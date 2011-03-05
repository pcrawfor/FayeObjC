/* The MIT License
 
 Copyright (c) 2010 Paul Crawford
 
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
//  FayeClient.m
//  FayeObjC
//

#import "FayeClient.h"
#import "FayeMessage.h"

@interface FayeClient (Private)

- (void) openWebSocketConnection;
- (void) closeWebSocketConnection;
- (void) connect;
- (void) disconnect;
- (void) handshake;
- (void) subscribe;
- (void) publish:(NSDictionary *)messageDict;
- (void) parseFayeMessage:(NSString *)message;

@end


@implementation FayeClient

@synthesize fayeURLString;
@synthesize webSocket;
@synthesize fayeClientId;
@synthesize webSocketConnected;
@synthesize fayeConnected;
@synthesize activeSubChannel;
@synthesize delegate;

/*
 Example websocket url string
 // ws://localhost:8000/faye
 */
- (id) initWithURLString:(NSString *)aFayeURLString channel:(NSString *)channel
{
  self = [super init];
  if (self != nil) {
    self.fayeURLString = aFayeURLString;
    self.webSocketConnected = NO;
    self.fayeConnected = NO;
    self.activeSubChannel = channel;  
  }
  return self;
}

#pragma mark -
#pragma mark Faye

// fire up a connection to the websocket
// handshake with the server
// establish a faye connection
- (void) connectToServer {
  [self openWebSocketConnection];
}

- (void) disconnectFromServer {  
  [self disconnect];  
}
   
- (void) publishDict:(NSDictionary *)messageDict {
  [self publish:messageDict];
}

#pragma mark -
#pragma mark WebSocket Delegate

#pragma mark -
#pragma mark webSocket
-(void)webSocketDidClose:(ZTWebSocket *)webSocket {
  NSLog(@"WEBSOCKET DID CLOSE");
  self.webSocketConnected = NO;  
}

-(void)webSocket:(ZTWebSocket *)webSocket didFailWithError:(NSError *)error {
  NSLog(@"WEBSOCKET DID FAIL");
  if (error.code == ZTWebSocketErrorConnectionFailed) {
    NSLog(@"Connection failed %@", [error localizedDescription]);
  } else if (error.code == ZTWebSocketErrorHandshakeFailed) {
    NSLog(@"Handshake failed %@", [error localizedDescription]);
  } else {
    NSLog(@"Error %@", [error localizedDescription]);
  }
}

-(void)webSocket:(ZTWebSocket *)webSocket didReceiveMessage:(NSString*)message {
  NSLog(@"WEBSOCKET DID RECEIVE MESSAGE");  
  [self parseFayeMessage:message];
}

-(void)webSocketDidOpen:(ZTWebSocket *)aWebSocket {
  NSLog(@"WEBSOCKET Connected");  
  self.webSocketConnected = YES;  
  [self handshake];    
}

-(void)webSocketDidSendMessage:(ZTWebSocket *)webSocket {
  NSLog(@"WEBSOCKET DID SEND MESSAGE");
}

#pragma mark -
#pragma mark Deallocation
- (void) dealloc
{
  self.delegate = nil;
  [webSocket release];
  [fayeURLString release];
  [fayeClientId release];
  [activeSubChannel release];  
  [super dealloc];
}

@end

#pragma mark -
#pragma mark Private
@implementation FayeClient (Private)

#pragma mark -
#pragma mark WebSocket connection
- (void) openWebSocketConnection {
  self.webSocket = [[ZTWebSocket alloc] initWithURLString:self.fayeURLString delegate:self];
  [webSocket open];	    
}

- (void) closeWebSocketConnection { 
  [webSocket close];	    
}

#pragma mark -
#pragma mark Private Bayeux procotol functions

/* 
 Bayeux Handshake
 "channel": "/meta/handshake",
 "version": "1.0",
 "minimumVersion": "1.0beta",
 "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe", "websocket]
 */
- (void) handshake {
  NSArray *connTypes = [NSArray arrayWithObjects:@"long-polling", @"callback-polling", @"iframe", @"websocket", nil];   
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:HANDSHAKE_CHANNEL, @"channel", @"1.0", @"version", @"1.0beta", @"minimumVersion", connTypes, @"supportedConnectionTypes", nil];
  NSString *json = [dict yajl_JSONString];
  [webSocket send:json];  
}

/*
 Bayeux Connect
 "channel": "/meta/connect",
 "clientId": "Un1q31d3nt1f13r",
 "connectionType": "long-polling"
 */
- (void) connect {
  NSLog(@"Connect");
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:CONNECT_CHANNEL, @"channel", self.fayeClientId, @"clientId", @"websocket", @"connectionType", nil];
  NSString *json = [dict yajl_JSONString];  
  [webSocket send:json];
}

/*
 {
 "channel": "/meta/disconnect",
 "clientId": "Un1q31d3nt1f13r"
 }
 */
- (void) disconnect {
  NSLog(@"Disconnect");
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:DISCONNECT_CHANNEL, @"channel", self.fayeClientId, @"clientId", nil];
  NSString *json = [dict yajl_JSONString];  
  [webSocket send:json];
}

/*
 {
 "channel": "/meta/subscribe",
 "clientId": "Un1q31d3nt1f13r",
 "subscription": "/foo/**"
 }
 */
- (void) subscribe {
  NSLog(@"Subscribe");
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:SUBSCRIBE_CHANNEL, @"channel", self.fayeClientId, @"clientId", self.activeSubChannel, @"subscription", nil];
  NSString *json = [dict yajl_JSONString];    
  [webSocket send:json];
}

/*
 {
 "channel": "/meta/unsubscribe",
 "clientId": "Un1q31d3nt1f13r",
 "subscription": "/foo/**"
 }
 */
- (void) unsubscribe {
  NSLog(@"Unsubscribe");
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:UNSUBSCRIBE_CHANNEL, @"channel", self.fayeClientId, @"clientId", self.activeSubChannel, @"subscription", nil];
  NSString *json = [dict yajl_JSONString];  
  [webSocket send:json];
}

/*
 {
 "channel": "/some/channel",
 "clientId": "Un1q31d3nt1f13r",
 "data": "some application string or JSON encoded object",
 "id": "some unique message id"
 }
 */
- (void) publish:(NSDictionary *)messageDict {
  NSLog(@"Publish");
  NSString *channel = self.activeSubChannel;
  NSString *messageId = [NSString stringWithFormat:@"msg_%d_%d", [[NSDate date] timeIntervalSince1970], 1];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", self.fayeClientId, @"clientId", messageDict, @"data", messageId, @"id", nil];
  NSString *json = [dict yajl_JSONString];  
  [webSocket send:json];
}

#pragma mark -
#pragma mark Faye message handling
- (void) parseFayeMessage:(NSString *)message {
  // interpret the message(s) 
  NSArray *messageArray = [message yajl_JSON];    
  for(NSDictionary *messageDict in messageArray) {
    FayeMessage *fm = [[FayeMessage alloc] initWithDict:messageDict];
    NSLog(@"faye message %@", fm);
    
    if ([fm.channel isEqualToString:HANDSHAKE_CHANNEL]) {    
      if ([fm.successful boolValue]) {
        self.fayeClientId = fm.clientId;
        NSLog(@"HANDSHAKE SUCCESSFUL"); // TODO: check that websocket is in allowed connection types
        if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(connectedToServer)]) {
          [self.delegate connectedToServer];
        }
        [self connect];  
        // try to sub right after conn      
        [self subscribe];
      } else {
        NSLog(@"ERROR WITH HANDSHAKE");
      }    
    } else if ([fm.channel isEqualToString:CONNECT_CHANNEL]) {
      NSLog(@"CONNECT RESPONSE");
      if ([fm.successful boolValue]) {
        NSLog(@"CONNECTED TO FAYE!");
        self.fayeConnected = YES;
        [self connect];
      } else {
        NSLog(@"ERROR CONNECTING TO FAYE");
      }
    } else if ([fm.channel isEqualToString:DISCONNECT_CHANNEL]) {
      if ([fm.successful boolValue]) {
        NSLog(@"DISCONNECTED FROM FAYE!");
        self.fayeConnected = NO;  
        [self closeWebSocketConnection];
        if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(disconnectedFromServer)]) {
          [self.delegate disconnectedFromServer];
        }
      } else {
        NSLog(@"ERROR DISCONNECTING TO FAYE");
      }
    } else if ([fm.channel isEqualToString:SUBSCRIBE_CHANNEL]) {
      if ([fm.successful boolValue]) {
        NSLog(@"SUBSCRIBED TO CHANNEL %@ ON FAYE", fm.subscription);
        NSLog(@"SUBSCRIPTION CLASS %@", [fm.subscription className]);                
      } else {
        NSLog(@"ERROR SUBSCRIBING TO %@ WITH ERROR %@", fm.subscription, fm.error);
      }
    } else if ([fm.channel isEqualToString:UNSUBSCRIBE_CHANNEL]) {
      NSLog(@"UNSUBSCRIBED FROM CHANNEL %@ ON FAYE", fm.subscription);
    } else if ([fm.channel isEqualToString:self.activeSubChannel]) {
      NSLog(@"MESSAGE FROM CHANNEL! %@", self.activeSubChannel);
      if (fm.successful) {
        NSLog(@"MESSAGE EVENT SUCCESSFUL");
      }
      
      if(fm.data) {        
        if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(messageReceived:)]) {
          [self.delegate messageReceived:fm.data];
        }
      } else {
        NSLog(@"NO DATA");
      }
      
    } else {
      NSLog(@"NO MATCH FOR CHANNEL %@", fm.channel);      
    }
  }    
}

@end
