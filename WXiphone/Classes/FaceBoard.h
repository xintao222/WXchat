//
//  FaceBoard.h
//  WXiphone
//
//  Created by zhou angel on 13-9-12.
//  Copyright (c) 2013年 zhou angel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceButton.h"
#import "GrayPageControl.h"

@interface FaceBoard : UIView<UIScrollViewDelegate>{
    UIScrollView *faceView;
    GrayPageControl *facePageControl;
    NSDictionary *_faceMap;
}
@property (nonatomic, retain) UITextField *inputTextField;
@property (nonatomic, retain) UITextView *inputTextView;

@end
