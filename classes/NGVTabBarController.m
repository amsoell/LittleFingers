//
//  NGVTabBarController.m
//  NGVerticalTabBarControllerDemo
//
//  Created by Tretter Matthias on 24.04.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGVTabBarController.h"
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"

@interface NGVTabBarController ()

- (void)setupForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end

@implementation NGVTabBarController
@synthesize settingsGear;
@synthesize appSettingsViewController;

- (id)initWithDelegate:(id<NGTabBarControllerDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        self.animation = NGTabBarControllerAnimationMoveAndScale;
        self.tabBar.tintColor = [UIColor colorWithRed:143.f/255.f green:139.f/255.f blue:47.f/255.f alpha:1.f];
        self.tabBar.itemPadding = 10.f;
        [self setupForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
       
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    settingsGear = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsGear setImage:[UIImage imageNamed:@"gear"] forState:UIControlStateNormal];
    [settingsGear addTarget:self action:@selector(displaySettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:settingsGear];
}

- (void) displaySettings:(UIButton*)sender {
    // Set up the settings view
    appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
    appSettingsViewController.delegate = self;
    appSettingsViewController.showDoneButton = NO;
    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:appSettingsViewController];
    
    // Set up the popover
    CGRect buttonFrame = CGRectMake(sender.frame.origin.x+30 , sender.frame.origin.y, sender.frame.size.width, sender.frame.size.height);
    popover = [[UIPopoverController alloc] initWithContentViewController:aNavController];
    
    // Put the settings view in the popover
    [popover presentPopoverFromRect:buttonFrame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    
} 

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
		appSettingsViewController.delegate = self;
	}
	return appSettingsViewController;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    float x = 37;
    float y = (toInterfaceOrientation==UIInterfaceOrientationPortrait || toInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown)?910:680;
    NSLog(@"moving to %fx%f", x, y);
    [settingsGear setFrame:CGRectMake(x, y, 26, 26)];
    
    [self setupForInterfaceOrientation:toInterfaceOrientation];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setupForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation; {

    self.tabBarPosition = NGTabBarPositionLeft;
    self.tabBar.drawItemHighlight = YES;
    self.tabBar.drawGloss = YES;
    self.tabBar.layoutStrategy = NGTabBarLayoutStrategyStrungTogether;

}

- (void)didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
    NSLog(@"index %@", index);
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    //    [self dismissModalViewControllerAnimated:YES];
	
	// your code here to reconfigure the app for changed settings
}

// optional delegate method for handling mail sending result
- (void)settingsViewController:(id<IASKViewController>)settingsViewController mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if ( error != nil ) {
        // handle error here
    }
    
    if ( result == MFMailComposeResultSent ) {
        // your code here to handle this result
    }
    else if ( result == MFMailComposeResultCancelled ) {
        // ...
    }
    else if ( result == MFMailComposeResultSaved ) {
        // ...
    }
    else if ( result == MFMailComposeResultFailed ) {
        // ...
    }
}
- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewContoller 
                        tableView:(UITableView *)tableView 
        heightForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewContoller.settingsReader keyForSection:section];
	if ([key isEqualToString:@"IASKLogo"]) {
		return [UIImage imageNamed:@"Icon.png"].size.height + 25;
	} else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
		return 55.f;    
    }
	return 0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewContoller 
                         tableView:(UITableView *)tableView 
           viewForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewContoller.settingsReader keyForSection:section];
	if ([key isEqualToString:@"IASKLogo"]) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon.png"]];
		imageView.contentMode = UIViewContentModeCenter;
		return imageView;
	} else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor redColor];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.numberOfLines = 0;
        label.font = [UIFont boldSystemFontOfSize:16.f];
        
        //figure out the title from settingsbundle
        label.text = [settingsViewContoller.settingsReader titleForSection:section];
        
        return label;
    }
	return nil;
}



@end
