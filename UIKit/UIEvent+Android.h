//
//  UIEvent+Android.h
//  UIKit
//
//  Created by Chen Yonghui on 2/15/14.
//  Copyright (c) 2014 Shanghai Tinynetwork Inc. All rights reserved.
//


#import "UIEvent.h"
#include <android/input.h>
@class UITouch;

#pragma mark - Private Declarations

@interface UIEvent (Private)
- (id)initWithEventType:(UIEventType)type;
- (void)_setTimestamp:(NSTimeInterval)timestamp;
@end

@interface UIEvent (Android)
- (instancetype)initWithAInputEvent:(AInputEvent *)aEvent;
- (void)_updateTouchesWithEvent:(AInputEvent *)aEvent;
- (UITouch *)_touchForIdentifier:(NSInteger)identifier;
- (void)_updateWithAEvent:(AInputEvent *)aEvent;

- (AInputEvent *)_AInputEvent;
@end
