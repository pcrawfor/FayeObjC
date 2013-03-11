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

#import <Cocoa/Cocoa.h>
#import <FayeObjC/FayeClient.h>

@interface MainController : NSObject <FayeClientDelegate> {
  NSTextView *messagesText;
  NSButton *sendBtn;
  NSTextField *messageField;
  NSTextField *serverField;
  NSTextField *channelField;  
  FayeClient *faye;
  NSButton *connectBtn;
  NSString *serverURLString;
  NSString *serverChannelString;
  BOOL connected;
  NSImageView *connectIndicator;
  NSTextField *statusLabel;
}

@property (strong) IBOutlet NSTextView *messagesText;
@property (strong) IBOutlet NSButton *sendBtn;
@property (strong) IBOutlet NSTextField *messageField;
@property (strong) IBOutlet NSTextField *serverField;
@property (strong) IBOutlet NSTextField *channelField;  
@property (strong) FayeClient *faye;
@property (strong) IBOutlet NSButton *connectBtn;
@property (strong) NSString *serverURLString;
@property (strong) NSString *serverChannelString;
@property (assign) BOOL connected;
@property (strong) IBOutlet NSImageView *connectIndicator;
@property (strong) IBOutlet NSTextField *statusLabel;

- (IBAction) connectToServer:(id)sender;
- (IBAction) sendMessage:(id)sender;
- (IBAction) clearLog:(id)sender;
- (void) disableFields;
- (void) enableFields;
- (void) addLogMessage:(NSString *)message;

@end
