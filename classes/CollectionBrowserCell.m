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
@synthesize duration, durationLabel, favoriteToggle, title, album, thumbnail;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"CollectionBrowserCellBg"]]];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"CollectionBrowserCellBg"]]];
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
    [album setText:[details objectForKey:@"album"]];
    NSMutableString* dur = [[NSMutableString alloc] init];
    if ([details objectForKey:@"duration"]!=nil) {
        NSNumber* hours;
        NSNumber* minutes;
        NSNumber* seconds;
        seconds = [details objectForKey:@"duration"];
        hours   = [NSNumber numberWithInt:seconds.intValue / 3600];
        seconds = [NSNumber numberWithInt:seconds.intValue - (hours.intValue*3600)];
        minutes = [NSNumber numberWithInt:seconds.intValue / 60];
        seconds = [NSNumber numberWithInt:seconds.intValue - (minutes.intValue*60)];        
        
        if (hours.intValue > 0) [dur appendFormat:@"%d hour%@, ", hours.intValue, (hours.intValue==1)?@"":@"s"];
        if (minutes.intValue > 0) [dur appendFormat:@"%d minute%@, ", minutes.intValue, (minutes.intValue==1)?@"":@"s"];        
        [dur appendFormat:@"%d second%@", seconds.intValue, (seconds.intValue==1)?@"":@"s"];        

    } else {
        dur = [NSString stringWithString:@""];
    }
    [duration setText:dur];
    
    [self generateThumbnailForAsset:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [details objectForKey:@"url"], @"url",
                                     [details objectForKey:@"id"], @"id",
                                     nil]];
    [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"CollectionBrowserCellBg"]]];    
}

- (void) generateThumbnailForAsset:(NSDictionary*)asset {
    NSString* imageName = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/thumbnails"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [[asset objectForKey:@"id"] stringValue]]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:imageName]) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageName];
        NSLog(@"thumb pulled from cache: %@", imageName);
        [self.thumbnail setImage:image];
    } else {
        NSLog(@"generating thumb for: %@", [asset objectForKey:@"url"]);
        
        NSURL* vidUrl;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[asset objectForKey:@"url"]]) {
            vidUrl = [NSURL fileURLWithPath:[asset objectForKey:@"url"]];
        } else {
            vidUrl = [NSURL URLWithString:[asset objectForKey:@"url"]];            
        }        
        
        AVAsset *a = [AVAsset assetWithURL:vidUrl];
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

void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight, BOOL top, BOOL bottom)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 0);
    
    if (top) {
        CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 3);
    } else {
        CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 0);
    }
    
    if (bottom) {
        CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 3);
    } else {
        CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 0);
    }
    
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 0);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (UIImage *)roundCornersOfImage:(UIImage *)source roundTop:(BOOL)top roundBottom:(BOOL)bottom {
    int w = source.size.width;
    int h = source.size.height;
    
    int radius = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?4:10;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextBeginPath(context);
    CGRect rect = CGRectMake(0, 0, w, h);
    addRoundedRectToPath(context, rect, radius, radius, top, bottom);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), source.CGImage);
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *ret = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    
    return ret;    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect f = self.accessoryView.frame;
    f.origin.y = 20;
    [self.accessoryView setFrame:f];
    
    int ypos;
    if (album.text.length <= 0) {
        ypos = 46;
    } else {
        ypos = 68;
    }
    
    if (duration.text.length <= 0) {
        [duration setAlpha:0.0];
        [durationLabel setAlpha:0.0];
    } else {
        [duration setAlpha:1.0];
        [durationLabel setAlpha:1.0];
        
        f = duration.frame;
        f.origin.y = ypos;
        [duration setFrame:f];
        
        f = durationLabel.frame;
        f.origin.y = ypos;
        [durationLabel setFrame:f];        
    }
}

@end
