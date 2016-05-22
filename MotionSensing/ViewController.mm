//
//  ViewController.m
//  MotionSensing
//
//  Created by Glenn Smith on 4/5/16.
//  Copyright © 2016 CouleeApps. All rights reserved.
//

#import "ViewController.h"
#import <sys/time.h>
#import "DataController.hpp"
#import "StringMath.hpp"

@interface ViewController () {
	CMMotionManager *manager;
	CLLocationManager *locationManager;
	NSFileHandle *handle;

	BOOL shouldCollect;
	NSThread *collectThread;

	DataController controller;
}

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *rowCountField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (nonatomic, strong) IBOutlet UITextView *text;
@property (nonatomic) IBOutlet UIProgressView *xAccel, *yAccel, *zAccel;
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
	manager = [CMMotionManager new];
	[manager startGyroUpdates];
	[manager startDeviceMotionUpdates];
	[manager startMagnetometerUpdates];
	[manager startAccelerometerUpdates];

	locationManager = [CLLocationManager new];
	[locationManager requestWhenInUseAuthorization];
	[locationManager setDistanceFilter:kCLDistanceFilterNone];
	[locationManager setDesiredAccuracy:kCLLocationAccuracyBest];

	if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
		//oh no
		NSLog(@"Can't get location");
	}

	[locationManager startUpdatingHeading];
	[locationManager startUpdatingLocation];
	[locationManager setDelegate:self];

	[super viewDidLoad];

	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCollection) userInfo:nil repeats:NO];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	CLLocation *currentLocation = [locations objectAtIndex:0];
	self.text.text = [NSString stringWithFormat:@"%f %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)checkCollection {
	BOOL shouldStart = (manager.isGyroAvailable && manager.isGyroActive &&
						manager.isDeviceMotionAvailable && manager.isDeviceMotionActive &&
						manager.isMagnetometerAvailable && manager.isMagnetometerActive &&
						manager.isAccelerometerAvailable && manager.isAccelerometerActive
						);

	self.text.text = [NSString stringWithFormat:@"%f %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude];

	self.startButton.enabled = shouldStart;
//	if (!shouldStart) {
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCollection) userInfo:nil repeats:NO];
//	}
}

- (void)collect {
	@autoreleasepool {
		int i = 0;
		NSString *filePath;
		do {
			filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
			filePath = [NSString stringWithFormat:@"%@/%@-%d.csv", filePath, self.nameField.text, i];
			i ++;
		} while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);

		NSLog(@"Make file: %@", filePath);

		timeval start;
		gettimeofday(&start, NULL);
		controller.setStartTime(start);
		controller.setWriteTypes(DataController::All);
		controller.startWritingToFile(std::string([filePath UTF8String]));
		controller.writeHeader();

		float count = self.rowCountField.text.floatValue;

		float correctDelta = 1000000.f / count;

		while (shouldCollect) {
			[self update];

			struct timeval current;
			gettimeofday(&current, NULL);

			struct timeval delta;
			timersub(&current, &start, &delta);

			usleep(correctDelta - delta.tv_usec - 2500);

			gettimeofday(&start, NULL);
		}
	}
}

- (void)update {
	struct timeval current;
	gettimeofday(&current, NULL);

	DataController::Data dataPoint;
	dataPoint.time = current;

	//Acceleration
	dataPoint.acceleration.raw = glm::vec3(manager.accelerometerData.acceleration.x, manager.accelerometerData.acceleration.y, manager.accelerometerData.acceleration.z);
	dataPoint.acceleration.gravity = glm::vec3(manager.deviceMotion.gravity.x, manager.deviceMotion.gravity.y, manager.deviceMotion.gravity.z);
	dataPoint.acceleration.user = glm::vec3(manager.deviceMotion.userAcceleration.x, manager.deviceMotion.userAcceleration.y, manager.deviceMotion.userAcceleration.z);

	//Motion
	dataPoint.motion.rotationRate = glm::vec3(manager.deviceMotion.rotationRate.x, manager.deviceMotion.rotationRate.y, manager.deviceMotion.rotationRate.z);
	dataPoint.motion.attitude = glm::vec3(manager.deviceMotion.attitude.pitch, manager.deviceMotion.attitude.yaw, manager.deviceMotion.attitude.roll);

	//Various other things
	dataPoint.heading = glm::vec3(locationManager.heading.x, locationManager.heading.y, locationManager.heading.z);
	dataPoint.magneticHeading = locationManager.heading.magneticHeading;
	dataPoint.trueHeading = locationManager.heading.trueHeading;
	dataPoint.location = glm::vec3(locationManager.location.coordinate.longitude, locationManager.location.coordinate.latitude, locationManager.location.altitude);
	dataPoint.magneticField = glm::vec3(manager.magnetometerData.magneticField.x, manager.magnetometerData.magneticField.y, manager.magnetometerData.magneticField.z);

	controller.addDataPoint(dataPoint);
	controller.write(dataPoint);

	[self.text performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"Collected %d rows / %d bytes", controller.getCollectionCount(), controller.getCollectionSize()] waitUntilDone:NO];

	[self performSelectorOnMainThread:@selector(updateLabels) withObject:nil waitUntilDone:NO];
}

- (void)updateLabels {
	glm::vec3 accel = controller.getLatestDataPoint().acceleration.raw;
	self.xAccel.progress = 0.5 + (accel.x / 2.0f);
	self.yAccel.progress = 0.5 + (accel.y / 2.0f);
	self.zAccel.progress = 0.5 + (accel.z / 2.0f);
}

- (IBAction)start:(id)sender {
	self.text.text = @"Collected 0 bytes";
	shouldCollect = YES;
	[NSThread detachNewThreadSelector:@selector(collect) toTarget:self withObject:nil];

	[self.nameField resignFirstResponder];
	[self.rowCountField resignFirstResponder];
}

- (IBAction)stop:(id)sender {
	shouldCollect = NO;
	[collectThread cancel];
	controller.stopWriting();
}
@end
