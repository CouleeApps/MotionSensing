//
//  StringMath.h
//  MotionSensing
//
//  Created by Glenn Smith on 4/20/16.
//  Copyright © 2016 CouleeApps. All rights reserved.
//

#ifndef StringMath_hpp
#define StringMath_hpp

#import <string>
#import <sstream>
#import <glm/vec3.hpp>

namespace std {
	inline std::string to_string(const glm::vec3 &value) {
		std::stringstream ss;
		ss << value.x << "," << value.y << "," << value.z;
		return ss.str();
	}
}

#endif /* StringMath_hpp */
