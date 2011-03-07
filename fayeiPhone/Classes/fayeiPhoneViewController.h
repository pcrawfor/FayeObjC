//
//  fayeiPhoneViewController.h
//  fayeiPhone
//
//  Created by Paul Crawford on 11-03-04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FayeClient.h"

@interface fayeiPhoneViewController : UIViewController <FayeClientDelegate, UITextFieldDelegate> {
  FayeClient *faye;
  BOOL connected;
  UITextField *messageTextField;
  UIToolbar *editToolbar;
  UITextView *messageView;
}

@property (retain) FayeClient *faye;
@property (assign) BOOL connected;
@property (nonatomic, retain) IBOutlet UITextField *messageTextField;
@property (nonatomic, retain) IBOutlet UIToolbar *editToolbar;
@property (nonatomic, retain) IBOutlet UITextView *messageView;

- (IBAction) sendMessage;
- (IBAction) hideKeyboard;

@end

