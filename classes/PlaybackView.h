#import <UIKit/UIKit.h>

@class AVPlayer;

@interface PlaybackView : UIView

@property (nonatomic, retain) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
