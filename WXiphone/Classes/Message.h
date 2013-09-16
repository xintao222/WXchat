//
//  Message.h
//  WXiphone
//
//  Created by zhou angel on 13-9-11.
//  Copyright (c) 2013年 zhou angel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *type;
@property (nonatomic) BOOL isSelef;
@property (nonatomic, copy) NSString *time;

@end
