//
//  NSData+Serialize.h
//  DailyBurn
//
//  Created by Paul Crawford on 10-06-24.
//  Copyright 2010 Daily Burn, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData(Serialize)

+ (NSString *) deserialize:(id)value;
- (NSString *) serialize; 

@end
