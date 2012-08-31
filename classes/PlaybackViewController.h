#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ATMHudDelegate.h"
@class ATMHud;

@class AVPlayer;
@class PlaybackView;

@interface PlaybackViewController : UIViewController <ATMHudDelegate>
{
@private
	IBOutlet PlaybackView* mPlaybackView;
	
	IBOutlet UISlider* mScrubber;
    IBOutlet UIToolbar *mToolbar;
    IBOutlet UIBarButtonItem *mPlayButton;
    IBOutlet UIBarButtonItem *mStopButton;

	float mRestoreAfterScrubbingRate;
	BOOL seekToZeroBeforePlay;
	id mTimeObserver;

	NSURL* mURL;
    
	AVPlayer* mPlayer;
    AVPlayerItem * mPlayerItem; 
    
	ATMHud *hud;   
    NSString* videotitle;
    UILabel *reminder;
    int playCount;
}

@property (nonatomic, copy) NSURL* URL;
@property (readwrite, retain, setter=setPlayer:, getter=player) AVPlayer* mPlayer;
@property (retain) AVPlayerItem* mPlayerItem;
@property (nonatomic, retain) IBOutlet PlaybackView *mPlaybackView;
@property (nonatomic, retain) IBOutlet UIToolbar *mToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *mPlayButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *mStopButton;
@property (nonatomic, retain) IBOutlet UISlider* mScrubber;
@property (retain) NSMutableString* swipeHistory;
@property (nonatomic, retain) ATMHud *hud;
@property (nonatomic, strong) NSString *videotitle;
@property (nonatomic) int playCount;

- (IBAction)play:(id)sender;
- (void)playMedia;
- (IBAction)pause:(id)sender;
- (IBAction)lockScreen:(id)sender;
- (void)zoomVideo:(id)sender;
- (void)unlockScreen;

@end
