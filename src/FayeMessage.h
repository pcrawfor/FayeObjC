/* The MIT License
 
 Copyright (c) 2011 Paul Crawford
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE. */

//
//  FayeMessage.h
//  FayeObjC
//

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
  #import <Cocoa/Cocoa.h>
#else
  #import <UIKit/UIKit.h>
#endif
/*
 Represents the faye message structure
 */

@interface FayeMessage : NSObject {
  NSString *channel;
  NSString *clientId;
  NSNumber *successful;
  NSNumber *authSuccessful;
  NSString *version;
  NSString *minimumVersion;  
  NSArray *supportedConnectionTypes;
  NSDictionary *advice;
  NSString *error;
  NSString *subscription;
  NSDate *timestamp;
  NSDictionary *data;
  NSDictionary *ext;
  NSString *fayeId; // converted from "id" in bayeux protocol
}

@property (strong) NSString *channel;
@property (strong) NSString *clientId;
@property (strong) NSNumber *successful;
@property (strong) NSNumber *authSuccessful;
@property (strong) NSString *version;
@property (strong) NSString *minimumVersion;  
@property (strong) NSArray *supportedConnectionTypes;
@property (strong) NSDictionary *advice;
@property (strong) NSString *error;
@property (strong) NSString *subscription;
@property (strong) NSDate *timestamp;
@property (strong) NSDictionary *data;
@property (strong) NSDictionary *ext;
@property (strong) NSString *fayeId;

- (id) initWithDict:(NSDictionary *)dict;

@end