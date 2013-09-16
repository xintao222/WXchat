//
//  GrayPageControl.m
//  WXiphone
//
//  Created by zhou angel on 13-9-12.
//  Copyright (c) 2013年 zhou angel. All rights reserved.
//

#import "GrayPageControl.h"

@implementation GrayPageControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        activeImage = [UIImage imageNamed:@"inactive_page_image"];
        inactiveImage = [UIImage imageNamed:@"active_page_image"];
        [self setCurrentPage:1];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    activeImage = [UIImage imageNamed:@"inactive_page_image"];
    inactiveImage = [UIImage imageNamed:@"active_page_image"];
    [self setCurrentPage:1];
    return self;
}

-(void) updateDots
{
    for (int i = 0; i < [self.subviews count]; i++)
    {
        UIImageView* dot = [self.subviews objectAtIndex:i];
        if (i == self.currentPage) dot.image = activeImage;
        else dot.image = inactiveImage;
    }
}

-(void) setCurrentPage:(NSInteger)page
{
    [super setCurrentPage:page];
    [self updateDots];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
