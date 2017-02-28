//
//  TimeUtils.h
//  Watchable
//
//  Created by valtech on 26/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeUtils : NSObject

+ (void)timeUntilDate:(NSDate *)date
              daysOut:(int *)daysOut
             hoursOut:(int *)hoursOut
           minutesOut:(int *)minutesOut
           secondsOut:(int *)secondsOut;

+ (void)convertFromSeconds:(NSTimeInterval)totalSecs
                   daysOut:(int *)daysOut
                  hoursOut:(int *)hoursOut
                minutesOut:(int *)minutesOut
                secondsOut:(int *)secondsOut;

+ (NSString *)durationStringForDuration:(NSTimeInterval)duration;

@end
