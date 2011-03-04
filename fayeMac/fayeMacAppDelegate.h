//
//  fayeMacAppDelegate.h
//  fayeMac
//
//  Created by Paul Crawford on 3/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface fayeMacAppDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;  
}

@property (assign) IBOutlet NSWindow *window;

@end
