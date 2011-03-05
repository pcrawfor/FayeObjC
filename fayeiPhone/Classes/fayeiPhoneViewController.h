//
//  fayeiPhoneViewController.h
//  fayeiPhone
//
//  Created by Paul Crawford on 11-03-04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FayeClient.h"

@interface fayeiPhoneViewController : UIViewController <FayeConnectorDelegate> {
  FayeClient *faye;
  BOOL connected;
}

@property (retain) FayeClient *faye;
@property (assign) BOOL connected;

@end

