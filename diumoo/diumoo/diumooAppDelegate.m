//
//  diumooAppDelegate.m
//  diumoo
//
//  Created by Shanzi on 11-12-5.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "diumooAppDelegate.h"
#import "preference.h"
#import "controlCenter.h"

@implementation diumooAppDelegate

//@synthesize window;

+(void) initialize
{
    if([self class] != [diumooAppDelegate class]) return;
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,nil]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    g=[[notifier alloc] init];
    s=[[doubanFMSource alloc] init];
    p=[[musicPlayer alloc] init];
    m=[[menu alloc]init];
    
    [preference sharedPreference];
     
    [[controlCenter sharedCenter] setPlayer:p];
    [[controlCenter sharedCenter] setSource:s];
    
    
    keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
	if([SPMediaKeyTap usesGlobalMediaKeyTap])
		[keyTap startWatchingMediaKeys];
	else
		NSLog(@"Media key monitoring disabled");
    
    
    [[controlCenter sharedCenter] performSelectorInBackground:@selector(startToPlay) withObject:nil ];
    
    
}

-(void) applicationWillTerminate:(NSNotification *)notification
{
    [[controlCenter sharedCenter] pause];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.iTunes.playerInfo" object:@"com.apple.iTunes.player" userInfo:nil];
}

-(IBAction)showPreference:(id)sender
{
    if([sender tag]==3) [preference showPreferenceWithView:INFO_PREFERENCE_ID];
    else [preference showPreferenceWithView:GENERAL_PREFERENCE_ID];
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event{
    
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    int keyState = (((keyFlags & 0xFF00) >> 8)) ==0xA;
    if(keyState==0)
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"PlayPauseFastHotKey"] integerValue]==NSOnState)
                    [[controlCenter sharedCenter] play_pause];
                break;
            case NX_KEYTYPE_FAST:
                if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"PlayPauseFastHotKey"] integerValue]==NSOnState)
                    [[controlCenter sharedCenter] skip];
                break;
            case NX_KEYTYPE_REWIND:
                if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"RateHotKey"] integerValue]==NSOnState)
                    [[controlCenter sharedCenter] rate];
                break;
        }

}


-(void) dealloc
{
    [g release];
    [s release];
    [p release];
    [m release];
    [keyTap release];
    [super dealloc];
}



@end