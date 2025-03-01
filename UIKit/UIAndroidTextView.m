//
//  UIAndroidTextView.m
//  UIKit
//
//  Created by Chen Yonghui on 4/5/15.
//  Copyright (c) 2015 Shanghai Tinynetwork Inc. All rights reserved.
//

#import "UIAndroidTextView.h"
#import <GLES2/gl2.h>
#import <TNJavaHelper/TNJavaHelper.h>
#import "UIEvent+Android.h"
#import "TNJavaBridgeProxy+UIJniObj.h"

typedef BOOL(^EAGLTextureUpdateCallback)(CATransform3D *t);

@interface CAMovieLayer : CALayer

@property (nonatomic, copy) EAGLTextureUpdateCallback updateCallback;
- (BOOL)updateTextureIfNeeds:(CATransform3D *)t;
- (int)textureID;

@end

@implementation UIAndroidTextView
{
    jobject _jTextView;
    jclass _jTextViewClass;
    JNIEnv *_env;
    
    BOOL _singleLine;
}
@synthesize textColor = _textColor;
@synthesize textAlignment = _textAlignment;
@synthesize font = _font;
@synthesize editable = _editable;

+ (Class)layerClass
{
    return [CAMovieLayer class];
}

- (void)destory
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"onDestory","()V");
    if (mid == NULL) {
        NSLog(@"method not found: onDestory()");
        return;
    }
    NSLog(@"env:%p mid:%p, class:%p obj:%p",env,mid,_jTextViewClass,_jTextView);
    (*env)->CallVoidMethod(env,_jTextView,mid);
    
    (*env)->DeleteGlobalRef(env,_jTextViewClass);
    (*env)->DeleteGlobalRef(env,_jTextView);
}

- (void)dealloc
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    ((CAMovieLayer *)self.layer).updateCallback = nil;
    [self destory];
}

- (instancetype) initWithFrame:(CGRect)frame singleLine:(BOOL)singleLine
{
    self = [super initWithFrame:frame];
    if (self) {
        _singleLine = singleLine;
        CAMovieLayer *layer = self.layer;
        __weak typeof(self) weakSelf = self;
        layer.updateCallback = ^(CATransform3D *t) {
            BOOL result = [weakSelf updaeTextureIfNeeds:t];
            return result;
        };
        [layer displayIfNeeded];
        
        GLuint tex = [layer textureID];
        [self createJavaTextView:tex];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame singleLine:NO];
}

- (void)setTextWatcherListener:(TNJavaBridgeProxy *)textWatcherListener
{
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,
                                        "addTextChangedListener","(Landroid/text/TextWatcher;)V");
    
    if (mid == NULL) {
        NSLog(@"method id not found:%@",@"addTextChangedListener(Landroid/text/TextWatcher;)V");
        return;
    }
    (*env)->CallVoidMethod(env, _jTextView, mid, textWatcherListener.jProxiedInstance);
}

- (void)setOnFocusChangeListener:(TNJavaBridgeProxy *)focusChangeListener
{
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,
                                        "setOnFocusChangeListener","(Landroid/view/View$OnFocusChangeListener;)V");
    
    if (mid == NULL) {
        NSLog(@"method id not found:%@",@"setOnFocusChangeListener(OnFocusChangeListener)V");
        return;
    }
    (*env)->CallVoidMethod(env, _jTextView, mid, focusChangeListener.jProxiedInstance);
}

- (BOOL)updaeTextureIfNeeds:(CATransform3D *)transform
{
    //    NSLog(@"%s",__PRETTY_FUNCTION__);
    static JNIEnv *env = NULL;
    if (env == NULL) {
        env = [[TNJavaHelper sharedHelper] env];
    }
    
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"updateTextureIfNeeds","([F)I");
    if (mid == NULL) {
        NSLog(@"method id not found:%@",@"updateTextureIfNeeds ([F)I");
        return NO;
    }
    
    jfloatArray jMatrix = (*env)->NewFloatArray(env,16);
    
    jint result = (*env)->CallIntMethod(env, _jTextView, mid,jMatrix);
    
    //convert java matrix to CATransform3D
    jfloat *arr = (*env)->GetFloatArrayElements(env,jMatrix,NULL);
    CATransform3D t = CATransform3DIdentity;
    if (arr != NULL) {
        CATransform3D matrix = {
            arr[0],arr[1],arr[2],arr[3],
            arr[4],arr[5],arr[6],arr[7],
            arr[8],arr[9],arr[10],arr[11],
            arr[12],arr[13],arr[14],arr[15]};
        t = matrix;
    }
    
    (*env)->ReleaseFloatArrayElements(env,jMatrix,arr,0);
    (*env)->DeleteLocalRef(env,jMatrix);
    
    *transform = t;
    return result;
}

- (void)createJavaTextView:(int)texID
{
    NSString *className = _singleLine? @"org.tiny4.CocoaActivity.GLSingleLineTextViewRender":
                                       @"org.tiny4.CocoaActivity.GLTextViewRender";
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jclass class = [[TNJavaHelper sharedHelper] findCustomClass:className];
    
    if (class == NULL) {
        NSLog(@"class not found: %@", className);
        return;
    }
    
    jmethodID mid = (*env)->GetMethodID(env,class,"<init>","(Landroid/content/Context;III)V");
    if (mid == NULL) {
        NSLog(@"method id not found:%@",@"init  (Landroid/content/Context;III)V");
        return;
    }
    
    jclass clazz = [[TNJavaHelper sharedHelper] clazz];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    jint width = self.bounds.size.width * scale;
    jint height = self.bounds.size.height * scale;
    NSLog(@"size:%@ scale:%.2f,w:%dh:%d",NSStringFromCGSize(self.bounds.size),scale, width,height);
    jobject object = (*env)->NewObject(env,class,mid,clazz,texID,width,height);
    
    if (object == NULL) {
        NSLog(@"create object failed");
        return;
    }
    
    _jTextView = (*env)->NewGlobalRef(env,object);
    _jTextViewClass = (*env)->NewGlobalRef(env,class);
    
    (*env)->DeleteLocalRef(env,class);
    (*env)->DeleteLocalRef(env,object);
    
    NSThread *thread = [NSThread currentThread];
    NSLog(@"thread:%p",thread);
    NSLog(@"env:%p mid:%p, class:%p obj:%p",env,mid,_jTextViewClass,_jTextView);
}

#pragma mark -
- (NSString *)text
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"getTextString","()Ljava/lang/String;");
    if (mid == NULL) {
        NSLog(@"method id not found:getTextString()");
        return nil;
    }

    jstring *c = (*env)->CallObjectMethod(env,_jTextView,mid);

    const char *utf8 = (*env)->GetStringUTFChars(env,c,NULL);
    NSString *text = [NSString stringWithUTF8String:utf8];
    
    
    (*env)->ReleaseStringUTFChars(env,c,utf8);
    (*env)->DeleteLocalRef(env,c);
    
    return text;
}

- (void)setText:(NSString *)text
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jstring jData = (*env)->NewStringUTF(env,[text UTF8String]);
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setText","(Ljava/lang/CharSequence;)V");
    if (mid == NULL) {
        NSLog(@"method id not found:setText()");
        return;
    }
    
    (*env)->CallVoidMethod(env,_jTextView,mid,jData);
    (*env)->DeleteLocalRef(env,jData);

}

- (void)setTextColor:(UIColor *)textColor
{
    NSLog(@"%s",__PRETTY_FUNCTION__);

    _textColor = textColor;
    
    CGFloat r,g,b,a;
    [textColor getRed:&r green:&g blue:&b alpha:&a];
    jint red = r * 255.0;
    jint green = g * 255.0;
    jint blue = b * 255.0;
    jint alpha = a * 255.0;
    NSLog(@"color: r:%.2f g:%.2f b:%.2f a:%.2f",r,g,b,a);
    NSLog(@"color: r:%d g:%d b:%d a:%d",red,green,blue,alpha);
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setTextColor","(IIII)V");
    if (mid == NULL) {
        NSLog(@"method id not found:setTextColor()");
        return;
    }
    
    (*env)->CallVoidMethod(env,_jTextView,mid,alpha,red,green,blue);

    
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
    if (_secureTextEntry == secureTextEntry) {
        return;
    }
    _secureTextEntry = secureTextEntry;
    
    if (_jTextView && _jTextViewClass) {
        JNIEnv *env = [[TNJavaHelper sharedHelper] env];
        
        jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setSecureTextEntry","(Z)V");
        if (mid == NULL) {
            NSLog(@"can't get method setSecureTextEntry()");
        }
        (*env)->CallVoidMethod(env,_jTextView,mid,secureTextEntry? JNI_TRUE: JNI_FALSE);
    }
}

- (UIColor *)textColor
{
    return _textColor;
}

- (void)updateJavaSize:(CGSize)size
{
    if (_jTextView && _jTextViewClass) {
        JNIEnv *env = [[TNJavaHelper sharedHelper] env];
        
        jint width = size.width;
        jint height = size.height;
        
        jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setSize","(II)V");
        if (mid == NULL) {
            NSLog(@"can't get method setSize()");
        }
        (*env)->CallVoidMethod(env,_jTextView,mid,width,height);
    }
}
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self updateJavaSize:frame.size];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    [self updateJavaSize:bounds.size];
}

#define GRAVITY_TOP 48
#define GRAVITY_BOTTOM 80
#define GRAVITY_LEFT 3
#define GRAVITY_RIGHT 5
#define GRAVITY_CENTER_VERTICAL 16
#define GRAVITY_FILL_VERTICAL 112
#define GRAVITY_CENTER_HORIZONTAL 1
#define GRAVITY_FILL_HORIZONTAL 7
#define GRAVITY_CENTER 17
#define GRAVITY_FILL 119

#define TEXT_ALIGNMENT_INHERIT 0
#define TEXT_ALIGNMENT_GRAVITY 1
#define TEXT_ALIGNMENT_TEXT_START 2
#define TEXT_ALIGNMENT_TEXT_END 3
#define TEXT_ALIGNMENT_CENTER 4
#define TEXT_ALIGNMENT_VIEW_START 5
#define TEXT_ALIGNMENT_VIEW_END 6

- (void)setTextAlignment:(UITextAlignment)textAlignment
{
    NSLog(@"%s",__PRETTY_FUNCTION__);

    _textAlignment = textAlignment;
    
    
    jint aAlignment = 2;
    jint gravity = GRAVITY_LEFT;
    switch (textAlignment) {
        case UITextAlignmentLeft:
            aAlignment = TEXT_ALIGNMENT_TEXT_START;
            gravity = GRAVITY_LEFT;
            break;
        case UITextAlignmentCenter:
            aAlignment = TEXT_ALIGNMENT_CENTER;
            gravity = GRAVITY_CENTER;
            break;
        case UITextAlignmentRight:
            aAlignment = TEXT_ALIGNMENT_TEXT_END;
            gravity = GRAVITY_RIGHT;

            break;
            
        default:
            break;
    }
    
    [self setGravity:gravity];
    return;
    
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setTextAlignment","(I)V");
    if (mid == NULL) {
        NSLog(@"method id not found: setTextAlignment()");
        return;
    }
    
    (*env)->CallVoidMethod(env,_jTextView,mid,aAlignment);
}

- (void)setGravity:(int)gravity
{
    
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setGravity","(I)V");
    if (mid == NULL) {
        NSLog(@"method id not found: setGravity()");
        return;
    }
    
    (*env)->CallVoidMethod(env,_jTextView,mid,gravity);

}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = [placeholder copy];
    
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setHint","(Ljava/lang/CharSequence;)V");
    if (mid == NULL) {
        NSLog(@"method id not found: setHint()");
        return;
    }
    
    jstring hint = (*env)->NewStringUTF(env,[placeholder UTF8String]);
    (*env)->CallVoidMethod(env,_jTextView,mid,hint);
    (*env)->DeleteLocalRef(env,hint);

}

- (UITextAlignment)textAlignment
{
    return _textAlignment;
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    
    NSString *fontName = [font fontName];
    CGFloat fontSize = 12;//font.xHeight;
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"setFont","(Ljava/lang/String;I)V");
    if (mid == NULL) {
        NSLog(@"method id not found: setFont()");
        return;
    }
    
    jstring jstr = (*env)->NewStringUTF(env,fontName.UTF8String);
    jint jfs = fontSize;
    NSLog(@"set fontName:%@ size:%d",fontName,jfs);
    (*env)->CallVoidMethod(env,_jTextView,mid,jstr,jfs);
    
    (*env)->DeleteLocalRef(env,jstr);
}

- (UIFont *)font
{
    return _font;
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
}

- (BOOL)isEditable
{
    return _editable;
}

- (void)setSelectedRange:(NSRange)selectedRange
{
    
}

- (NSRange)selectedRange
{
    return NSMakeRange(NSNotFound, 0);
}

- (void)setContentOffset:(CGPoint)theOffset
{
    
}

- (void)scrollRangeToVisible:(NSRange)range
{
    
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return YES;
}

- (void)showKeyBoard
{
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"showKeyBoard","()V");
    (*env)->CallVoidMethod(env,_jTextView,mid);
}

- (void)closeKeyBoard
{
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"closeKeyBoard","()V");
    (*env)->CallVoidMethod(env,_jTextView,mid);
}

#pragma mark - Event forward
- (void)simulateTouches:(NSSet *)touches event:(UIEvent *)event
{
    AInputEvent *aEvent = [event _AInputEvent];
    JNIEnv *env = [[TNJavaHelper sharedHelper] env];
    
    UITouch *touch = [touches anyObject];
    
    int64_t downTime = AMotionEvent_getDownTime(aEvent)/1000000;
    int64_t eventTime = AMotionEvent_getEventTime(aEvent)/1000000;
    
    int action = AMotionEvent_getAction(aEvent);
    int32_t trueAction = action & AMOTION_EVENT_ACTION_MASK;
    
    CGPoint location = [touch locationInView:self];
    //    NSLog(@"touch on web:%@ action:%d trueAction:%d",NSStringFromCGPoint(location),action,trueAction);
    //    NSLog(@"eventTime:%lld downTime:%lld",eventTime,downTime);
    
    jlong x = (jlong)location.x;
    jlong y = (jlong)location.y;
    jint jaction = action;
    jlong jdownTime = downTime;
    jlong jeventTime = eventTime;
    jint jtrueAction = trueAction;
    
    
    //public boolean dispatchTouchEvent(android.view.MotionEvent ev)
    jmethodID mid = (*env)->GetMethodID(env,_jTextViewClass,"simulateTouch","(JJIJJ)V");
    if (mid == NULL) {
        NSLog(@"mithod id simulateTouch not found");
    }
    (*env)->CallVoidMethod(env,_jTextView,mid,jeventTime,jdownTime,jtrueAction,x,y);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self simulateTouches:touches event:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self simulateTouches:touches event:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self simulateTouches:touches event:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self simulateTouches:touches event:event];
}

@end
