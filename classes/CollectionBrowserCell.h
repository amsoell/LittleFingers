//
//  CollectionBrowserCell.h
//  LittleFingers
//
//  Created by Andy Soell on 8/9/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVAssetImageGenerator;
@interface CollectionBrowserCell : UITableViewCell {
    IBOutlet UILabel *title;
    IBOutlet UIImageView *thumbnail;    
    AVAssetImageGenerator *generator;    
}

- (void)setDetails:(NSDictionary*)details; 
- (void) generateThumbnailForAsset:(NSDictionary*)asset;
- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size;
- (bool)saveThumb:(UIImage*)image withName:(NSString*)name;


@property (nonatomic, retain) IBOutlet UILabel *title;
@property (nonatomic, retain) IBOutlet UIImageView *thumbnail;


@end
