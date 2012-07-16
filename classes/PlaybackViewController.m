#import "PlaybackViewController.h"
#import "PlaybackView.h"
#import "ATMHud.h"
#import "ATMHudQueueItem.h"
#import <QuartzCore/QuartzCore.h>

//#import "PinDisplay.h"

/* Asset keys */
NSString * const kTracksKey         = @"tracks";
NSString * const kPlayableKey		= @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";

/* AVPlayer keys */
NSString * const kRateKey			= @"rate";
NSString * const kCurrentItemKey	= @"currentItem";

NSString * title;

@interface PlaybackViewController ()
- (void)play:(id)sender;
- (void)playMedia;
- (void)pause:(id)sender;
- (void)lockScreen:(id)sender;
- (void)unlockScreen;
- (void)initScrubberTimer;
- (void)showPlayButton;
- (void)showStopButton;
- (void)syncScrubber;
- (void)beginScrubbing:(id)sender;
- (void)scrub:(id)sender;
- (void)endScrubbing:(id)sender;
- (BOOL)isScrubbing;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (id)init;
- (void)dealloc;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)viewDidLoad;
- (void)viewWillDisappear:(BOOL)animated;
- (void)handleSwipe:(UISwipeGestureRecognizer*)gestureRecognizer;
- (void)syncPlayPauseButtons;
- (void)setURL:(NSURL*)URL;
- (NSURL*)URL;
@end

@interface PlaybackViewController (Player)
- (void)removePlayerTimeObserver;
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)playerItemDidReachEnd:(NSNotification *)notification ;
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end

static void *PlaybackViewControllerRateObservationContext = &PlaybackViewControllerRateObservationContext;
static void *PlaybackViewControllerStatusObservationContext = &PlaybackViewControllerStatusObservationContext;
static void *PlaybackViewControllerCurrentItemObservationContext = &PlaybackViewControllerCurrentItemObservationContext;

#pragma mark -
@implementation PlaybackViewController

@synthesize mPlayer, mPlayerItem, mPlaybackView, mToolbar, mPlayButton, mStopButton, mScrubber, swipeHistory, hud, videotitle;

#pragma mark Asset URL

- (void)setURL:(NSURL*)URL
{
	if (mURL != URL)
	{
		mURL = [URL copy];
		
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset keys "tracks", "playable".
         */
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:mURL options:nil];
        
        NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
         ^{		 
             dispatch_async( dispatch_get_main_queue(), 
                            ^{
                                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
         }];
	}
}

- (NSURL*)URL
{
	return mURL;
}

#pragma mark -
#pragma mark Movie controller methods

#pragma mark
#pragma mark Button Action Methods

- (IBAction)play:(id)sender
{
    NSLog(@"play pushed");
    [self playMedia];
}

- (void)playMedia {
	/* If we are at the end of the movie, we must seek to the beginning first 
     before starting playback. */
	if (YES == seekToZeroBeforePlay) 
	{
		seekToZeroBeforePlay = NO;
		[mPlayer seekToTime:kCMTimeZero];
	}

	[mPlayer play];
    [TestFlight passCheckpoint:@"Played video"];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Played video" attributes:[NSDictionary dictionaryWithObjectsAndKeys:videotitle, @"Title", [[NSUserDefaults standardUserDefaults] stringForKey:@"autolock"], @"autolock", [[NSUserDefaults standardUserDefaults] stringForKey:@"repeat"], @"repeat", nil]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autolock"] && ![[[self navigationController] navigationBar] isHidden]) {
        [self lockScreen:nil];
    }
	
    [self showStopButton];        
}

- (IBAction)pause:(id)sender
{
    NSLog(@"pause pushed");
	[mPlayer pause];

    [self showPlayButton];
}

- (IBAction)lockScreen:(id)sender
{
    [TestFlight passCheckpoint:@"Screen locked"];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Screen locked" attributes:[NSDictionary dictionaryWithObjectsAndKeys:videotitle, @"Title", nil]];
    [UIView animateWithDuration:0.2f animations:
     ^{
         [[self navigationController] setNavigationBarHidden:YES animated:YES];
         [mToolbar setFrame:CGRectOffset([mToolbar frame], 0, +mToolbar.frame.size.height)];
         [mToolbar setAlpha:0.0];             
     } completion:
     ^(BOOL finished)
     {
         [UIView animateWithDuration:0.2f animations:
          ^{         
              [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
          } completion:
          ^(BOOL finished)
          {
              NSLog(@"showing confirmation");
              [[NSUserDefaults standardUserDefaults] synchronize];            
              NSString* hudcaption = [NSString stringWithFormat:@"Locked! To unlock, swipe your fingers down in the following order: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"unlockcode"]];

              // How complete is the code?
              UIImage* hudimage = [UIImage imageNamed:@"Lock"];
              float hudduration = 5.0;
              [hud setBlockTouches:NO];
              [hud setCaption:hudcaption];
              [hud setImage:hudimage];        
              [hud show];
              [hud hideAfter:hudduration];
          }];
     }];
}

- (void)unlockScreen
{
    [TestFlight passCheckpoint:@"Screen unlocked"];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Screen unlocked" attributes:[NSDictionary dictionaryWithObjectsAndKeys:videotitle, @"Title", [[NSUserDefaults standardUserDefaults] stringForKey:@"unlockcode"], @"Unlock code", nil]];
    
    [UIView animateWithDuration:0.2f animations:
     ^{
         [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
     } completion:
     ^(BOOL finished)
     {
         [UIView animateWithDuration:0.2f animations:
          ^{         
              [[self navigationController] setNavigationBarHidden:NO animated:YES];
              [mToolbar setFrame:CGRectOffset([mToolbar frame], 0, -mToolbar.frame.size.height)];
              [mToolbar setAlpha:1.0];             

          } completion:
          ^(BOOL finished)
          {
// code to move notification center
          }];
     }];
}

#pragma mark -
#pragma mark Play, Stop buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    NSLog(@"show stop button");
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[mToolbar items]];
    NSLog(@"toolbar items: %@", toolbarItems);
    if (toolbarItems && (toolbarItems.count>0)) {
        [toolbarItems replaceObjectAtIndex:0 withObject:mStopButton];
        mToolbar.items = toolbarItems;
    }
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[mToolbar items]];
    NSLog(@"toolbarItems: %@", toolbarItems);
    NSLog(@"mToolbar items: %@", [mToolbar items]);
    if (toolbarItems && (toolbarItems.count>0)) {
        [toolbarItems replaceObjectAtIndex:0 withObject:mPlayButton];
        mToolbar.items = toolbarItems;
    }
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        [self showStopButton];
	}
	else
	{
        [self showPlayButton];        
	}
}

-(void)enablePlayerButtons
{
    self.mPlayButton.enabled = YES;
    self.mStopButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.mPlayButton.enabled = NO;
    self.mStopButton.enabled = NO;
}

#pragma mark -
#pragma mark Movie scrubber control

/* ---------------------------------------------------------
**  Methods to handle manipulation of the movie scrubber control
** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
	double interval = .1f;	
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		return;
	} 
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([mScrubber bounds]);
		interval = 0.5f * duration / width;
	}

	/* Update the scrubber during normal playback. */
    __block id myself = self;    
	mTimeObserver = [mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
								queue:NULL /* If you pass NULL, the main queue is used. */
								usingBlock:^(CMTime time) 
                                            {
                                                [myself syncScrubber];
                                            }];

}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		mScrubber.minimumValue = 0.0;
		return;
	} 

	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		float minValue = [mScrubber minimumValue];
		float maxValue = [mScrubber maximumValue];
		double time = CMTimeGetSeconds([mPlayer currentTime]);
		
		[mScrubber setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)beginScrubbing:(id)sender
{
	mRestoreAfterScrubbingRate = [mPlayer rate];
	[mPlayer setRate:0.f];
	
	/* Remove previous timer. */
	[self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (void)scrub:(id)sender
{
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		} 
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
			[mPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing:(id)sender
{
	if (!mTimeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) 
		{
			return;
		} 
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([mScrubber bounds]);
			double tolerance = 0.5f * duration / width;

            __block id myself = self;            
			mTimeObserver = [mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
			^(CMTime time)
			{
				[myself syncScrubber];
			}];
		}
	}

	if (mRestoreAfterScrubbingRate)
	{
		[mPlayer setRate:mRestoreAfterScrubbingRate];
		mRestoreAfterScrubbingRate = 0.f;
	}
}

- (BOOL)isScrubbing
{
	return mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.mScrubber.enabled = YES;
}

-(void)disableScrubber
{
    self.mScrubber.enabled = NO;    
}

#pragma mark
#pragma mark View Controller

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		mPlayer = nil;		
		
		[self setWantsFullScreenLayout:YES];
	}
	
	return self;
}

- (id)init
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
    {
        return [self initWithNibName:@"PlaybackView-iPad" bundle:nil];
	} 
    else 
    {
        return [self initWithNibName:@"PlaybackView" bundle:nil];
	}
}

- (void)viewDidUnload
{
    self.mPlaybackView = nil;
	
    self.mToolbar = nil;
    self.mPlayButton = nil;
    self.mStopButton = nil;
    self.mScrubber = nil;
        
    [super viewDidUnload];
}



- (void)viewDidLoad
{    
	mPlayer = nil;
    swipeHistory = [[NSMutableString alloc] initWithString:@""];

	UIView* view  = [self view];
	
    // Set up multitouch queues
    // down
	UISwipeGestureRecognizer* swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];    
    [swipeDownRecognizer setNumberOfTouchesRequired:1];
	[view addGestureRecognizer:swipeDownRecognizer];
    
	swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];    
    [swipeDownRecognizer setNumberOfTouchesRequired:2];
	[view addGestureRecognizer:swipeDownRecognizer];
    
	swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];    
    [swipeDownRecognizer setNumberOfTouchesRequired:3];
	[view addGestureRecognizer:swipeDownRecognizer];
    
    // left
    swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];    
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];    
    [swipeDownRecognizer setNumberOfTouchesRequired:1];
	[view addGestureRecognizer:swipeDownRecognizer];
    
	swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];    
    [swipeDownRecognizer setNumberOfTouchesRequired:2];
	[view addGestureRecognizer:swipeDownRecognizer];
    
	swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];    
    [swipeDownRecognizer setNumberOfTouchesRequired:3];
	[view addGestureRecognizer:swipeDownRecognizer];
    
    // right
    swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];    
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];    
    [swipeDownRecognizer setNumberOfTouchesRequired:1];
	[view addGestureRecognizer:swipeDownRecognizer];
    
	swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];    
    [swipeDownRecognizer setNumberOfTouchesRequired:2];
	[view addGestureRecognizer:swipeDownRecognizer];
    
	swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];    
    [swipeDownRecognizer setNumberOfTouchesRequired:3];
	[view addGestureRecognizer:swipeDownRecognizer];    

    UIBarButtonItem *scrubberItem = [[UIBarButtonItem alloc] initWithCustomView:mScrubber];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIImage *lockImg = [UIImage imageNamed:@"Unlock"]; 
    UIButton *lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    lockButton.userInteractionEnabled = YES;
    [lockButton setFrame:CGRectMake(0.0,0.0, 30, 36)];
    [lockButton setImage:lockImg forState:UIControlStateNormal];
    [lockButton addTarget:self action:@selector(lockScreen:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *lockItem = [[UIBarButtonItem alloc] initWithCustomView:lockButton];
    
    mToolbar.items = [NSArray arrayWithObjects:mPlayButton, flexItem, scrubberItem, flexItem, lockItem, nil];

	[self initScrubberTimer];
	
	[self syncPlayPauseButtons];
	[self syncScrubber];
    
	hud = [[ATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
    
    

    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[mPlayer pause];
	seekToZeroBeforePlay = YES;
    [mPlayer seekToTime:kCMTimeZero];    
    [self setTitle:@""];
	
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)setViewDisplayName
{
    /* Set the view title to the last component of the asset URL. */
    self.title = videotitle;
    
    /* Or if the item has a AVMetadataCommonKeyTitle metadata, use that instead. */
	for (AVMetadataItem* item in ([[[mPlayer currentItem] asset] commonMetadata]))
	{
		NSString* commonKey = [item commonKey];
		
		if ([commonKey isEqualToString:AVMetadataCommonKeyTitle])
		{
			self.title = videotitle;
		}
	}
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    NSLog(@"Swipe!");
    [[NSUserDefaults standardUserDefaults] synchronize];            
    NSString* unlockCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"unlockcode"];
    if (unlockCode.length < 3) unlockCode = @"321";
    NSLog(@"unlock code is: %@", unlockCode);
    
    if ([[[self navigationController] navigationBar] isHidden]) {
        // No need to pay attention unless display is locked
        NSUInteger touches = gestureRecognizer.numberOfTouches;   
        [swipeHistory appendString:[NSString stringWithFormat:@"%d", touches]];
        if (swipeHistory.length > 3) {
            [swipeHistory setString:[swipeHistory substringFromIndex:[swipeHistory length] - 3]];
        }

        if ([swipeHistory isEqualToString:unlockCode]) {
            [self unlockScreen];
        } else {
            NSLog(@"Swipe history: %@", swipeHistory);        
        }
        
        // How complete is the code?
        UIImage* hudimage;
        
        NSString* code1text = [[NSString alloc] init];
        NSString* code2text = [[NSString alloc] init];
        UIFont* font1 = [UIFont fontWithName:@"TrebuchetMS-Bold" size:24.0f];
        UIFont* font2 = [UIFont fontWithName:@"TrebuchetMS" size:24.0f];

        if ((swipeHistory.length>=1) && [[swipeHistory substringFromIndex:[swipeHistory length] - 1] isEqualToString:[unlockCode substringToIndex:1]]) {
            code1text = [unlockCode substringToIndex:1];
            code2text = [unlockCode substringFromIndex:1];
        } else if ((swipeHistory.length>=2) && [[swipeHistory substringFromIndex:[swipeHistory length] - 2] isEqualToString:[unlockCode substringToIndex:2]]) {
            code1text =[unlockCode substringToIndex:2];  
            code2text =[unlockCode substringFromIndex:2];
        } else if ((swipeHistory.length>=3) && [swipeHistory isEqualToString:unlockCode]) {
            code1text = unlockCode;
            code2text = @"";
        }
        
        UILabel *code1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [code1text sizeWithFont:font1].width+[code2text sizeWithFont:font2].width, 30)];
        [code1 setFont:font1];
        [code1 setTextColor:[UIColor whiteColor]];
        [code1 setBackgroundColor:[UIColor clearColor]];
        [code1 setTextAlignment:UITextAlignmentLeft];
        [code1 setText:code1text];
        
        NSLog(@"part 2 is at %f", [code1text sizeWithFont:font1].width);
        UILabel *code2 = [[UILabel alloc] initWithFrame:CGRectMake([code1text sizeWithFont:font1].width, 0, [code2text sizeWithFont:font2].width+[code1text sizeWithFont:font1].width, 30)];
        [code2 setFont:[UIFont fontWithName:@"TrebuchetMS" size:24.0f]];
        [code2 setTextColor:[UIColor lightGrayColor]];
        [code2 setBackgroundColor:[UIColor clearColor]];
        [code2 setTextAlignment:UITextAlignmentRight];   
        [code2 setText:code2text];
        
        
        UIGraphicsBeginImageContext(CGSizeMake(code1.frame.size.width, code1.frame.size.height));
        [code1.layer renderInContext:UIGraphicsGetCurrentContext()];
        [code2.layer renderInContext:UIGraphicsGetCurrentContext()];        
        hudimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSString* hudcaption = @"";
        float hudduration = 5.0;
        if ((swipeHistory.length>=3) && [swipeHistory isEqualToString:unlockCode]) {
            NSLog(@"swipe 3/3");
            hudcaption = @"Success!";
            hudduration = 0.5;
        } else if ((swipeHistory.length>=2) && [[swipeHistory substringFromIndex:[swipeHistory length] - 2] isEqualToString:[unlockCode substringToIndex:2]]) {
            NSLog(@"swipe 2/3");            
            hudcaption = @"Unlocking...";            
        } else if ((swipeHistory.length>=1) && [[swipeHistory substringFromIndex:[swipeHistory length] - 1] isEqualToString:[unlockCode substringToIndex:1]]) {
            NSLog(@"swipe 1/3");            
            hudcaption = @"Unlocking...";            
        } else if (((swipeHistory.length>=2) && [[swipeHistory substringWithRange:NSMakeRange([swipeHistory length] - 2, 1)] isEqualToString:[unlockCode substringToIndex:1]]) ||
                   ((swipeHistory.length>=3) && ([[swipeHistory substringWithRange:NSMakeRange([swipeHistory length] - 3, 2)] isEqualToString:[unlockCode substringToIndex:2]])))  {
            NSLog(@"locked!");            
            hudcaption = @"Locked!";            
            hudimage = [UIImage imageNamed:@"x"]; 
            hudduration = 0.5;
            
            [TestFlight passCheckpoint:@"Unlock failed"];
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Unlock failed" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] stringForKey:@"unlockcode"], @"Unlock code", swipeHistory, @"Attempt", nil]];
        }
                
        if (hudcaption.length > 0) {
            [hud setCaption:hudcaption];
            [hud setImage:hudimage];        
            [hud show];
            [hud hideAfter:hudduration];
        } else {
            [self reminderFadeIn:unlockCode];
        }

    }
}

-(void)reminderFadeIn:(NSString*)unlockCode {
    if (reminder.alpha == 0) {
        reminder = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-20, self.view.bounds.size.width, 20)];
        [reminder setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.9f]];
        [reminder setText:[NSString stringWithFormat:@"Reminder: Your unlock code is %@", unlockCode]];
        [reminder setTextColor:[UIColor darkGrayColor]];
        [reminder setFont:[UIFont fontWithName:@"Courier-Bold" size:14.0f]];
        [reminder setTextAlignment:UITextAlignmentCenter];
        [reminder setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
        [reminder setAlpha:0.0];
        
        [self.view addSubview:reminder];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:1.0f];
        [reminder setAlpha:0.9f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(reminderPause:finished:context:)];
        [UIView commitAnimations];    
    }
}

-(void)reminderPause:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [self performSelector:@selector(reminderFadeOut) withObject:self afterDelay:2.0f];
}

-(void)reminderFadeOut {
    NSLog(@"done fading in");
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0];
    [reminder setAlpha:0];
    [UIView commitAnimations];    
}

#pragma mark ATMHud Delegate methods

- (void)userDidTapHud:(ATMHud *)_hud {
    NSLog(@"tapped!");
    [_hud hide];
}

- (void)dealloc
{
	[self removePlayerTimeObserver];
	
	[mPlayer removeObserver:self forKeyPath:@"rate"];
	[mPlayer.currentItem removeObserver:self forKeyPath:@"status"];
	
	[mPlayer pause];
}

@end

@implementation PlaybackViewController (Player)

#pragma mark Player Item

- (BOOL)isPlaying
{
	return mRestoreAfterScrubbingRate != 0.f || [mPlayer rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification 
{
	/* After the movie has played to its end time, seek back to time zero 
		to play it again. */
	seekToZeroBeforePlay = YES;
    
    [TestFlight passCheckpoint:@"Video reached end"];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Video reached end" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] stringForKey:@"repeat"], @"repeat", nil]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"repeat"]) {    
        [self playMedia];
    }
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem. 
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
	AVPlayerItem *playerItem = [mPlayer currentItem];
	if (playerItem.status == AVPlayerItemStatusReadyToPlay)
	{
        /* 
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice 
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3. 
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching 
         the value of the duration property of its associated AVAsset object. However, 
         note that for HTTP Live Streaming Media the duration of a player item during 
         any particular playback session may differ from the duration of its asset. For 
         this reason a new key-value observable duration property has been defined on 
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */		

		return([playerItem duration]);
	}
	
	return(kCMTimeInvalid);
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if (mTimeObserver)
	{
		[mPlayer removeTimeObserver:mTimeObserver];
		mTimeObserver = nil;
	}
}

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 ** 
 **  1) values of asset keys did not load successfully, 
 **  2) the asset keys did load successfully, but the asset is not 
 **     playable
 **  3) the item did not become ready to play. 
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}


#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    NSLog(@"Preparing to play");
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
	}
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) 
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */
    	
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.mPlayerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.mPlayerItem removeObserver:self forKeyPath:kStatusKey];            
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.mPlayerItem addObserver:self 
                      forKeyPath:kStatusKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:PlaybackViewControllerStatusObservationContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.mPlayerItem];
	
    seekToZeroBeforePlay = NO;
	
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.mPlayerItem]];	
		
        /* Observe the AVPlayer "currentItem" property to find out when any 
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
         occur.*/
        [self.player addObserver:self 
                      forKeyPath:kCurrentItemKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:PlaybackViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self 
                      forKeyPath:kRateKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:PlaybackViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.mPlayerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs 
         asynchronously; observe the currentItem property to find out when the 
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.mPlayerItem];
        
        [self syncPlayPauseButtons];
    }
	
    [mScrubber setValue:0.0];
    
    [self playMedia];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
**  Called when the value at the specified key path relative
**  to the given object has changed. 
**  Adjust the movie play and pause button controls when the 
**  player item "status" value changes. Update the movie 
**  scrubber control when the player item is ready to play.
**  Adjust the movie scrubber control when the player item 
**  "rate" value changes. For updates of the player
**  "currentItem" property, set the AVPlayer for which the 
**  player layer displays visual output.
**  NOTE: this method is invoked on the main queue.
** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path 
			ofObject:(id)object 
			change:(NSDictionary*)change 
			context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
	if (context == PlaybackViewControllerStatusObservationContext)
	{
		[self syncPlayPauseButtons];

        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            /* Indicates that the status of the player is not yet known because 
             it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
            break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e. 
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initScrubberTimer];
                
                [self enableScrubber];
                [self enablePlayerButtons];
            }
            break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
            break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == PlaybackViewControllerRateObservationContext)
	{
        [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer. 
        Called when the AVPlayer replaceCurrentItemWithPlayerItem: 
        replacement will/did occur. */
	else if (context == PlaybackViewControllerCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [mPlaybackView setPlayer:mPlayer];
            
            [self setViewDisplayName];
            
            /* Specifies that the player should preserve the video’s aspect ratio and 
             fit the video within the layer’s bounds. */
            [mPlaybackView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
}


@end

