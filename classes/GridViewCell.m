/*
 * ImageDemoFilledCell.m
 * Classes
 * 
 * Created by Jim Dovey on 18/4/2010.
 * 
 * Copyright (c) 2010 Jim Dovey
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "GridViewCell.h"
#import <QuartzCore/CALayer.h>

@implementation GridViewCell

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) aReuseIdentifier
{
    self = [super initWithFrame: frame reuseIdentifier: aReuseIdentifier];
    if ( self == nil )
        return ( nil );
    
    _imageView = [[UIImageView alloc] initWithFrame: CGRectZero];
    _title = [[UILabel alloc] initWithFrame: CGRectZero];
    _title.highlightedTextColor = [UIColor whiteColor];
    _title.font = [UIFont boldSystemFontOfSize: 12.0];
    _title.adjustsFontSizeToFitWidth = YES;
    _title.minimumFontSize = 10.0;
    
    self.backgroundColor = [UIColor colorWithWhite: 0.95 alpha: 1.0];
    self.contentView.backgroundColor = self.backgroundColor;
    _imageView.backgroundColor = self.backgroundColor;
    _title.backgroundColor = self.backgroundColor;
    
    [self.contentView addSubview: _imageView];
    [self.contentView addSubview: _title];
    
    return ( self );
}


- (UIImage *) image
{
    return ( _imageView.image );
}

- (void) setImage: (UIImage *) anImage
{
/*    
    UIGraphicsBeginImageContext(anImage.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    UIColor *color = [UIColor blueColor];
    [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, anImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeOverlay);// kCGBlendModeMultiply);// kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, anImage.size.width, anImage.size.height);
    CGContextDrawImage(context, rect, anImage.CGImage);
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, anImage.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();    
    
    anImage = coloredImg;
*/    
    _imageView.image = anImage;
    [self setNeedsLayout];
}

- (void) addBorders {
    UIColor *darkColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
    UIColor *lightColor = [UIColor colorWithRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0];
    
    UIView *rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width-1, 0, 1.0f, self.bounds.size.height)];
    [rightBorder setBackgroundColor:lightColor];
    
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-1, self.bounds.size.width, 1.0f)];
    [bottomBorder setBackgroundColor:lightColor];
    
    UIView *leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.0f, self.bounds.size.height)];
    [leftBorder setBackgroundColor:darkColor];
    
    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1.0f)];
    [topBorder setBackgroundColor:darkColor];    
    
    [self addSubview:rightBorder];
    [self addSubview:bottomBorder];
    [self addSubview:leftBorder];
    [self addSubview:topBorder];    
}

- (NSString *) title
{
    return ( _title.text );
}

- (void) setTitle: (NSString *) title
{
    _title.text = title;
    [self setNeedsLayout];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGSize imageSize = _imageView.image.size;
    CGRect bounds = CGRectInset( self.contentView.bounds, 10.0, 10.0 );
    
    [_title sizeToFit];
    [_title setFont:[UIFont fontWithName:@"GillSans-Light" size:14.0f]];
    [_title setTextColor:[UIColor blackColor]];
    
    [_title setShadowColor:[UIColor darkGrayColor]];
    [_title setShadowOffset:CGSizeMake(0, -0.5)];
    
    
    CGRect frame = _title.frame;
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    frame.origin.y = CGRectGetMaxY(bounds) - frame.size.height;
    frame.origin.x = bounds.size.width/2 - frame.size.width/2 + 10;
    _title.frame = frame;
    
    // adjust the frame down for the image layout calculation
    bounds.size.height = frame.origin.y - bounds.origin.y;
    
    [_imageView sizeToFit];
    [_imageView setAlpha:0.6];
    frame = _imageView.frame;
    frame.size.width = floorf(imageSize.width);
    frame.size.height = floorf(imageSize.height);
    NSLog(@"%f x %f inside %f x %f", frame.size.width, frame.size.height, bounds.size.width, bounds.size.height);
    frame.origin.x = bounds.size.width/2 - frame.size.width/2 + 10;
    frame.origin.y = bounds.size.height/2 - frame.size.height/2 + 10;
    _imageView.frame = frame;
}

@end
