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
@synthesize statusLabel;

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
    [self.channelField setStringValue:self.serverURLString];
  }
  
  [self.messageField setTarget:self];
  [self.messageField setAction:@selector(sendMessage:)];
  self.statusLabel.stringValue = @"";  
}

#pragma mark -
#pragma mark FayeObjc delegate
- (void)fayeClientError:(NSError *)error {
  NSLog(@"Faye Client Error: %@", [error localizedDescription]);
}

- (void)messageReceived:(NSDictionary *)messageDict channel:(NSString *)channel {
  DLog(@"message recieved on channel: %@", channel);
  if([messageDict objectForKey:@"message"]) {    
    [self addLogMessage:[messageDict objectForKey:@"message"]];
  }
}

- (void)connectedToServer {
  [self addLogMessage:@"**** Connected to server ****"];
  self.connected = YES;
  [self.connectIndicator setImage:[NSImage imageNamed:@"green.png"]];
  [self.connectBtn setTitle:@"Disconnect"];
  [connectBtn setAction:@selector(disconnectFromServer:)];
  [self disableFields];
  NSLog(@"subscribe");
  [self.faye subscribeToChannel:self.serverChannelString];
  self.statusLabel.stringValue = [NSString stringWithFormat:@"Subscribed to channel: %@", self.channelField.stringValue];
}

- (void)disconnectedFromServer {
  if(self.connected)
    [self addLogMessage:@"**** Disconnected from server ****"];
  [self enableFields];
  self.connected = NO;
  [self.connectIndicator setImage:[NSImage imageNamed:@"red.png"]];
  [self.connectBtn setTitle:@"Connect"];
  [connectBtn setAction:@selector(connectToServer:)];
  self.statusLabel.stringValue = @"Disconnected";
}

- (void)subscriptionFailedWithError:(NSString *)error {
  [self addLogMessage:@"**** Subscription Failed ****"];
}

#pragma mark -

- (void) disableFields {
  [self.serverField setEnabled:NO];
  [self.channelField setEnabled:NO];
}

- (void) enableFields {
  [self.serverField setEnabled:YES];
  [self.channelField setEnabled:YES];
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
        
  if([self.serverChannelString length] == 0 || [self.serverURLString length] == 0) {    
    NSAlert *myAlert = [NSAlert alertWithMessageText:(@"Enter Server Info") defaultButton:(@"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:@"You must enter both a server URL and a Faye channel to subscribe to."];
    [myAlert beginSheetModalForWindow:[(fayeMacAppDelegate *)[[NSApplication sharedApplication] delegate] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];    
    return;
  }
  
  if([self.serverChannelString length] == 0 || [self.serverURLString length] == 0) {    
    NSAlert *myAlert = [NSAlert alertWithMessageText:(@"Only Web socket connections are supported") defaultButton:(@"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:@"You must enter both a server URL and a Faye channel to subscribe to."];
    [myAlert beginSheetModalForWindow:[(fayeMacAppDelegate *)[[NSApplication sharedApplication] delegate] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];    
    return;
  }
  
  self.faye = nil;
  self.faye = [[FayeClient alloc] initWithURLString:self.serverURLString channel:nil];
  self.faye.delegate = self;  
  [faye connectToServer];
}

- (IBAction) disconnectFromServer:(id)sender {
  DLog(@"Disconnected!");
  [self.faye disconnectFromServer];
}

- (IBAction) sendMessage:(id)sender {
  DLog(@"send message %@", [self.messageField stringValue]);
  NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[self.messageField stringValue], @"message", nil];
  [self.messageField setStringValue:@""];
  [self.faye sendMessage:messageDict onChannel:self.serverChannelString];
}

- (IBAction) clearLog:(id)sender {
  DLog(@"Clear Log");
  [self.messagesText setString:@""]; 
}

- (void) addLogMessage:(NSString *)message {
  [self.messagesText insertText:[NSString stringWithFormat:@"%@\n", message]];
}

- (void) dealloc
{
  faye.delegate = nil;
}


@end
