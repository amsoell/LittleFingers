//
//  NGTestTabBarController.h
//  NGVerticalTabBarControllerDemo
//
//  Created by Tretter Matthias on 24.04.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGTabBarController.h"
#import "IASKAppSettingsViewController.h"

@interface NGVTabBarController : NGTabBarController <IASKSettingsDelegate> {
    UIButton* settingsGear;
    UIButton* helpButton;    
    IASKAppSettingsViewController *appSettingsViewController;       
    UIPopoverController* popover;    
}

@property (nonatomic) UIButton* settingsGear;
@property (nonatomic) UIButton* helpButton;
@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

@end
