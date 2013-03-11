//
//  fayeiPhoneViewController.m
//  fayeiPhone
//
//  Created by Paul Crawford on 11-03-04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "fayeiPhoneViewController.h"

@implementation fayeiPhoneViewController

@synthesize faye;
@synthesize connected;
@synthesize messageTextField;
@synthesize editToolbar;
@synthesize messageView;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];  
  [nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];    
  
  self.connected = NO;
  self.faye = [[FayeClient alloc] initWithURLString:@"ws://YOUR_SERVER_HERE:PORT/faye" channel:@"/YOUR_CHANNEL"];
  self.faye.delegate = self;
  [faye connectToServer];
}

- (void) keyboardWillShow:(NSNotification *)notification {  
  CGRect rect = editToolbar.frame, keyboardFrame;
  [[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];  
  rect.origin.y -= keyboardFrame.size.height;      
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.3];
  editToolbar.frame = rect;  
  messageView.frame = CGRectMake(0, 0, 320, messageView.frame.size.height-keyboardFrame.size.height);  
  [UIView commitAnimations];
}

- (void) keyboardWillHide:(NSNotification *)notification {
  CGRect rect = editToolbar.frame, keyboardFrame;
  [[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];  
  rect.origin.y += keyboardFrame.size.height;      
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.3];
  editToolbar.frame = rect;  
  messageView.frame = CGRectMake(0, 0, 320, messageView.frame.size.height+keyboardFrame.size.height);  
  [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  DLog(@"text field should return");
  [self sendMessage];
  return YES;
}

- (IBAction) sendMessage {
  DLog(@"send message %@", messageTextField.text);    
  NSString *message = [NSString stringWithString:messageTextField.text];
  NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil];  
  [self.faye sendMessage:messageDict onChannel:@"/test"];
  self.messageTextField.text = @"";
}

- (IBAction) hideKeyboard {
  self.messageTextField.text = @"";
  [self.messageTextField resignFirstResponder];
}

#pragma mark -
#pragma mark FayeObjc delegate
- (void)fayeClientError:(NSError *)error {
  NSLog(@"Faye Client Error: %@", [error localizedDescription]);
}

- (void)messageReceived:(NSDictionary *)messageDict channel:(NSString *)channel {
  DLog(@"message recieved %@", messageDict);
  if([messageDict objectForKey:@"message"]) {
    self.messageView.text = [self.messageView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n", [messageDict objectForKey:@"message"]]]; 
  }
}

- (void)connectedToServer {
  DLog(@"Connected");
  self.connected = YES;
}

- (void)disconnectedFromServer {
  DLog(@"Disconnected");
  self.connected = NO;
}

#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {	
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
  faye.delegate = nil;
}

@end
