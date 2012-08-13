//
//  CollectionBrowserCell.m
//  LittleFingers
//
//  Created by Andy Soell on 8/9/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import "CollectionBrowserCell.h"
#import <AVFoundation/AVFoundation.h>

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

- (void)setDetails:(NSDictionary*)details {
    [title setText:[details objectForKey:@"title"]]; 
    [thumbnail setImage:[UIImage imageNamed:@"thumbnailbg"]];         
    
    [self generateThumbnailForAsset:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [details objectForKey:@"url"], @"url",
                                     [details objectForKey:@"id"], @"id",
                                     nil]];
}

- (void) generateThumbnailForAsset:(NSDictionary*)asset {
    NSString* imageName = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/thumbnails"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [[asset objectForKey:@"id"] stringValue]]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:imageName]) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageName];
        NSLog(@"thumb pulled from cache: %@", imageName);
        [self.thumbnail setImage:image];
    } else {
        NSLog(@"generating thumb for: %@", [asset objectForKey:@"url"]);
        AVAsset *a = [AVAsset assetWithURL:[NSURL URLWithString:[asset objectForKey:@"url"]]];
        generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:a];	
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(384.0, 256.0);
        NSValue *imageTimeValue = [NSValue valueWithCMTime:CMTimeMake(a.duration.value/2.0, a.duration.timescale)];	
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{            
            [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:imageTimeValue] completionHandler:
             ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) 
             {	
                 if (result == AVAssetImageGeneratorFailed) {

                 }
                 else {
                     if (image) {
                         UIImage *thumb;
                         if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {    
                             thumb = [self copyImageFromCGImage:image croppedToSize:CGSizeMake(192.0, 128.0)];
                             [self saveThumb:thumb withName:[[asset objectForKey:@"id"] stringValue]];
                             
                             thumb = [self copyImageFromCGImage:image croppedToSize:CGSizeMake(384.0, 256.0)];
                             [self saveThumb:thumb withName:[NSString stringWithFormat:@"%@@2x", [[asset objectForKey:@"id"] stringValue]]];
                         } else {
                             thumb = [self copyImageFromCGImage:image croppedToSize:CGSizeMake(96.0, 64.0)];
                             [self saveThumb:thumb withName:[[asset objectForKey:@"id"] stringValue]];
                             
                             thumb = [self copyImageFromCGImage:image croppedToSize:CGSizeMake(192.0, 128.0)];                             
                             [self saveThumb:thumb withName:[NSString stringWithFormat:@"%@@2x", [[asset objectForKey:@"id"] stringValue]]];
                         }
                         
                         if (thumb != nil) {
                             dispatch_async(dispatch_get_main_queue(), ^{                     
                                 [self.thumbnail setImage:thumb];
                             });
                         }
                     } else {
                     }
                 }
                 
             }];
        });    
    }
}

- (bool)saveThumb:(UIImage*)image withName:(NSString*)name {
    if ((image != nil) && (name != nil)) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/thumbnails"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
        if ([imageData writeToFile:[NSString stringWithFormat:@"%@/%@.png", path, name] atomically:YES]) {
            NSLog(@"Success: %@", name);
            return YES;
        } else {
            NSLog(@"couldn't save: %@", name);
            return NO;
        }
    } else {
        return NO;
    }
}

- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size {
	UIImage *thumbUIImage = nil;
	
	CGRect thumbRect = CGRectMake(0.0, 0.0, CGImageGetWidth(image), CGImageGetHeight(image));
	CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(size, thumbRect);
	cropRect.origin.x = round(cropRect.origin.x);
	cropRect.origin.y = round(cropRect.origin.y);
	cropRect = CGRectIntegral(cropRect);
	CGImageRef croppedThumbImage = CGImageCreateWithImageInRect(image, cropRect);
	thumbUIImage = [[UIImage alloc] initWithCGImage:croppedThumbImage];
	CGImageRelease(croppedThumbImage);
	
	return thumbUIImage;
}

@end
