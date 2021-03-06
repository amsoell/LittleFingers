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
    
    self.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite: 0.95 alpha: 1.0];
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

- (void) setImage: (UIImage *) anImage {
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
    frame.origin.x = bounds.size.width/2 - frame.size.width/2 + 10;
    frame.origin.y = bounds.size.height/2 - frame.size.height/2 + 10;
    _imageView.frame = frame;
}

@end
