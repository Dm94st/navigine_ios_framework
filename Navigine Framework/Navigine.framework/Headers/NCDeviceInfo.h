//
//  NCDeviceInfo.h
//  NavigineSDK
//
//  Created by Pavel Tychinin on 29/03/2017.
//  Copyright © 2017 Navigine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCLocationPoint.h"
#import "NCGlobalPoint.h"


@interface NCDeviceInfo : NSObject <NSCoding>
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSDate *time;
@property (nonatomic, assign) NSInteger location;
@property (nonatomic, assign) NSInteger sublocation;
@property (nonatomic, assign) float x;
@property (nonatomic, assign) float kx;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float ky;
@property (nonatomic, assign) float r;
@property (nonatomic, assign) float azimuth;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, strong) NSArray *paths;
@property (nonatomic, strong) NSArray *zones;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong, readonly) NCLocationPoint *locationPoint;
@property (nonatomic, strong, readonly) NCGlobalPoint   *globalPoint;

- (BOOL) isValid;

@end
