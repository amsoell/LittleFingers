//
//  GridViewController.m
//  LittleFingers
//
//  Created by Andy Soell on 7/10/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import "GridViewController.h"
#import "AppDelegate.h"
#import "WelcomeViewController.h"

@interface GridViewController ()

@end

@implementation GridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([sharedAppDelegate isFirstLaunch]) {
        NSLog(@"first launch");
        WelcomeViewController *welcomeController = [[WelcomeViewController alloc] initWithNibName:@"Welcome"];
        [welcomeController.navigationBar setTintColor:[UIColor colorWithRed:0.0/255.0f green:85.0f/255.0f blue:20.0f/255.0f alpha:1.0f]];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                    
            [welcomeController setModalPresentationStyle:UIModalPresentationFormSheet];
            [welcomeController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            [welcomeController setModalInPopover:YES];
        }
        
        [self presentModalViewController:welcomeController animated:YES];    
        
    } else if ([sharedAppDelegate isFirstLaunchThisVersion]) {
        
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
