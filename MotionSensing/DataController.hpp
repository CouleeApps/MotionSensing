//
//  DataController.hpp
//  MotionSensing
//
//  Created by Glenn Smith on 4/20/16.
//  Copyright © 2016 CouleeApps. All rights reserved.
//

#ifndef DataController_hpp
#define DataController_hpp

#include <stdio.h>
#include <sys/time.h>
#include <vector>
#include <fstream>
#include <glm/vec3.hpp>

class DataController {
public:
	enum WriteTypes {
		AccelerationRaw     = 1 << 0,
		AccelerationGravity = 1 << 1,
		AccelerationUser    = 1 << 2,
		RotationRate        = 1 << 3,
		Attitude            = 1 << 4,
		Heading             = 1 << 5,
		MagneticHeading     = 1 << 6,
		TrueHeading         = 1 << 7,
		Location            = 1 << 8,
		MagneticField       = 1 << 9,

		All                 = 0xFFFF
	};

	struct Data {
		timeval time;
		struct {
			glm::vec3 raw;
			glm::vec3 gravity;
			glm::vec3 user;
		} acceleration;

		struct {
			glm::vec3 rotationRate;
			glm::vec3 attitude;
		} motion;

		glm::vec3 heading;
		float magneticHeading;
		float trueHeading;
		glm::vec3 location;
		glm::vec3 magneticField;
	};

protected:
	std::vector<Data> mData;
	timeval mStart;
	WriteTypes mWriteTypes;
	FILE *mWriteStream;

public:
	void writeHeader();
	void write(const Data &data);

	void startWritingToFile(const std::string &file) {
		mWriteStream = fopen(file.c_str(), "w");
	}
	void stopWriting() {
		fclose(mWriteStream);
	}
	const Data &getLatestDataPoint() const {
		return mData[mData.size() - 1];
	}
	void clearDataPoints() {
		mData.clear();
	}
	void addDataPoint(const Data &data) {
		mData.push_back(data);
	}
	void setStartTime(const timeval &start) {
		mStart = start;
	}
	void setWriteTypes(const WriteTypes &types) {
		mWriteTypes = types;
	}
	int getCollectionCount() {
		return mData.size();
	}
	int getCollectionSize() {
		return ftell(mWriteStream);
	}
};

#endif /* DataController_hpp */
