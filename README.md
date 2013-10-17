# FayeObjC

2.0 is now live on the master branch.

Thanks to steveluscher for all the hard work on getting 2.0 ready to ship.

## About

A simple Objective-C client library for the Faye publish-subscribe messaging server. FayeObjC is implemented atop the SocketRocket Objective-C web socket library and will work on both Mac and iPhone projects.

# Mac Test Client

Included in the repository is a zipped release build of the FayeObjC Mac client.  This client allows you to test your Faye server, it connects over a websocket connection to the server specified and subscribes to the channel specified and will send messages via the server/channel it is connected to.

The messages are of the form { message: "some text" }

If you want to use the mac client to connect and test your faye server just unzip and start it on any mac.

The Mac client is available in the Downloads section of the repo - click "Downloads" to access it.

# Installation

TODO: Write up cocoapods installation instructions.

## Working with the library

Initialize a Client:

    // import the client
    #import "FayeClient.h"

    // init the FayeClient with a server and channel to subscribe to
    FayeClient *faye = [[FayeClient alloc] initWithURLString:@"ws://localhost:8000/faye" channel:@"/chat"];
    faye.delegate = self; // ensure that you implement the FayeClientDelegate functions
    // connect to the server
    [faye connectToServer];
  
Implement the FayeClientDelegate:
 
    - (void) messageReceived:(NSDictionary *)messageDict {
      DLog(@"message received");
      // do something useful with the message dictionary    
    }

    - (void)connectedToServer {
      // Faye connection established    
    }

    - (void)disconnectedFromServer {
      // Faye disconnected
    }

Send a message to the Server:
 
    // The message dictionary can be any dictionary structure that you want to send via the connected channel 
    NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys: @"Some message text", @"message", @"some meta information", @"meta", nil];
    [faye sendMessage:messageDict];

Using Bayeux Extensions:
 
    // Faye supports extensions to accomplish things like authentication  
    // import the client
    #import "FayeClient.h"

    // init the FayeClient with a server and channel to subscribe to
    FayeClient *faye = [[FayeClient alloc] initWithURLString:@"ws://localhost:8000/faye" channel:@"/chat"];
    faye.delegate = self; // ensure that you implement the FayeClientDelegate functions
  
    // setup the extension and connect to the server
    NSDictionary *ext = [NSDictionary dictionaryWithObjectsAndKeys:@"testing", @"authToken", nil];
    [faye connectToServerWithExt:ext];
        
    // sending an extension with a standard message
    NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys: @"Some message text", @"message", @"some meta information", @"meta", nil];
  
    NSDictionary *ext = [NSDictionary dictionaryWithObjectsAndKeys:@"testing", @"authToken", nil];
    [faye sendMessage:messageDict withExt:ext];


Example Project:

Included in the repository is a sample XCode project for Mac that provides a simple client application for interacting with Faye servers.  Try it out and have a look at the code for an illustration on the usage of the library.

The fayeMac sample project allows you to test out any Faye server.

# Development

Want to help us make FayeObjC the best Faye client it can be? Clone, initialize the submodules, and go for it!

    git clone git@github.com:pcrawfor/FayeObjC.git
    cd FayeObjC
    git submodule init
    git submodule update

# Credits

## Faye
Faye is a simple JSON based Pub-Sub server which has support for node.js and Ruby (using Rack).

Check out the Faye project here:

[http://faye.jcoglan.com](http://faye.jcoglan.com)

## SocketRocket
SocketRocket is a conforming Objective-C WebSocket client library by the people at Square.

[https://github.com/square/SocketRocket](https://github.com/square/SocketRocket)

# License

(The MIT License)

Copyright (c) 2011 Paul Crawford

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
