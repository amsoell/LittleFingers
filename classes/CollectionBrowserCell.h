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
    IBOutlet UILabel *album;    
    IBOutlet UILabel *duration;    
    IBOutlet UILabel *durationLabel;     
    IBOutlet UIImageView *thumbnail;    
    IBOutlet UIImageView *favoriteToggle;
    AVAssetImageGenerator *generator;    
}

- (void)setDetails:(NSDictionary*)details; 
- (void) generateThumbnailForAsset:(NSDictionary*)asset;
- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size;
- (bool)saveThumb:(UIImage*)image withName:(NSString*)name;
- (UIImage *)roundCornersOfImage:(UIImage *)source roundTop:(BOOL)top roundBottom:(BOOL)bottom;
void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight, BOOL top, BOOL bottom);


@property (nonatomic, retain) IBOutlet UILabel *title;
@property (nonatomic, retain) IBOutlet UILabel *album;
@property (nonatomic, retain) IBOutlet UILabel *duration;
@property (nonatomic, retain) IBOutlet UILabel *durationLabel;
@property (nonatomic, retain) IBOutlet UIImageView *thumbnail;
@property (nonatomic, retain) IBOutlet UIImageView *favoriteToggle;


@end
