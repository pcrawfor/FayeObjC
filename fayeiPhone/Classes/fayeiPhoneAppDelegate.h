//
//  fayeiPhoneAppDelegate.h
//  fayeiPhone
//
//  Created by Paul Crawford on 11-03-04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class fayeiPhoneViewController;

@interface fayeiPhoneAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    fayeiPhoneViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet fayeiPhoneViewController *viewController;

@end

