//
//  WelcomeView.h
//  LittleFingers
//
//  Created by Andy Soell on 8/17/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeView : UIView {
    IBOutlet UILabel *title;
    IBOutlet UILabel *text1;
    IBOutlet UILabel *text2;
}


@property (nonatomic, retain) IBOutlet UILabel *title;
@property (nonatomic, retain) IBOutlet UILabel *text1;
@property (nonatomic, retain) IBOutlet UILabel *text2;

@end
