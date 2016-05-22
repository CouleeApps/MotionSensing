//
//  DataController.cpp
//  MotionSensing
//
//  Created by Glenn Smith on 4/20/16.
//  Copyright © 2016 CouleeApps. All rights reserved.
//

#include "DataController.hpp"
#include "StringMath.hpp"

static const char *headers[] = {
	"Raw Acceleration X,Raw Acceleration Y,Raw Acceleration Z",
	"Gravity Acceleration X,Gravity Acceleration Y,Gravity Acceleration Z",
	"User Acceleration X,User Acceleration Y,User Acceleration Z",
	"Rotation Rate X,Rotation Rate Y,Rotation Rate Z",
	"Attitude X,Attitude Y,Attitude Z",
	"Heading X,Heading Y,Heading Z",
	"Magnetic Heading",
	"True Heading",
	"Location X,Location Y,Location Z",
	"Magnetic Field X,Magnetic Field Y,Magnetic Field Z"
};

void DataController::writeHeader() {
	//Write headers
	fprintf(mWriteStream, "Time");

	for (int i = 0; i < 10; i ++) {
		if (mWriteTypes & (1 << i)) {
			fprintf(mWriteStream, ",%s", headers[i]);
		}
	}

	fprintf(mWriteStream, "\n");
}

void DataController::write(const Data &data) {
	timeval delta;
	timersub(&data.time, &mStart, &delta);

	fprintf(mWriteStream, "%ld.%06d", delta.tv_sec, delta.tv_usec);

	if ((mWriteTypes & AccelerationRaw) == AccelerationRaw) {
		fprintf(mWriteStream, ",%s", std::to_string(data.acceleration.raw).c_str());
	}
	if ((mWriteTypes & AccelerationGravity) == AccelerationGravity) {
		fprintf(mWriteStream, ",%s", std::to_string(data.acceleration.gravity).c_str());
	}
	if ((mWriteTypes & AccelerationUser) == AccelerationUser) {
		fprintf(mWriteStream, ",%s", std::to_string(data.acceleration.user).c_str());
	}
	if ((mWriteTypes & RotationRate) == RotationRate) {
		fprintf(mWriteStream, ",%s", std::to_string(data.motion.rotationRate).c_str());
	}
	if ((mWriteTypes & Attitude) == Attitude) {
		fprintf(mWriteStream, ",%s", std::to_string(data.motion.attitude).c_str());
	}
	if ((mWriteTypes & Heading) == Heading) {
		fprintf(mWriteStream, ",%s", std::to_string(data.heading).c_str());
	}
	if ((mWriteTypes & MagneticHeading) == MagneticHeading) {
		fprintf(mWriteStream, ",%s", std::to_string(data.magneticHeading).c_str());
	}
	if ((mWriteTypes & TrueHeading) == TrueHeading) {
		fprintf(mWriteStream, ",%s", std::to_string(data.trueHeading).c_str());
	}
	if ((mWriteTypes & Location) == Location) {
		fprintf(mWriteStream, ",%s", std::to_string(data.location).c_str());
	}
	if ((mWriteTypes & MagneticField) == MagneticField) {
		fprintf(mWriteStream, ",%s", std::to_string(data.magneticField).c_str());
	}
	fprintf(mWriteStream, "\n");
}
