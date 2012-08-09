#import "NGTabBarController.h"
#import "IASKAppSettingsViewController.h"

@interface NGVTabBarController : NGTabBarController <IASKSettingsDelegate, UIScrollViewDelegate> {
    UIButton* settingsGear;
    UIButton* helpButton;    
    IASKAppSettingsViewController *appSettingsViewController;       
    UIPopoverController* popover;    
}

@property (nonatomic) UIButton* settingsGear;
@property (nonatomic) UIButton* helpButton;
@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

@end
