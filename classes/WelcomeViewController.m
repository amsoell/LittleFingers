#import "WelcomeViewController.h"
#import "WelcomeView.h"
#import "AppDelegate.h"

#import <QuartzCore/QuartzCore.h>

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController
@synthesize pages, currentPage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil {
    self = [super init];
    
    welcomeVC = [[UIViewController alloc] init];
    NSString *appName = [sharedAppDelegate longAppName];
    UIFont *displayFont = [UIFont fontWithName:@"HoneyScript-SemiBold" size:30.f];
    CGRect frame = CGRectMake(0, 0, [appName sizeWithFont:displayFont].width , [appName sizeWithFont:displayFont].height);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = displayFont;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
    label.text = appName;
    [label setShadowColor:[UIColor darkGrayColor]];
    [label setShadowOffset:CGSizeMake(0, -0.5)];
    welcomeVC.navigationItem.titleView = label;    
    
  
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:nibNameOrNil owner:self options:nil];
    pages = [[NSMutableArray alloc] init];
    UIFont *labelFont = [UIFont fontWithName:@"SketchRockwell" size:20.0f];    
    WelcomeView *page;
    int i = 0;
    for (id object in bundle) {
        if ([object isKindOfClass:[WelcomeView class]]) {
            i++;
            page = (WelcomeView *)object;            
            for (id object in page.subviews) {
                if ([object isKindOfClass:[UILabel class]]) {
                    UILabel *label = object;
                    [label setFont:[UIFont fontWithName:labelFont.fontName size:label.font.pointSize]];
                }
            }
            
            NSString *title_key = [NSString stringWithFormat:@"WELCOME_%d_TITLE%@", i, (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"_IPAD":@"")];
            NSString *title = NSLocalizedString(title_key, nil);            
            [page.title setText:title];
            
            NSString *text1_key = [NSString stringWithFormat:@"WELCOME_%d_TEXT%@", i, (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"_IPAD":@"")];
            NSString *text1 = NSLocalizedString(text1_key, nil);            
            [page.text1 setText:text1];

            NSString *text2_key = [NSString stringWithFormat:@"WELCOME_%d_TEXT_2%@", i, (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"_IPAD":@"")];
            NSString *text2 = NSLocalizedString(text2_key, nil);            
            [page.text2 setText:text2];

            
            [page setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chalkbg.jpg"]]];
            
            [pages insertObject:page atIndex:page.tag];
        }
    }       
    
    [welcomeVC setView:[pages objectAtIndex:0]]; 
    [self setViewControllers:[NSArray arrayWithObject:welcomeVC]];
     
    
    return self;
}

- (IBAction)navigateNext:(id)sender {
    if ([pages objectAtIndex:(currentPage + 1)]!=nil) {
        [welcomeVC setView:[pages objectAtIndex:(++currentPage)]];
    }
    NSLog(@"advance");
}

- (IBAction)navigateBack:(id)sender {
    if ([pages objectAtIndex:(currentPage - 1)]!=nil) {
        [welcomeVC setView:[pages objectAtIndex:(--currentPage)]];
    }
    NSLog(@"advance");
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (IBAction) dismissSelf:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
