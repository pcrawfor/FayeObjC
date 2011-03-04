//
//  NSData+Serialize.m
//  DailyBurn
//
//  Created by Paul Crawford on 10-06-24.
//  Copyright 2010 Daily Burn, Inc.. All rights reserved.
//

#import "NSData+Serialize.h"


@implementation NSData(Serialize)

+ (NSString *) deserialize:(id)value {
	// For now the only NSData type we are parsing is strings which are too large to package as strings
  
  NSString *string = [[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding] autorelease];
  
  return string;
}

- (NSString *) serialize {
	[NSException raise:@"DBNotImplemented" format:@"NSData serialize function not implemented"];
  return @"";
}

@end