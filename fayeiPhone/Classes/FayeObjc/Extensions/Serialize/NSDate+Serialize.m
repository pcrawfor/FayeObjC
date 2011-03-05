//
//  NSDate+Deserialize.m
//  active_resource
//
//  Created by James Burka on 1/19/09.
//  Copyright 2009 Burkaprojects. All rights reserved.
//

#import "NSDate+Serialize.h"
#import "ObjectiveResourceDateFormatter.h"
#import "NSDate-UTC.h"

@implementation NSDate(Serialize)

+ (NSDate *) deserialize:(id)value {
	NSDate *returnDate;
    
  if([value isKindOfClass:[NSDate class]]) {    
    return [value convertToUTC];
  } else {
    NSLog(@"didn't match %@",[NSDate class]); 
  }
  
  if([NSNull null] == value)
    return nil;
    
  returnDate = [ObjectiveResourceDateFormatter parseDateTime:value];
    
  if(nil == returnDate)
    returnDate = [ObjectiveResourceDateFormatter parseDate:value];
      
  return returnDate;
}

- (NSString *) serialize {
	return [ObjectiveResourceDateFormatter formatDate:self];
}

@end
