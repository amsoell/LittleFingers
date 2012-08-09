#import <UIKit/UIKit.h>

@interface WelcomeViewController : UINavigationController {
    UIViewController *welcomeVC;
    NSMutableArray *pages;
    int currentPage;
}
- (id)initWithNibName:(NSString *)nibNameOrNil;
- (IBAction)navigateNext:(id)sender;
- (IBAction)navigateBack:(id)sender;
- (IBAction)dismissSelf:(id)sender;

@property (nonatomic) NSMutableArray *pages;
@property (nonatomic) int currentPage;
@end
