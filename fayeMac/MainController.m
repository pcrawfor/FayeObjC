//
//  MainController.m
//  fayeMac
//
//  Created by Paul Crawford on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "fayeMacAppDelegate.h"

#define SERVER_URL_STRING @"ServerURLString"
#define SERVER_CHANNEL_STRING @"ServerChannelString"

@implementation MainController

@synthesize messagesText;
@synthesize sendBtn;
@synthesize messageField;
@synthesize serverField;
@synthesize channelField;
@synthesize faye;
@synthesize connectBtn;
@synthesize serverURLString;
@synthesize serverChannelString;
@synthesize connected;
@synthesize connectIndicator;

- (void) awakeFromNib {
  DLog(@"MainController firing up");  
  [self disconnectedFromServer];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if([defaults objectForKey:SERVER_URL_STRING]) {
    self.serverURLString = [defaults objectForKey:SERVER_URL_STRING];
    [self.serverField setStringValue:self.serverURLString];
  }
  if([defaults objectForKey:SERVER_CHANNEL_STRING]) {
    self.serverURLString = [defaults objectForKey:SERVER_CHANNEL_STRING];
    [self.serverField setStringValue:self.serverURLString];
  }
}

#pragma mark -
#pragma mark FayeObjc delegate
- (void) messageReceived:(NSDictionary *)messageDict {
  DLog(@"message recieved");
  if([messageDict objectForKey:@"message"]) {    
    [self.messagesText insertText:[NSString stringWithFormat:@"%@\n", [messageDict objectForKey:@"message"]]];
  }
}

- (void)connectedToServer {
  self.connected = YES;
  [self.connectIndicator setImage:[NSImage imageNamed:@"green.png"]];
  [self.connectBtn setTitle:@"Disconnect"];
  [connectBtn setAction:@selector(disconnectFromServer:)];
}

- (void)disconnectedFromServer {
  self.connected = NO;
  [self.connectIndicator setImage:[NSImage imageNamed:@"red.png"]];
  [self.connectBtn setTitle:@"Connect"];
  [connectBtn setAction:@selector(connectToServer:)];
}

#pragma mark -
- (IBAction) connectToServer:(id)sender {  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  
  self.serverURLString = [self.serverField stringValue];  
  self.serverChannelString = [self.channelField stringValue];
  
  DLog(@"set server string %@", [self.serverField stringValue]);    
  DLog(@"set channel string %@", [self.channelField stringValue]);    
  
  if([self.serverURLString length] > 0) {    
    [defaults setObject:self.serverURLString forKey:SERVER_URL_STRING];
    [defaults synchronize];
  } else {
    if([defaults objectForKey:SERVER_CHANNEL_STRING]) {
      self.serverURLString = [defaults objectForKey:SERVER_URL_STRING];
      [self.serverField setStringValue:self.serverURLString];
    }
  }
  
  if([self.serverChannelString length] > 0) {        
    [defaults setObject:self.serverChannelString forKey:SERVER_CHANNEL_STRING];
    [defaults synchronize];
  } else {
    if([defaults objectForKey:SERVER_CHANNEL_STRING]) {
      self.serverChannelString = [defaults objectForKey:SERVER_CHANNEL_STRING];
      [self.channelField setStringValue:self.serverChannelString];
    }
  }  
  
  
  
  DLog(@"check");
  if([self.serverChannelString length] == 0 || [self.serverURLString length] == 0) {    
    NSAlert *myAlert = [NSAlert alertWithMessageText:(@"Enter Server Info") defaultButton:(@"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:@"You must enter both a server URL and a Faye channel to subscribe to."];
    [myAlert beginSheetModalForWindow:[(fayeMacAppDelegate *)[[NSApplication sharedApplication] delegate] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];    
    return;
  }
  
  self.faye = nil;
  self.faye = [[FayeClient alloc] initWithURLString:self.serverURLString channel:self.serverChannelString];
  self.faye.delegate = self;
  [faye connectToServer];    
}

- (IBAction) disconnectFromServer:(id)sender {
  [self.faye disconnectFromServer];
}

- (IBAction) sendMessage:(id)sender {
  DLog(@"message %@", [self.messageField stringValue]);
  NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[self.messageField stringValue], @"message", nil];
  [self.messageField setStringValue:@""];
  [self.faye publishDict:messageDict];
}

- (void) dealloc
{
  self.messagesText = nil;
  self.sendBtn = nil;
  self.messageField = nil;
  self.serverField = nil;
  self.channelField = nil;
  self.connectBtn = nil;
  [faye release];
  [serverURLString release];
  [serverChannelString release];
  self.connectIndicator = nil;
  [super dealloc];
}


@end
