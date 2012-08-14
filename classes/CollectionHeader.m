//
//  CollectionHeader2.m
//  LittleFingers
//
//  Created by Andy Soell on 8/14/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import "CollectionHeader.h"
#import <QuartzCore/QuartzCore.h>

@implementation CollectionHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    switch (UI_USER_INTERFACE_IDIOM()) {
        case UIUserInterfaceIdiomPhone:
            rect.size.width -= 20;
            rect.origin.x += 10;        

            break;
        default:
            switch ([UIApplication sharedApplication].statusBarOrientation) {
                case UIInterfaceOrientationPortrait:
                    rect.size.width -= 80;
                    rect.origin.x += 40;        
                    break;
                default:
                    rect.size.width -= 80;
                    rect.origin.x += 44;        
                    break;
            }
    }

    rect.origin.y += 2;
    
    CGRect b = self.layer.bounds;
    [self.layer setBounds:b];
    [self setBackgroundColor:[UIColor redColor]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self setAutoresizesSubviews:YES];
    
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 0.8;
    self.layer.masksToBounds = NO;    
    
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects: 
                               (id)[UIColor colorWithRed: 0.35 green: 0.62 blue: 0.83 alpha: 1].CGColor, 
                               (id)[UIColor colorWithRed: 0.4 green: 0.4 blue: 0.6 alpha: 1].CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    CGColorRef shadow = [UIColor blackColor].CGColor;
    CGSize shadowOffset = CGSizeMake(0, 1);
    CGFloat shadowBlurRadius = 5;
    
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(10, 10)];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow);
    CGContextSetFillColorWithColor(context, shadow);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(rect.size.width/2.0, rect.origin.y), CGPointMake(rect.size.width/2.0, rect.origin.y+rect.size.height), 0);
    CGContextRestoreGState(context);
    
    /*    
     [[UIColor darkGrayColor] setStroke];
     roundedRectanglePath.lineWidth = 1;
     [roundedRectanglePath stroke];
     */ 
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGRect maskRect = rect;
    maskRect.size.height += 15;
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *roundedPath = 
    [UIBezierPath bezierPathWithRoundedRect:maskRect byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(10, 10)];   
    maskLayer.fillColor = [[UIColor whiteColor] CGColor];
    maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
    maskLayer.path = [roundedPath CGPath];
    
    //Don't add masks to layers already in the hierarchy!
    UIView *superview = [self superview];
    [self removeFromSuperview];
    self.layer.mask = maskLayer;
    [superview addSubview:self];    
    
    [super drawRect:rect];
    
}


@end
