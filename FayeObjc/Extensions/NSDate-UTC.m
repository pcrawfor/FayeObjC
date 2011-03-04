//
//  NSDate-UTC.m
//  Gyminee-iPhone
//
//  Created by Paul Crawford on 03/08/09.
//  Copyright 2009 Daily Burn, Inc.. All rights reserved.
//

#import "NSDate-UTC.h"


@implementation NSDate(UTC)

- (NSDate *) convertToUTC
{
  // Convert current local time to UTC  
  NSInteger sourceSeconds = [[NSTimeZone localTimeZone] secondsFromGMTForDate:self];
  NSInteger destinationSeconds = [[NSTimeZone timeZoneWithName:@"UTC"] secondsFromGMTForDate:self];
  NSTimeInterval interval = destinationSeconds - sourceSeconds;
  return [[[NSDate alloc] initWithTimeInterval:interval sinceDate:self] autorelease];
}

@end
