//
//  UIScreenPrivate.h
//  UIKit
//
//  Created by Chen Yonghui on 12/7/13.
//  Copyright (c) 2013 Shanghai Tinynetwork Inc. All rights reserved.
//

#import <UIKit/UIScreen.h>
#include <android/native_window.h>
#import "android_native_app_glue.h"

@class CALayer;
@class UIEvent;
@class UIWindow;

@interface UIScreen ()
- (void)_setScale:(CGFloat)scale;
- (void)_setPixelBounds:(CGRect)bounds;

- (UIView *)_hitTest:(CGPoint)clickPoint event:(UIEvent *)theEvent;
- (CALayer *)_pixelLayer;
- (CALayer *)_windowLayer;
- (void)_setLandscaped:(BOOL)landscaped;

typedef NS_ENUM(NSInteger, UIScreenFitMode) {
    UIScreenFitModeCenter,
    UIScreenFitModeScaleAspectFit,
};

- (void)_setScreenBounds:(CGRect)bounds fitMode:(UIScreenFitMode)mode;

@end

