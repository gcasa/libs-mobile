/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UITapGestureRecognizer.h"
#import "UIGestureRecognizerSubclass.h"
#import "UITouch.h"
#import "UIGeometry.h"
#import "TNMultiTapHelper.h"

#define kBeInvalidTime 0.8
#define kTapLimitAreaSize 5

@interface UITapGestureRecognizer()
@property (nonatomic, strong) NSMutableArray *touches;
@property (nonatomic, assign) NSUInteger numTouches;
@property (nonatomic, strong) NSMutableDictionary *beganLocations;
@property (nonatomic, strong) TNMultiTapHelper *multiTapHelper;
@property (nonatomic, assign) BOOL waitForNewTouchBegin;
@end

@implementation UITapGestureRecognizer
@synthesize numberOfTapsRequired=_numberOfTapsRequired, numberOfTouchesRequired=_numberOfTouchesRequired;

- (instancetype)init
{
    if (self = [super init]) {
        _numberOfTapsRequired = 1;
        _numberOfTouchesRequired = 1;
        _touches = [NSMutableArray array];
        _beganLocations = [NSMutableDictionary dictionary];
        _multiTapHelper = [[TNMultiTapHelper alloc] initWithTimeInterval:kBeInvalidTime
                                                       gestureRecognizer:self];
        _waitForNewTouchBegin = YES;
    }
    return self;
}

- (void)setNumberOfTapsRequired:(NSUInteger)numberOfTapsRequired
{
    _numberOfTapsRequired = numberOfTapsRequired;
    _multiTapHelper.numberOfTapsRequired = numberOfTapsRequired;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    // this logic is here based on a note in the docs for -canPreventGestureRecognizer:
    // it may not be correct :)
    if ([preventedGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return (((UITapGestureRecognizer *)preventedGestureRecognizer).numberOfTapsRequired <= self.numberOfTapsRequired);
    } else {
        return [super canPreventGestureRecognizer:preventedGestureRecognizer];
    }
}

- (void)reset
{
    [super reset];
    [_multiTapHelper reset];
    [_touches removeAllObjects];
    [self _resetOneTap];
}

- (void)_resetOneTap
{
    _numTouches = 0;
    _waitForNewTouchBegin = YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_touches addObjectsFromArray:touches.allObjects];
    
    if (!_waitForNewTouchBegin || [self _pressedTouchesCount] > self.numberOfTouchesRequired) {
        [_multiTapHelper cancelTap];
        return;
    }
    
    for (UITouch *t in touches) {
        NSInteger idx = [_touches indexOfObject:t];
        CGPoint initPoint = [t locationInView:nil];
        NSValue *v = [NSValue valueWithCGPoint:initPoint];
        _beganLocations[@(idx)] = v;
    }
    [_multiTapHelper beginOneTap];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self _anyTouchesOutOfArea:touches]) {
        [_multiTapHelper cancelTap];
    }
}

- (BOOL)_anyTouchesOutOfArea:(NSSet *)touches
{
    for (UITouch *touch in touches) {
        if ([self _isTouchOutOfArea:touch]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)_isTouchOutOfArea:(UITouch *)touch
{
    CGPoint currentLocation = [self locationInView:nil];
    
    NSInteger idx = [_touches indexOfObject:touch];
    CGPoint beginPoint = [_beganLocations[@(idx)] CGPointValue];
    
    if (ABS(currentLocation.x - beginPoint.x) > kTapLimitAreaSize ||
        ABS(currentLocation.y - beginPoint.y) > kTapLimitAreaSize) {
        // if move so far, failed
        return YES;
    }
    return NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_touches removeObjectsInArray:touches.allObjects];
    _numTouches += touches.count;
    _waitForNewTouchBegin = NO;
    
    if (_touches.count == 0) {
        // all touches ended
        if (_numTouches >= self.numberOfTouchesRequired) {
            [_multiTapHelper completeOneTap];
            [self _resetOneTap];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_multiTapHelper cancelTap];
}

- (NSUInteger)_pressedTouchesCount
{
    return _touches.count;
}

@end
