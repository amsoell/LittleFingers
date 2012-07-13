//
//  WelcomeViewController.h
//  LittleFingers
//
//  Created by Andy Soell on 7/13/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeViewController : UINavigationController {
    UIViewController *welcomeVC;
    NSMutableArray *pages;
    int currentPage;
}

- (IBAction)advancePage:(id)sender;

@property (nonatomic) NSMutableArray *pages;
@property (nonatomic) int currentPage;
@end
