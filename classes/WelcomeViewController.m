//
//  WelcomeViewController.m
//  LittleFingers
//
//  Created by Andy Soell on 7/13/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import "WelcomeViewController.h"
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
    UIView *page;
    for (id object in bundle) {
        if ([object isKindOfClass:[UIView class]]) {
            page = (UIView *)object;            
            for (id object in page.subviews) {
                if ([object isKindOfClass:[UILabel class]]) {
                    UILabel *label = object;
                    [label setFont:[UIFont fontWithName:labelFont.fontName size:label.font.pointSize]];
                }
            }
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
