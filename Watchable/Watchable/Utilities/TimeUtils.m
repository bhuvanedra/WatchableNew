//
//  TimeUtils.m
//  Watchable
//
//  Created by valtech on 26/04/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "TimeUtils.h"

@implementation TimeUtils

+ (void)timeUntilDate:(NSDate *)date
              daysOut:(int *)daysOut
             hoursOut:(int *)hoursOut
           minutesOut:(int *)minutesOut
           secondsOut:(int *)secondsOut
{
    NSTimeInterval totalSecs = [date timeIntervalSinceDate:[NSDate date]];
    [self convertFromSeconds:totalSecs daysOut:daysOut hoursOut:hoursOut minutesOut:minutesOut secondsOut:secondsOut];
}

+ (void)convertFromSeconds:(NSTimeInterval)totalSecs
                   daysOut:(int *)daysOut
                  hoursOut:(int *)hoursOut
                minutesOut:(int *)minutesOut
                secondsOut:(int *)secondsOut
{
    int days = (int)totalSecs / (60 * 60 * 24);
    int hours = ((int)totalSecs - days * 60 * 60 * 24) / (60 * 60);
    int minutes = ((int)totalSecs - days * 60 * 60 * 24 - hours * 60 * 60) / 60;
    int seconds = (int)totalSecs - days * 60 * 60 * 24 - hours * 60 * 60 - minutes * 60;

    *daysOut = days;
    *hoursOut = hours;
    *minutesOut = minutes;
    *secondsOut = seconds;
}

+ (NSString *)durationStringForDuration:(NSTimeInterval)duration
{
    int days;
    int hours;
    int minutes;
    int seconds;

    [TimeUtils convertFromSeconds:duration
                          daysOut:&days
                         hoursOut:&hours
                       minutesOut:&minutes
                       secondsOut:&seconds];

    NSString *durationString = nil;
    if (days > 0)
    {
        durationString = [NSString stringWithFormat:@"%d:%02d:%02d:%02d", days, hours, minutes, seconds];
    }
    else if (hours > 0)
    {
        durationString = [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
    }
    else
    {
        durationString = [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
    }

    return durationString;
}

@end
