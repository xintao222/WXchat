//
//  MainView.h
//  WXiphone
//
//  Created by zhou angel on 13-9-11.
//  Copyright (c) 2013年 zhou angel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceBoard.h"

@interface MainView : UIViewController<UITableViewDataSource,UITableViewDelegate,NSXMLParserDelegate,UITextFieldDelegate,UITextViewDelegate,UIGestureRecognizerDelegate>
{NSMutableArray * messages;
    NSString * msgType;
    NSString *currentNodeName;
    BOOL isConnect;
    bool isShowKeyBoard;
    bool isShowFaceBoard;
    CGFloat allCellHeight;
    FaceBoard *_faceBoard;
    NSDictionary *_faceMap;
    NSString                   *_titleString;
	NSMutableString            *_messageString;
	NSString                   *_phraseString;
	NSMutableArray		       *messageviews;
	NSMutableArray		       *_chatArray;
	
	UITableView                *_chatTableView;
	UITextField                *_messageTextField;
	BOOL                       _isFromNewSMS;
	NSDate                     *_lastTime;
}
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UITableView *bgTableView;
@property (weak, nonatomic) IBOutlet UITextField *textContent;
@property (weak, nonatomic) IBOutlet UIView *sendView;


@property (weak, nonatomic) IBOutlet UITextView *inputtext;
@property (nonatomic, retain) NSString               *phraseString;
@property (nonatomic, retain) NSString               *titleString;
@property (nonatomic, retain) NSMutableString        *messageString;
@property (nonatomic, retain) NSMutableArray		 *chatArray;

@property (nonatomic, retain) NSDate                 *lastTime;



- (IBAction)sendMessage:(id)sender;
- (IBAction)closeKeyboard:(id)sender;
- (IBAction)setUrl:(id)sender;
- (IBAction)addFaceBoard:(id)sender;
- (IBAction)textContentTouch:(id)sender;
- (IBAction)urlTextTouch:(id)sender;

@end
