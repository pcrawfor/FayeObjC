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
//  FayeClient.h
//  FayeObjC
//
#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
  #import <Cocoa/Cocoa.h>
  #import <YAJL/YAJL.h>
#else
  #import <UIKit/UIKit.h>
  #import "NSObject+YAJL.h"
#endif

#import "ZTWebSocket.h"
enum _fayeStates {
  kWebSocketDisconnected,
  kWebSocketConnected,
  kFayeDisconnected,
  kFayeConnected  
} fayeStates;

// Bayeux protocol channels
#define HANDSHAKE_CHANNEL @"/meta/handshake"
#define CONNECT_CHANNEL @"/meta/connect"
#define DISCONNECT_CHANNEL @"/meta/disconnect"
#define SUBSCRIBE_CHANNEL @"/meta/subscribe"
#define UNSUBSCRIBE_CHANNEL @"/meta/unsubscribe"

@protocol FayeConnectorDelegate <NSObject>

- (void)messageReceived:(NSDictionary *)messageDict;
- (void)connectedToServer;
- (void)disconnectedFromServer;

@end


@interface FayeClient : NSObject <ZTWebSocketDelegate> {
  NSString *fayeURLString;
  ZTWebSocket* webSocket;
  NSString *fayeClientId;
  BOOL webSocketConnected;
  BOOL fayeConnected;  
  NSString *activeSubChannel;
  id <FayeConnectorDelegate> delegate;
}

@property (retain) NSString *fayeURLString;
@property (retain) ZTWebSocket* webSocket;
@property (retain) NSString *fayeClientId;
@property (assign) BOOL webSocketConnected;
@property (assign) BOOL fayeConnected;
@property (retain) NSString *activeSubChannel;
@property (assign) id <FayeConnectorDelegate> delegate;

- (id) initWithURLString:(NSString *)aFayeURLString channel:(NSString *)channel;
- (void) connectToServer;
- (void) disconnectFromServer;
- (void) publishDict:(NSDictionary *)messageDict;

@end
