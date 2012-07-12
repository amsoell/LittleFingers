//
//  CollectionBrowser.h
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 7/3/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionBrowser : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    NSDictionary *dataSource;   
    UIViewController *owner;
    IBOutlet UITableView *tv;
    UILabel *intro;
}

- (id)initWithCollection:(NSDictionary *)collection;
@property (nonatomic, strong) IBOutlet UITableView *tv;
@property (nonatomic, strong) UILabel *intro;
@property (nonatomic, strong) NSDictionary *dataSource;
@property (nonatomic, strong) UIViewController *owner;
@property (nonatomic, strong) UINavigationController* videoPlaybackController;

@end
