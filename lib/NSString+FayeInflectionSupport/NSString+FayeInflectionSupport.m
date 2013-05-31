//
//  NSString+InflectionSupport.m
//  
//
//  Created by Ryan Daigle on 7/31/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

#import "NSString+FayeInflectionSupport.h"

@implementation NSString (FayeInflectionSupport)

- (NSCharacterSet *)camelcaseDelimiters {
	return [NSCharacterSet characterSetWithCharactersInString:@"-_"];
}

- (NSString *)faye_camelize {
	
	unichar *buffer = calloc([self length], sizeof(unichar));
	[self getCharacters:buffer ];
	NSMutableString *underscored = [NSMutableString string];
	
	BOOL capitalizeNext = NO;
	NSCharacterSet *delimiters = [self camelcaseDelimiters];
	for (int i = 0; i < [self length]; i++) {
		NSString *currChar = [NSString stringWithCharacters:buffer+i length:1];
		if([delimiters characterIsMember:buffer[i]]) {
			capitalizeNext = YES;
		} else {
			if(capitalizeNext) {
				[underscored appendString:[currChar uppercaseString]];
				capitalizeNext = NO;
			} else {
				[underscored appendString:currChar];
			}
		}
	}
	
	free(buffer);
	return underscored;
}

- (NSString *)faye_toClassName {
	NSString *result = [self faye_camelize];
	return [result stringByReplacingCharactersInRange:NSMakeRange(0,1) 
										 withString:[[result substringWithRange:NSMakeRange(0,1)] uppercaseString]];
}

@end
