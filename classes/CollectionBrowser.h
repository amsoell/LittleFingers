//
//  CollectionBrowser.h
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 7/3/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionBrowser : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    NSDictionary *dataSource;   // Dictionary (category), whose members are arrays (collection) of dictionaries (media item)
    IBOutlet UITableView *tv;
    UIView *intro;
    NSString* emptyText;
}

- (id)initWithCollection:(NSDictionary *)collection;
- (BOOL)hasUnprotectedContent;

@property (nonatomic, strong) IBOutlet UITableView *tv;
@property (nonatomic, strong) UIView *intro;
@property (nonatomic, strong) NSDictionary *dataSource;
@property (nonatomic, strong) UINavigationController* videoPlaybackController;
@property (nonatomic, strong) NSString* emptyText;

@end
