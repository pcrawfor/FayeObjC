//
//  fayeMacAppDelegate.m
//  fayeMac
//
//  Created by Paul Crawford on 3/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "fayeMacAppDelegate.h"

@implementation fayeMacAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
  
  //application/json HTTP POST request    	
	/*
   "channel": "/meta/handshake",
   "version": "1.0",
   "minimumVersion": "1.0beta",
   "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe"]
   */
  
  // Bayeux HANDSHAKE
  /* ++
  NSArray *connTypes = [NSArray arrayWithObjects:@"long-polling", @"callback-polling", @"iframe", nil];  
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"/meta/handshake", @"channel", @"1.0", @"version", @"1.0beta", @"minimumVersion", connTypes, @"supportedConnectionTypes", nil];
  NSDictionary *responseDict = nil;
  NSData *resultData = [self requestWithDataDict:dict];
  if(nil != resultData) {
    NSString *result = [[[NSString alloc] initWithData:resultData encoding:[NSString defaultCStringEncoding]] autorelease];
    DLog(@"Class %@", [[result yajl_JSON] className]);
    NSArray *resultArray = [result yajl_JSON];
    DLog(@"RESULT %@", result);
    DLog(@"RESULTS ARRAY %@", resultArray);
    if ([resultArray count] > 0) {
      id obj = [resultArray objectAtIndex:0];
      DLog(@"OBJ: %@", obj);
      responseDict = (NSDictionary *)obj;
    }
  }
      
  DLog(@"CLIENT ID %@", [responseDict objectForKey:@"clientId"]);
  NSString *clientId = [responseDict objectForKey:@"clientId"];
  ++ */
  
  // Bayeux Connect
  /*
   [
   {
   "channel": "/meta/connect",
   "clientId": "Un1q31d3nt1f13r",
   "connectionType": "long-polling"
   }
   ]
   */
  
  /*DLog(@"TRY TO CONNECT");
  NSDictionary *connectDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/meta/connect", @"channel", clientId, @"clientId", @"long-polling", @"connectionType", nil];
  NSData *connData = [self requestWithDataDict:connectDict];
  if(nil != resultData) {
    NSString *result = [[[NSString alloc] initWithData:connData encoding:[NSString defaultCStringEncoding]] autorelease];
    DLog(@"Class %@", [[result yajl_JSON] className]);  
    DLog(@"CONN RESULT %@", result);
  } else {
    DLog(@"NO DATA");
  }*/
  
  //NSDictionary *connectDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/meta/connect", @"channel", clientId, @"clientId", @"long-polling", @"connectionType", nil];    
}


/*- (NSData *) requestWithDataDict:(NSDictionary *)dict {
  NSData *queryData = [[dict yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
  NSString *queryLength = [NSString stringWithFormat:@"%d", [queryData length]];
	
	NSMutableURLRequest *request= [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:@"http://localhost:8000/faye"]];
	[request setHTTPMethod:@"POST"];	
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:queryLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:queryData];
  
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;  
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[request release];
  if (error) {
		NSString *reason= @"URL connection returned error: ";
		reason= [reason stringByAppendingString:[error description]];				
    DLog(@"REASON %@", reason);
    return nil;
	} else {
    return data;
  }  
}*/

@end
