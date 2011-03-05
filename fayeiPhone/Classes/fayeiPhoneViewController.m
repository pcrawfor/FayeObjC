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
  self.connected = NO;
  self.faye = [[FayeClient alloc] initWithURLString:@"ws://localhost:8000/faye" channel:@"/chat"];
  self.faye.delegate = self;
  [faye connectToServer];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark FayeObjc delegate
- (void) messageReceived:(NSDictionary *)messageDict {
  DLog(@"message recieved %@", messageDict);
  if([messageDict objectForKey:@"message"]) {    
    //[self.messagesText insertText:[NSString stringWithFormat:@"%@\n", [messageDict objectForKey:@"message"]]];
  }
}

- (void)connectedToServer {
  DLog(@"Connected");
  self.connected = YES;
  //[self.connectIndicator setImage:[NSImage imageNamed:@"green.png"]];
  //[self.connectBtn setTitle:@"Disconnect"];
  //[connectBtn setAction:@selector(disconnectFromServer:)];
}

- (void)disconnectedFromServer {
  DLog(@"Disconnected");
  self.connected = NO;
  //[self.connectIndicator setImage:[NSImage imageNamed:@"red.png"]];
  //[self.connectBtn setTitle:@"Connect"];
  //[connectBtn setAction:@selector(connectToServer:)];
}

#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
  faye.delegate = nil;
  [faye release];
  [super dealloc];
}

@end
