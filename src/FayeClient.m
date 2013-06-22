
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
  NSMutableSet *queuedSubscriptions;
  NSMutableSet *pendingSubscriptions;
  NSMutableSet *openSubscriptions;
}

@synthesize fayeURLString;
@synthesize webSocket;
@synthesize fayeClientId;
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
    fayeConnected = NO;
    queuedSubscriptions = [[NSMutableSet alloc] init];
    pendingSubscriptions = [[NSMutableSet alloc] init];
    openSubscriptions = [[NSMutableSet alloc] init];
    if(nil != channel) {
      if(![queuedSubscriptions containsObject:channel]) {
        [queuedSubscriptions addObject:channel];
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
  if([pendingSubscriptions containsObject:channel] || [openSubscriptions containsObject:channel]) return;
  
  if(fayeConnected) {
    [self subscribe:channel];
  } else {
    [queuedSubscriptions addObject:channel];
  }
}

- (void) unsubscribeFromChannel:(NSString *)channel {
  [queuedSubscriptions removeObject:channel];
  [self unsubscribe:channel];
}

- (BOOL) isSubscribedToChannel:(NSString *)channel {
  return [openSubscriptions containsObject:channel];
}

- (void) subscribeQueuedSubscriptions {
  
  // if there are any outstanding open subscriptions resubscribe
  if ([queuedSubscriptions count] > 0) {
    NSSet *queue = [queuedSubscriptions copy];
    for(NSString *channel in queue) {
      [queuedSubscriptions removeObject:channel];
      [self subscribeToChannel:channel];
    }
  }
}

- (BOOL)webSocketConnected { return self.webSocket.readyState == SR_OPEN; }
+ (NSSet *)keyPathsForValuesAffectingWebSocketConnected { return [NSSet setWithObject:@"websocket.readyState"]; }

#pragma -
#pragma mark SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
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
  fayeConnected = NO;
  
  [queuedSubscriptions unionSet:pendingSubscriptions];
  [queuedSubscriptions unionSet:openSubscriptions];
  [pendingSubscriptions removeAllObjects];
  [openSubscriptions removeAllObjects];
  
  if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(disconnectedFromServer)]) {
    [self.delegate disconnectedFromServer];
  }
}

#pragma mark -
#pragma mark Deallocation
- (void) dealloc
{
  // clean up any existing socket
  [self closeWebSocketConnection];
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

- (NSString *) base36Encode:(uint32_t)value
{
  NSString *base36 = @"0123456789abcdefghijklmnopqrstuvwxyz";
  NSString *buffer = @"";
  
  do {
    NSString *newChar = [NSString stringWithFormat:@"%c", [base36 characterAtIndex:(value % 36)]];
    buffer = [newChar stringByAppendingString:buffer];
  } while (value /= 36);
  
  return buffer;
}

- (NSString *) nextMessageId
{
  messageNumber++;
  if (messageNumber >= UINT32_MAX) messageNumber = 0;
  
  return [self base36Encode:messageNumber];
}

- (void) send:(id)object
{
    [self pipeThroughOutgoingExtensions:object withCallback:^(id object){
        NSError *writeError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&writeError];
        
        if (writeError) {
            NSLog(@"Could not serialize object as JSON data: %@", [writeError localizedDescription]);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [webSocket send:jsonString];
        }
    }];
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
  [self closeWebSocketConnection];
  
  webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.fayeURLString]]];
  webSocket.delegate = self;
  self.connectionInitiated = YES;
  [webSocket open];
}

- (void) closeWebSocketConnection {
  [webSocket setDelegate:nil];
  [webSocket close];
  webSocket = nil;
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
  
  // Add the channel to pending
  [pendingSubscriptions addObject:channel];
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
  
  NSString *messageId = [self nextMessageId];
  NSDictionary *dict = nil;
  
  if(nil == extension) {
    dict = [NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", self.fayeClientId, @"clientId", messageDict, @"data", messageId, @"id", nil];
  } else {
    dict = [NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", self.fayeClientId, @"clientId", messageDict, @"data", messageId, @"id", extension, @"ext",nil];
  }
  
  [self send:dict];
}

# pragma mark - Faye extensions

- (void)pipeThroughIncomingExtensions:(NSDictionary *)messageDict withCallback:(FayeClientMessageHandler)callback
{
    [self pipeThroughExtensions:messageDict inDirection:@"incoming" withCallback:callback];
}

- (void)pipeThroughOutgoingExtensions:(NSDictionary *)messageDict withCallback:(FayeClientMessageHandler)callback
{
    [self pipeThroughExtensions:messageDict inDirection:@"outgoing" withCallback:callback];
}

- (void)pipeThroughExtensions:(NSDictionary *)messageDict inDirection:(NSString *)direction withCallback:(FayeClientMessageHandler)callback
{
    SEL pipeHandler = nil;
    
    if ([direction isEqualToString:@"incoming"]) {
        pipeHandler = @selector(fayeClientWillReceiveMessage:withCallback:);
    } else if ([direction isEqualToString:@"outgoing"]) {
        pipeHandler = @selector(fayeClientWillSendMessage:withCallback:);
    } else {
        NSLog(@"You've attempted to pipe a message through an unknown pipe. Choices are \"outgoing\" and \"incoming\"");
    }
    
    if (pipeHandler != nil && [self.delegate respondsToSelector:pipeHandler]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:pipeHandler withObject:messageDict withObject:callback];
        #pragma clang diagnostic pop
    } else {
        callback(messageDict);
    }
}

#pragma mark -
#pragma mark Faye message handling
- (void) parseFayeMessages:(NSArray *)messages {
    // interpret the message(s)
    for(NSDictionary *messageDict in messages) {
        [self pipeThroughIncomingExtensions:messageDict withCallback:^(NSDictionary *messageDict){
            FayeMessage *fm = [[FayeMessage alloc] initWithDict:messageDict];
    
            if ([fm.channel isEqualToString:HANDSHAKE_CHANNEL]) {
                if ([fm.successful boolValue]) {
                  self.fayeClientId = fm.clientId;        
                  if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(connectedToServer)]) {
                      fayeConnected = YES;
                      [self.delegate connectedToServer];
                  }
                  [self connect];
                  [self subscribeQueuedSubscriptions];
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
                [pendingSubscriptions removeObject:fm.subscription];
                if ([fm.successful boolValue]) {
                    NSLog(@"SUBSCRIBED TO CHANNEL %@ ON FAYE", fm.subscription);
                    [openSubscriptions addObject:fm.subscription];
                    if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(didSubscribeToChannel:)]) {          
                        [self.delegate didSubscribeToChannel:fm.subscription];
                    }
                } else {
                    NSLog(@"ERROR SUBSCRIBING TO %@ WITH ERROR %@", fm.subscription, fm.error);
                    if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(subscriptionFailedWithError:)]) {          
                        [self.delegate subscriptionFailedWithError:fm.error];
                    }        
                }      
            } else if ([fm.channel isEqualToString:UNSUBSCRIBE_CHANNEL]) {
                  NSLog(@"UNSUBSCRIBED FROM CHANNEL %@ ON FAYE", fm.subscription);
                  [openSubscriptions removeObject:fm.subscription];
                  if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(didUnsubscribeFromChannel:)]) {          
                      [self.delegate didUnsubscribeFromChannel:fm.subscription];
                  }
            } else if ([openSubscriptions containsObject:fm.channel]) {      
                if(fm.data) {        
                    if(self.delegate != NULL && [self.delegate respondsToSelector:@selector(messageReceived:channel:)]) {          
                        [self.delegate messageReceived:fm.data channel:fm.channel];
                    }
                }           
            } else {
                NSLog(@"NO MATCH FOR CHANNEL %@", fm.channel);      
            }
        }];
    }
}

@end
