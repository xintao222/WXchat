//
//  MainView.m
//  WXiphone
//
//  Created by zhou angel on 13-9-11.
//  Copyright (c) 2013年 zhou angel. All rights reserved.
//

#import "MainView.h"
#import "Message.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

#define BEGIN_FLAG @"["
#define END_FLAG @"]"
#define KFacialSizeWidth  18
#define KFacialSizeHeight 18
#define MAX_WIDTH 150

MainView *mainview;
@interface MainView ()

@end

@implementation MainView
@synthesize urlTextField,bgTableView,textContent,sendView;
@synthesize titleString = _titleString;
@synthesize chatArray = _chatArray;
@synthesize messageString = _messageString;
@synthesize phraseString = _phraseString;
@synthesize lastTime = _lastTime;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.urlTextField.delegate=self;
    self.textContent.delegate=self;
    self.bgTableView.delegate=self;
    self.bgTableView.dataSource=self;
    messages = [[NSMutableArray alloc] initWithCapacity:0];
    isConnect=NO;
    isShowKeyBoard=true;
    isShowFaceBoard=false;
    _faceBoard=[[FaceBoard alloc]init];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changeKeyBoard:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
   	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.chatArray = tempArray;
	
    NSMutableString *tempStr = [[NSMutableString alloc] initWithFormat:@""];
    self.messageString = tempStr;
    
	NSDate   *tempDate = [[NSDate alloc] init];
	self.lastTime = tempDate;
    
    textContent.delegate=self;
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
   
    
    [textContent addGestureRecognizer:singleTap];
    singleTap.delegate = self;
    singleTap.cancelsTouchesInView = NO;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
-(void)handleSingleTap:(UITapGestureRecognizer *)sender{
    if(isShowKeyBoard==false)
    {
        isShowKeyBoard=true;
        isShowFaceBoard=false;
        _faceBoard.inputTextField =nil;
        [self.textContent resignFirstResponder];
        self.textContent.inputView=self.urlTextField.inputView;
        [self.textContent becomeFirstResponder];
    }
    if(self.sendView.frame.origin.y==504.0f)
        [self changeViewOrigin:-216.0f];
    if(self.sendView.frame.origin.y==540.0f)
        [self changeViewOrigin:-252.0f];
}
#pragma mark ---关闭键盘----
//轻触背景关闭键盘 error
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(![self.bgTableView isExclusiveTouch])
        [self.bgTableView resignFirstResponder];
}
//添加一个按钮来关闭，但是透明时失败 error
- (IBAction)closeKeyboard:(id)sender {
    [urlTextField resignFirstResponder];
    [textContent resignFirstResponder];
}
//return关闭键盘
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.urlTextField) {
        [textField resignFirstResponder];
    }
    return YES;
}


#pragma mark ----键盘高度变化------

-(void)changeKeyBoard:(NSNotification *)aNotifacation
{
    //获取到键盘frame 变化之前的frame
    NSValue *keyboardBeginBounds=[[aNotifacation userInfo]objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect beginRect=[keyboardBeginBounds CGRectValue];
    NSValue *keyboardEndBounds=[[aNotifacation userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endRect=[keyboardEndBounds CGRectValue];
    CGFloat deltaY=endRect.origin.y-beginRect.origin.y;
    //拿frame变化之后的origin.y-变化之前的origin.y，其差值(带正负号)就是我们self.view的y方向上的增量
    //[self changeViewOrigin:deltaY];
    if(self.sendView.frame.origin.y>300)
        [self changeViewOrigin:deltaY];
    else if(self.sendView.frame.origin.y<300 && deltaY >-200)
        [self changeViewOrigin:deltaY];
    
}
// 变化发送区域，添加动画
-(void) changeViewOrigin:(CGFloat)deltaY{
    sendView.frame=CGRectMake(sendView.frame.origin.x, sendView.frame.origin.y+deltaY, sendView.frame.size.width, sendView.frame.size.height); //end point
    bgTableView.frame=CGRectMake(bgTableView.frame.origin.x, bgTableView.frame.origin.y, bgTableView.frame.size.width, bgTableView.frame.size.height+deltaY);
    CGContextRef context=UIGraphicsGetCurrentContext();
    [UIView beginAnimations:@"myView" context:context];
    sendView.frame=CGRectMake(sendView.frame.origin.x, sendView.frame.origin.y, sendView.frame.size.width, sendView.frame.size.height);  //start point
    bgTableView.frame=CGRectMake(bgTableView.frame.origin.x, bgTableView.frame.origin.y, bgTableView.frame.size.width, bgTableView.frame.size.height);
    [UIView setAnimationDuration:0.2];
    
    [self showLastMessage];
    NSLog(@"SEND VIEW %f",sendView.frame.origin.y);
}







#pragma mark ----sokect-----------------

- (IBAction)TouchConnectServer:(id)sender {
    NSString *serverIp = self.urlTextField.text;
    serverIp=@"127.0.0.1";
    [self CreateConnect:serverIp];

}

-(void)CreateConnect:(NSString*)strAddress
{
    CFSocketContext sockContext = {0, // 结构体的版本，必须为0
        (__bridge void *) self,
        NULL, // 一个定义在上面指针中的retain的回调， 可以为NULL
        NULL,
        NULL};
    _socket = CFSocketCreate(kCFAllocatorDefault, // 为新对象分配内存，可以为nil
                             PF_INET, // 协议族，如果为0或者负数，则默认为PF_INET
                             SOCK_STREAM, // 套接字类型，如果协议族为PF_INET,则它会默认为SOCK_STREAM
                             IPPROTO_TCP, // 套接字协议，如果协议族是PF_INET且协议是0或者负数，它会默认为IPPROTO_TCP
                             kCFSocketConnectCallBack, // 触发回调函数的socket消息类型，具体见Callback Types
                             TCPClientConnectCallBack, // 上面情况下触发的回调函数
                             &sockContext // 一个持有CFSocket结构信息的对象，可以为nil
                             );
    if(_socket != NULL)
    {
        struct sockaddr_in addr4;   // IPV4
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(8888);
        addr4.sin_addr.s_addr = inet_addr([strAddress UTF8String]);  // 把字符串的地址转换为机器可识别的网络地址
        
        // 把sockaddr_in结构体中的地址转换为Data
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
        CFSocketConnectToAddress(_socket, // 连接的socket
                                 address, // CFDataRef类型的包含上面socket的远程地址的对象
                                 -1  // 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
                                 );
        CFRunLoopRef cRunRef = CFRunLoopGetCurrent();    // 获取当前线程的循环
        // 创建一个循环，但并没有真正加如到循环中，需要调用CFRunLoopAddSource
        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
        CFRunLoopAddSource(cRunRef, // 运行循环
                           sourceRef,  // 增加的运行循环源, 它会被retain一次
                           kCFRunLoopCommonModes  // 增加的运行循环源的模式
                           );
        CFRelease(sourceRef);
        NSLog(@"connect ok");
    }
}


// socket回调函数，同客户端
static void TCPClientConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data,void *info)
{
    MainView *client = (__bridge MainView *)info;
    NSString *nowTime=[client DateStringFromDate:[NSDate date]];
    if (data != NULL)
    {
        NSLog(@"socket,服务端连接失败");
        [client addMessage:@"连接失败！" isSelf:YES type:@"text" time:nowTime];
        [client setIsConnect:NO];
    }
    else
    {
        NSLog(@"socket,服务端连接成功");
        [client addMessage:@"连接成功！" isSelf:YES type:@"text" time:nowTime];
        [client setIsConnect:YES];
    }
    [client.bgTableView reloadData];
    [client StartReadThread];
    mainview=client;
}
- (void) setIsConnect:(BOOL) bo{
    isConnect=bo;
}
-(void)StartReadThread
{
    NSThread *InitThread = [[NSThread alloc]initWithTarget:self selector:@selector(InitThreadFunc:) object:self];
    [InitThread start];
}
-(void)InitThreadFunc:(id)sender
{
    while (1) {
        [self readStream];
    }
}
// 读取接收的数据
-(void)readStream
{
    char buffer[1024];
    NSString *str = @"服务器发来数据：";
    recv(CFSocketGetNative(_socket), buffer, sizeof(buffer), 0);
    {
        str = [str stringByAppendingString:[NSString stringWithUTF8String:buffer]];
    }
    NSLog(str);
    //回界面显示信息
    [self performSelectorOnMainThread:@selector(ShowMsg:) withObject:str waitUntilDone:NO];
}
-(void)ShowMsg:(id)sender
{
    NSLog(@"ShowMsg");
    NSString *str = sender;
    NSString *time=[self getNodeValue:@"CreateTime" xmlStr:str];
    [self addMessage:[NSString stringWithFormat:@"服务器：%@",[self getNodeValue:@"Content" xmlStr:str]] isSelf:NO type:@"text" time:[self DateStringFromString:time]];
    [self.bgTableView reloadData];
}




#pragma mark ----发送消息---------------
//确定发送消息按钮


- (IBAction)sendMessage:(id)sender {
    allCellHeight=0;
    [self sendTextMessage];
    [bgTableView reloadData];
    [self showLastMessage];
}
-(void) showLastMessage{
    if(bgTableView.frame.size.height <= allCellHeight)
     [bgTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[messages count] inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

-(void)sendTextMessage
{
    NSDate *nowTime = [NSDate date];
    
    if ([self.chatArray lastObject] == nil) {
		self.lastTime = nowTime;
		[self.chatArray addObject:nowTime];
	}
	// 发送后生成泡泡显示出来
	NSTimeInterval timeInterval = [nowTime timeIntervalSinceDate:self.lastTime];
	if (timeInterval >60) {
		self.lastTime = nowTime;
		[self.chatArray addObject:nowTime];
	}
    
    if(isConnect)//连接后发送消息
    {
        //发送文本消息
        if(![self.textContent.text isEqualToString:@""])
        {
            [self sendText:self.textContent.text];
        }
    }
    else
    {
        NSString *nowTime=[self DateStringFromDate:[NSDate date]];
        [self addMessage:@"连接失败！" isSelf:YES type:@"text" time:nowTime];
    }
    [bgTableView reloadData];
}
- (IBAction)sendMessageByEnter:(UITextView *)textContent
{
    [self sendTextMessage];
}

//获取url参数
- (NSString*)dictionaryFromQuery:(NSString*)query usingEncoding:(NSStringEncoding)encoding name:(NSString*)Name
{
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
    
    NSScanner* scanner = [[NSScanner alloc] initWithString:query];
    while (![scanner isAtEnd]) {
        NSString* pairString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="];
        if (kvPair.count == 2) {
            
            NSString* key = [[kvPair objectAtIndex:0]
                             stringByReplacingPercentEscapesUsingEncoding:encoding];
            if([key isEqual:Name])
            {
                NSString* value = [[kvPair objectAtIndex:1]
                                   stringByReplacingPercentEscapesUsingEncoding:encoding];
                return value;
            }
        }
    }
    return @"无此参数";
}


#pragma mark ------NSTableViewDataSource--------

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat cellHeight=0;
	if ([[self.chatArray objectAtIndex:[indexPath row]] isKindOfClass:[NSDate class]]) {
		cellHeight = 30;
	}else {
		UIView *chatView = [[self.chatArray objectAtIndex:[indexPath row]] objectForKey:@"view"];
		cellHeight = chatView.frame.size.height+10;
	}
    allCellHeight +=cellHeight;
    return cellHeight;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.chatArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    UITableViewCell *cell=nil;
    if ([tableView isEqual:self.bgTableView]){
        static NSString *CellIdentifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell==nil){
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:CellIdentifier];
        }
        if ([[self.chatArray objectAtIndex:[indexPath row]] isKindOfClass:[NSDate class]]) {
            // Set up the cell...
            NSDateFormatter  *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yy-MM-dd HH:mm"];
            NSMutableString *timeString = [NSMutableString stringWithFormat:@"%@",[formatter stringFromDate:[self.chatArray objectAtIndex:[indexPath row]]]];
            cell.textLabel.text=timeString;
            
        }else {
            // Set up the cell...
            NSDictionary *chatInfo = [self.chatArray objectAtIndex:[indexPath row]];
            UIView *chatView = [chatInfo objectForKey:@"view"];
            [cell.contentView addSubview:chatView];
        }
        return cell;
        
    }
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

#pragma mark -
#pragma mark NSTableViewDataSource



//发送文本消息
-(void)sendText:(NSString *)text
{
    NSString * content=[NSString stringWithFormat:@"我：%@",text];
    NSString *nowTime=[self DateStringFromDate:[NSDate date]];
    [self addMessage:content isSelf:YES type:@"text" time:nowTime];
    
    
    [self.bgTableView reloadData];
    
    NSString *source=self.textContent.text;
    for (int i = 0; i<[source length]; i++) {
        //截取字符串中的每一个字符
        NSString *s = [source substringWithRange:NSMakeRange(i, 1)];
        //NSLog(@"string is %@",s);
        if ([s isEqualToString:@"<"]) {
            NSRange range = NSMakeRange(i, 1);
            source =   [source stringByReplacingCharactersInRange:range withString:@"&lt;"];
        }
        if ([s isEqualToString:@"&"]) {
            NSRange range = NSMakeRange(i, 1);
            source =   [source stringByReplacingCharactersInRange:range withString:@"&amp;"];
        }
        if ([s isEqualToString:@"="]) {
            NSRange range = NSMakeRange(i, 1);
            source =   [source stringByReplacingCharactersInRange:range withString:@"＝"];
        }
        
    }
    //NSLog(@"after  is %@",source);
    NSString *textContent=[NSString stringWithFormat:@"<xml><ToUserName>1</ToUserName><FromUserName>2</FromUserName><CreateTime>1348831860</CreateTime><MsgType>text</MsgType><Content>%@</Content><MsgId>1234567890123456</MsgId></xml>",source];
    
    
    NSData *data = [textContent dataUsingEncoding:NSUTF8StringEncoding];
    char *ch=[data bytes];
    send(CFSocketGetNative(_socket), ch, strlen(ch) + 1, 0);
}



-(NSString*)getNodeValue:(NSString*)nodeName xmlStr:(NSString*)xmlStr
{
    NSRange range;
    range=[xmlStr rangeOfString:[NSString stringWithFormat:@"<%@>",nodeName]
           ];
    NSUInteger start=range.location+range.length;
    range=[xmlStr rangeOfString:[NSString stringWithFormat:@"</%@>",nodeName]
           ];
    NSUInteger legth=range.location-start;
    range.location=start;
    range.length=legth;
    NSString* value = [xmlStr substringWithRange:range];
    return value;
}
-(void)addMessage:(NSString *)content isSelf:(BOOL) isSelf type:(NSString*)type time:(NSString*)time
{
    Message *message=[[Message alloc] init];
    message.content=content;
    message.isSelef=isSelf;
    message.type=type;
    message.time=time;
    [messages addObject:message];
    
    UIView *chatView = [self bubbleView:content from:isSelf];
	[self.chatArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:content, @"text", @"self", @"speaker", chatView, @"view", @"type",type,nil]];
    
}
-(NSString*) DateStringFromString:(NSString*) date
{
    NSTimeInterval userTime = [date doubleValue];
    //设定时间格式,这里可以设置成自己需要的格式
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    NSString *iosDate = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:userTime]];
    return iosDate;
    
}
-(NSString*) DateStringFromDate:(NSDate*) date
{
    NSTimeInterval userTime = [date timeIntervalSince1970];
    //设定时间格式,这里可以设置成自己需要的格式
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    NSString *iosDate = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:userTime]];
    return iosDate;
    
}



#pragma mark ------------faceboard-----------
//自定义表情键盘
- (IBAction)addFaceBoard:(id)sender {
    if(isShowKeyBoard==true && isShowFaceBoard==false)
        [self.textContent resignFirstResponder];
    if(isShowFaceBoard==false)
    {
        _faceBoard.inputTextField = self.textContent;
        self.textContent.inputView = _faceBoard;
        [self.textContent becomeFirstResponder];
        isShowKeyBoard=false;
        isShowFaceBoard=true;
    }
    if(self.sendView.frame.origin.y==504.0f)
        [self changeViewOrigin:-216.0f];
    if(self.sendView.frame.origin.y==540.0f)
        [self changeViewOrigin:-252.0f];
}
-(BOOL) textView :(UITextView *) textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *) text {
    if(isShowKeyBoard==false)
    {
        isShowKeyBoard=true;
        isShowFaceBoard=false;
        _faceBoard.inputTextField =nil;
        [self.textContent resignFirstResponder];
        self.textContent.inputView=self.urlTextField.inputView;
        [self.textContent becomeFirstResponder];
    }
    if(self.sendView.frame.origin.y==504.0f)
        [self changeViewOrigin:-216.0f];
    if(self.sendView.frame.origin.y==540.0f)
        [self changeViewOrigin:-252.0f];
    return YES;
}
- (IBAction)textContentTouch:(id)sender {
    if(isShowKeyBoard==false)
    {
        isShowKeyBoard=true;
        isShowFaceBoard=false;
        _faceBoard.inputTextField =nil;
        [self.textContent resignFirstResponder];
        self.textContent.inputView=self.urlTextField.inputView;
        [self.textContent becomeFirstResponder];
    }
    if(self.sendView.frame.origin.y==504.0f)
        [self changeViewOrigin:-216.0f];
    if(self.sendView.frame.origin.y==540.0f)
        [self changeViewOrigin:-252.0f];
}

- (IBAction)urlTextTouch:(id)sender {
    isShowFaceBoard=false;
    isShowKeyBoard=true;
}

/*
 生成泡泡UIView
 */
#pragma mark -----------泡泡UIView-------------------------

- (UIView *)bubbleView:(NSString *)text from:(BOOL)fromSelf{
    UIView *returnView =  [self assembleMessageAtIndex:text from:fromSelf];
    returnView.backgroundColor = [UIColor clearColor];
    UIView *cellView = [[UIView alloc] initWithFrame:CGRectZero];
    cellView.backgroundColor = [UIColor clearColor];
    
	UIImage *bubble = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fromSelf?@"bubbleSelf":@"bubble" ofType:@"png"]];
	UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[bubble stretchableImageWithLeftCapWidth:20 topCapHeight:14]];
    
    if(fromSelf){
        returnView.frame= CGRectMake(12.0f, 15.0f, returnView.frame.size.width, returnView.frame.size.height);
        bubbleImageView.frame = CGRectMake(5.0f, 14.0f, returnView.frame.size.width+30.0f, returnView.frame.size.height+24.0f );
        cellView.frame = CGRectMake(310.0f-bubbleImageView.frame.size.width, 0.0f,bubbleImageView.frame.size.width+50.0f, bubbleImageView.frame.size.height+30.0f);
        
    }
	else{
        
        returnView.frame= CGRectMake(20.0f, 15.0f, returnView.frame.size.width, returnView.frame.size.height);
        bubbleImageView.frame = CGRectMake(5.0f, 14.0f, returnView.frame.size.width+35.0f, returnView.frame.size.height+24.0f);
		cellView.frame = CGRectMake(0.0f, 0.0f, bubbleImageView.frame.size.width+30.0f,bubbleImageView.frame.size.height+30.0f);
        
    }
    [cellView addSubview:bubbleImageView];
    [cellView addSubview:returnView];
	return cellView;
}
//图文混排

-(void)getImageRange:(NSString*)message : (NSMutableArray*)array {
    NSRange range=[message rangeOfString: BEGIN_FLAG];
    NSRange range1=[message rangeOfString: END_FLAG];
    //判断当前字符串是否还有表情的标志。
    if (range.length>0 && range1.length>0) {
        if (range.location > 0) {
            [array addObject:[message substringToIndex:range.location]];
            [array addObject:[message substringWithRange:NSMakeRange(range.location, range1.location+1-range.location)]];
            NSString *str=[message substringFromIndex:range1.location+1];
            [self getImageRange:str :array];
        }else {
            NSString *nextstr=[message substringWithRange:NSMakeRange(range.location, range1.location+1-range.location)];
            //排除文字是“”的
            if (![nextstr isEqualToString:@""]) {
                [array addObject:nextstr];
                NSString *str=[message substringFromIndex:range1.location+1];
                [self getImageRange:str :array];
            }else {
                return;
            }
        }
        
    } else if (message != nil) {
        [array addObject:message];
    }
}

-(UIView *)assembleMessageAtIndex : (NSString *) message from:(BOOL)fromself
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [self getImageRange:message :array];
    UIView *returnView = [[UIView alloc] initWithFrame:CGRectZero];
    NSArray *data = array;
    UIFont *fon = [UIFont systemFontOfSize:13.0f];
    CGFloat upX = 0;
    CGFloat upY = 0;
    CGFloat X = 0;
    CGFloat Y = 0;
    if (data) {
        for (int i=0;i < [data count];i++) {
            NSString *str=[data objectAtIndex:i];
            NSLog(@"str--->%@",str);
            if ([str hasPrefix: BEGIN_FLAG] && [str hasSuffix: END_FLAG])
            {
                if (upX >= MAX_WIDTH)
                {
                    upY = upY + KFacialSizeHeight;
                    upX = 0;
                    X = 150;
                    Y = upY;
                }
                // NSLog(@"str(image)---->%@",str);
                NSString *imageName=@"001";
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
                if ([[languages objectAtIndex:0] hasPrefix:@"zh"]) {
                    _faceMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"faceMap_ch" ofType:@"plist"]];
                } else {
                    _faceMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"faceMap_en" ofType:@"plist"]];
                }
                for(int i=0;i<[_faceMap count];i++)
                {
                    
                    NSString *value=[[_faceMap allValues] objectAtIndex:i];
                    BOOL result = [str isEqualToString:value];
                    if(result==true)
                        imageName=[[_faceMap allKeys] objectAtIndex:i];
                }
                // NSLog(@"str(key)---->%@",imageName);
                
                UIImageView *img=[[UIImageView alloc]initWithImage:[UIImage imageNamed:imageName]];
                img.frame = CGRectMake(upX, upY, KFacialSizeWidth, KFacialSizeHeight);
                [returnView addSubview:img];
                
                upX=KFacialSizeWidth+upX;
                if (X<150) X = upX;
                
                
            } else {
                for (int j = 0; j < [str length]; j++) {
                    NSString *temp = [str substringWithRange:NSMakeRange(j, 1)];
                    if (upX >= MAX_WIDTH)
                    {
                        upY = upY + KFacialSizeHeight;
                        upX = 0;
                        X = 150;
                        Y =upY;
                    }
                    CGSize size=[temp sizeWithFont:fon constrainedToSize:CGSizeMake(150, 40)];
                    UILabel *la = [[UILabel alloc] initWithFrame:CGRectMake(upX,upY,size.width,size.height)];
                    la.font = fon;
                    la.text = temp;
                    la.backgroundColor = [UIColor clearColor];
                    [returnView addSubview:la];
                    
                    upX=upX+size.width;
                    if (X<150) {
                        X = upX;
                    }
                }
            }
        }
    }
    returnView.frame = CGRectMake(15.0f,1.0f, X, Y); //@ 需要将该view的尺寸记下，方便以后使用
    NSLog(@"%.1f %.1f", X, Y);
    return returnView;
}

@end
