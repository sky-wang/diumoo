//
//  musicPlayer.m
//  diumoo
//
//  Created by Shanzi on 11-12-8.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "musicPlayer.h"


@implementation musicPlayer

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        cond=[[[NSCondition alloc] init] retain] ;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ended) name:QTMovieDidEndNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playing_rate) name:QTMovieRateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(stopAutoFade) name:@"playbuttonpressed" object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(load_state:) name:QTMovieLoadStateDidChangeNotification object:nil];
        level=[[[FrequencyLevels alloc] init] retain];
        token=YES;
    }
    
    return self;
}

-(void) load_state:(NSNotification*)n
{
    [cond lock];
    //if(![lock tryLock])return;
    if(token) {[cond unlock];return;}
    if([[n.object attributeForKey: QTMovieLoadStateAttribute] intValue]>=QTMovieLoadStatePlayable)
    {
        [level setMovie:n.object];
        [level toggleFreqLevels:NSOnState];
        token=YES;
    }
    else{
        [level toggleFreqLevels:NSOffState];
        token=NO;
    }
    [cond unlock];
}

-(void) _start_to_play_notification:(NSDictionary *)m
{
    NSImage* image=[[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[m valueForKey:@"Picture"]]] retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"player.startToPlay" object:image userInfo:m];
    [image release];
}

-(BOOL) startToPlay:(NSDictionary *)music
{
    if (autoFadeTimer != nil) {
		[self stopAutoFade];
	}
    [cond lock];
    NSLog(@"start to play:%@",music);
    [level toggleFreqLevels: NSOffState];
    if(player!=nil)
    {
        [self _pause];
        
        [player invalidate];
        [player release];
        player=nil;
    }
    NSError* e=nil;
    player=[[QTMovie movieWithURL:[NSURL URLWithString:[music valueForKey:@"Location"]] error:&e] retain]; 
    token=NO;
    
    
    
    if(e==NULL) 
    {
        [self performSelectorInBackground:@selector(_start_to_play_notification:) withObject:music];
        [player autoplay];
    }
    
    [cond unlock];
    return (e==NULL);
}
-(void) _pause
{
    if(player!=nil&&[player rate]!=0){
        [self startAutoFadeDuration:VOLUME_INTERVAL startVolume:1.0 targetVolume:0.0];
    }
}
-(void) play
{
    [cond lock];
    if(player != nil&& [player rate]==0){
        [self startAutoFadeDuration:VOLUME_INTERVAL startVolume:0.0 targetVolume:1.0];
    }
    [cond unlock];
}
-(void) pause
{
    [cond lock];
    [self _pause];
    [cond unlock];
}
/*
-(void) _set_volume:(float)v
{
    if(player ==nil) return;
    float vo=[player volume];
    int i=0;
    for (; i<=VOLUME_DURATION; i++) {
        [player setVolume:(vo+(v-vo) *(i/VOLUME_DURATION))];
        [NSThread sleepForTimeInterval:VOLUME_INTERVAL];
    }
    
}
*/
-(BOOL) isPlaying
{
    return (player!=nil && [player rate]>0.99);
}



-(void) ended
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"player.end" object:nil userInfo:nil];
}

-(void) playing_rate
{
    if(player==nil) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"player.rateChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[player rate]] forKey:@"rate"] ];
}

- (void)startAutoFadeDuration:(float)duration startVolume:(float)startVolume targetVolume:(float)target {
	if (autoFadeTimer != nil) {
		[self stopAutoFade];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"player.rateChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:target] forKey:@"rate"] ];
	autoFadeDuration = duration;
	autoFadeStartVolume = startVolume;
	autoFadeTargetVolume = target;
    autoFadeTimer = [[NSTimer timerWithTimeInterval:duration target:self selector:@selector(updateAutoFade:) userInfo:nil repeats:YES]retain];
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), (CFRunLoopTimerRef)autoFadeTimer, kCFRunLoopCommonModes);
    if (autoFadeTargetVolume==1) {
        [player play];
    }
	[autoFadeTimer fire];
}

- (void)stopAutoFade {
	if (autoFadeTimer != nil) {
		[autoFadeTimer invalidate];
		[autoFadeTimer release];
		autoFadeTimer = nil;
        if (autoFadeTargetVolume==0) {
            [player stop];
        }
	}
}

- (void)updateAutoFade:(NSTimer*)theTimer{
    if (autoFadeTargetVolume==0) {
        if (player.volume>0) {
            [player setVolume:([player volume]-(1/VOLUME_DURATION))];
        } else {
            [self stopAutoFade];
        }
    }else{
        if (player.volume<=1) {
            [player setVolume:([player volume]+(1/VOLUME_DURATION))];
        } else {
            [self stopAutoFade];
        }
    }
}

-(void) dealloc
{
    [cond release];
    [player release];
    [super dealloc];
}
@end

