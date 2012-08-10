//
//  CollectionBrowserCell.h
//  LittleFingers
//
//  Created by Andy Soell on 8/9/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionBrowserCell : UITableViewCell {
    IBOutlet UILabel *title;
    IBOutlet UIImageView *thumbnail;    
}

@property (nonatomic, retain) IBOutlet UILabel *title;
@property (nonatomic, retain) IBOutlet UIImageView *thumbnail;


@end
