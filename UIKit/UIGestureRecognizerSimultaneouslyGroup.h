//
//  UIGestureRecognizerSimultaneouslyGroup.h
//  UIKit
//
//  Created by TaoZeyu on 15/9/9.
//  Copyright (c) 2015年 Shanghai Tinynetwork Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIView;
@class UIGestureRecognizer;

@interface UIGestureRecognizerSimultaneouslyGroup : NSObject

- (instancetype)initWithView:(UIView *)view;

- (void)removeGestureRecognizer:(UIGestureRecognizer *)recognizer;
- (void)removeWithCondition:(BOOL (^)(UIGestureRecognizer *recognizer))conditionMethod;

- (NSSet *)allSimulataneouslyGroups;
- (NSArray *)allGestureRecognizers;
- (NSSet *)simultaneouslyGroupIncludes:(UIGestureRecognizer *)recognizer;

- (void)eachGestureRecognizer:(void (^)(UIGestureRecognizer *recognizer))blockMethod;

@end
