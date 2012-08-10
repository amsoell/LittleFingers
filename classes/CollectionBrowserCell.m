//
//  CollectionBrowserCell.m
//  LittleFingers
//
//  Created by Andy Soell on 8/9/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import "CollectionBrowserCell.h"

@implementation CollectionBrowserCell
@synthesize title, thumbnail;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
