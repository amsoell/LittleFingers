#import <UIKit/UIKit.h>
#import "AQGridViewCell.h"

@interface GridViewCell : AQGridViewCell
{
    UIImageView * _imageView;
    UILabel * _title;
}

-(void)addBorders;

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, copy) NSString * title;

@end
