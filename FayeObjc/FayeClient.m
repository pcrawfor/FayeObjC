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
//  FayeClient.m
//  FayeObjC
//

#import "FayeClient.h"
#import "FayeMessage.h"

// allows definition of private property
@interface FayeClient ()

@property (strong) NSDictionary *connectionExtension;

@end

@interface FayeClient (Private)

- (void) passFayeClientError:(NSError *)error;
- (void) openWebSocketConnection;
- (void) closeWebSocketConnection;
- (void) connect;
- (void) disconnect;
- (void) handshake;
- (void) subscribe:(NSString *)channel;
- (void) unsubscribe:(NSString *)channel;
- (void) publish:(NSDictionary *)messageDict channel:(NSString *)channel withExt:(NSDictionary *)extension;
- (void) parseFayeMessages:(NSArray *)messages;

- (void) send:(id)object;
- (void) receive:(id)data;

@end


@implementation FayeClient {
  NSMutableArray *openSubscriptions;
}

@synthesize fayeURLString;
@synthesize webSocket;
@synthesize fayeClientId;
@synthesize webSocketConnected;
@synthesize connectionInitiated;
@synthesize delegate;
@synthesize connectionExtension;

// Example websocket url string
// ws://localhost:8000/faye
- (id) initWithURLString:(NSString *)aFayeURLString channel:(NSString *)channel
{
  self = [super init];
  if (self != nil) {
    self.fayeURLString = aFayeURLString;
    self.webSocketConnected = NO;
    fayeConnected = NO;
    openSubscriptions = [[NSMutableArray alloc] init];
    if(nil != channel) {
      if(![openSubscriptions containsObject:channel]) {
        [openSubscriptions addObject:channel];
      }
    }
    self.connectionInitiated = NO;    
  }
  return self;
}

#pragma mark -
#pragma mark Faye

// fire up a connection to the websocket
// handshake with the server
// establish a faye connection
- (void) connectToServer {
  if(!connectionInitiated) {
    [self openWebSocketConnection];
  }
}

- (void) connectToServerWithExt:(NSDictionary *)extension {
  self.connectionExtension = extension;  
  [self connectToServer];
}

- (void) disconnectFromServer {  
  [self disconnect];  
}

- (void) sendMessage:(NSDictionary *)messageDict onChannel:(NSString *)channel {
  [self publish:messageDict channel:channel withExt:nil];
}

- (void) sendMessage:(NSDictionary *)messageDict onChannel:(NSString *)channel withExt:(NSDictionary *)extension {
  [self publish:messageDict channel:channel withExt:extension];
}

- (void) subscribeToChannel:(NSString *)channel {
  if(![openSubscriptions containsObject:channel]) {
    [openSubscriptions addObject:channel];
  }
  [self subscribe:channel];
}

- (void) unsubscribeFromChannel:(NSString *)channel {
  [openSubscriptions removeObject:channel];
  [self unsubscribe:channel];
}

- (BOOL) isSubscribedToChannel:(NSString *)channel {
  return [openSubscriptions containsObject:channel];
}

- (void) resubscribeOpenSubs {
  
  // if there are any outstanding open subscriptions resubscribe
  if ([openSubscriptions count] > 0) {    
    NSArray *subs = [NSArray arrayWithArray:openSubscriptions];
    for(NSString *channel in subs) {
      [self subscribeToChannel:channel];
    }
  }
}

#pragma -
#pragma mark SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{  
  self.webSocketConnected = YES;
  self.connectionInitiated = NO;
  [self handshake];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{      
  self.connectionInitiated = NO;
  if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(connectionFailed)]) {
    [self.delegate connectionFailed];
  }  
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{    
  [self receive:message];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {  
  self.connectionInitiated = NO;
  self.webSocketConnected = NO;  
  fayeConnected = NO;
  if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(disconnectedFromServer)]) {
    [self.delegate disconnectedFromServer];
  }
}

#pragma mark -
#pragma mark Deallocation
- (void) dealloc
{
  self.delegate = nil;
}

@end

#pragma mark -
#pragma mark Private
@implementation FayeClient (Private)

- (void) passFayeClientError:(NSError *)error {
  if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(fayeClientError:)]) {
    [self.delegate fayeClientError:error];
  }
}

- (void) send:(id)object
{
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&writeError];
    
    if (writeError) {
        NSLog(@"Could not serialize object as JSON data: %@", [writeError localizedDescription]);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [webSocket send:jsonString];
    }
}

- (void) receive:(id)data
{
    if ([data isKindOfClass:[NSString class]]) {
        data = [data dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSError *readError = nil;
    NSArray *messages = [NSJSONSerialization JSONObjectWithData:data options:0 error:&readError];
    
    if (readError) {
        NSLog(@"Could not deserialize JSON as object: %@", [readError localizedDescription]);
    } else {
        [self parseFayeMessages:messages];
    }
}

#pragma mark -
#pragma mark WebSocket connection
- (void) openWebSocketConnection {
  // clean up any existing socket    
  [webSocket setDelegate:nil];
  [webSocket close];
  webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.fayeURLString]]];
  webSocket.delegate = self;
  self.connectionInitiated = YES;
  [webSocket open];
}

- (void) closeWebSocketConnection { 
  [webSocket close];	    
}

#pragma mark -
#pragma mark Private Bayeux procotol functions

// Bayeux Handshake
// "channel": "/meta/handshake",
// "version": "1.0",
// "minimumVersion": "1.0beta",
// "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe", "websocket]
- (void) handshake {
  NSArray *connTypes = [NSArray arrayWithObjects:@"long-polling", @"callback-polling", @"iframe", @"websocket", nil];   
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:HANDSHAKE_CHANNEL, @"channel", @"1.0", @"version", @"1.0beta", @"minimumVersion", connTypes, @"supportedConnectionTypes", nil];
  [self send:dict];
}

// Bayeux Connect
// "channel": "/meta/connect",
// "clientId": "Un1q31d3nt1f13r",
// "connectionType": "long-polling"
- (void) connect {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:CONNECT_CHANNEL, @"channel", self.fayeClientId, @"clientId", @"websocket", @"connectionType", nil];
  [self send:dict];
}

// {
// "channel": "/meta/disconnect",
// "clientId": "Un1q31d3nt1f13r"
// }
- (void) disconnect {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:DISCONNECT_CHANNEL, @"channel", self.fayeClientId, @"clientId", nil];
  [self send:dict];
}

// {
// "channel": "/meta/subscribe",
// "clientId": "Un1q31d3nt1f13r",
// "subscription": "/foo/**"
// }
- (void) subscribe:(NSString *)channel {
  if(nil == channel) {
    return;
  }
  
  NSDictionary *dict = nil;
  if(nil == self.connectionExtension) {
    dict = [NSDictionary dictionaryWithObjectsAndKeys:SUBSCRIBE_CHANNEL, @"channel", self.fayeClientId, @"clientId", channel, @"subscription", nil];
  } else {
    dict = [NSDictionary dictionaryWithObjectsAndKeys:SUBSCRIBE_CHANNEL, @"channel", self.fayeClientId, @"clientId", channel, @"subscription", self.connectionExtension, @"ext", nil];
  }
  
  [self send:dict];
}

// {
// "channel": "/meta/unsubscribe",
// "clientId": "Un1q31d3nt1f13r",
// "subscription": "/foo/**"
// }
- (void) unsubscribe:(NSString *)channel {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:UNSUBSCRIBE_CHANNEL, @"channel", self.fayeClientId, @"clientId", channel, @"subscription", nil];
  [self send:dict];
}

// {
// "channel": "/some/channel",
// "clientId": "Un1q31d3nt1f13r",
// "data": "some application string or JSON encoded object",
// "id": "some unique message id"
// }

//- (void) publish:(NSDictionary *)messageDict withExt:(NSDictionary *)extension {
- (void) publish:(NSDictionary *)messageDict channel:(NSString *)channel withExt:(NSDictionary *)extension {    
  if(!fayeConnected) {
    [self passFayeClientError:[NSError errorWithDomain:@"FayeNotConnected" code:1 userInfo:nil]];
    return;
  }
  
  if(![openSubscriptions containsObject:channel]) {
    [self passFayeClientError:[NSError errorWithDomain:@"SubscriptionNotActive" code:1 userInfo:nil]];
    return;
  }
  
  NSString *messageId = [NSString stringWithFormat:@"msg_%d_%d", (int)[[NSDate date] timeIntervalSince1970], 1];
  NSDictionary *dict = nil;
  
  if(nil == extension) {
    dict = [NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", self.fayeClientId, @"clientId", messageDict, @"data", messageId, @"id", nil];
  } else {
    dict = [NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", self.fayeClientId, @"clientId", messageDict, @"data", messageId, @"id", extension, @"ext",nil];
  }
  
  [self send:dict];
}

#pragma mark -
#pragma mark Faye message handling
- (void) parseFayeMessages:(NSArray *)messages {
  // interpret the message(s)
  for(NSDictionary *messageDict in messages) {
    FayeMessage *fm = [[FayeMessage alloc] initWithDict:messageDict];
    
    if ([fm.channel isEqualToString:HANDSHAKE_CHANNEL]) {    
      if ([fm.successful boolValue]) {
        self.fayeClientId = fm.clientId;        
        if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(connectedToServer)]) {
          fayeConnected = YES;
          [self.delegate connectedToServer];
        }
        [self connect];
        [self resubscribeOpenSubs];        
      } else {
        NSLog(@"ERROR WITH HANDSHAKE");
      }    
    } else if ([fm.channel isEqualToString:CONNECT_CHANNEL]) {      
      if ([fm.successful boolValue]) {
        fayeConnected = YES;
        [self connect];        
      } else {
        NSLog(@"ERROR CONNECTING TO FAYE");
      }
    } else if ([fm.channel isEqualToString:DISCONNECT_CHANNEL]) {
      if ([fm.successful boolValue]) {        
        fayeConnected = NO;  
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
      } else {
        NSLog(@"ERROR SUBSCRIBING TO %@ WITH ERROR %@", fm.subscription, fm.error);
        if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(subscriptionFailedWithError:)]) {          
          [self.delegate subscriptionFailedWithError:fm.error];
        }        
      }      
    } else if ([fm.channel isEqualToString:UNSUBSCRIBE_CHANNEL]) {
      NSLog(@"UNSUBSCRIBED FROM CHANNEL %@ ON FAYE", fm.subscription);
    } else if ([openSubscriptions containsObject:fm.channel]) {      
      if(fm.data) {        
        if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(messageReceived:channel:)]) {          
          [self.delegate messageReceived:fm.data channel:fm.channel];
        }
      }           
    } else {
      NSLog(@"NO MATCH FOR CHANNEL %@", fm.channel);      
    }    
  }  
}

@end
