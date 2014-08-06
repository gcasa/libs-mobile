//
//  UIEvent.m
//  UIKit
//
//  Created by Chen Yonghui on 1/19/14.
//  Copyright (c) 2014 Shanghai Tinynetwork Inc. All rights reserved.
//

#import "UIEvent.h"
#import "UITouch.h"

#import "UIEvent+Android.h"
#include <android/input.h>
#import "UITouch+Private.h"
//#include <string.h>
//#include <jni.h>

#import "UIScreenPrivate.h"


@implementation UIEvent {
    NSMutableSet *_touches;
    NSMutableDictionary *_touchesByIdentifier;
}

- (id)initWithEventType:(UIEventType)type
{
    self = [super init];
    if (self) {
        _type = type;
        _touches = [NSMutableSet set];
        _touchesByIdentifier = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSSet *)allTouches
{
    return [_touches copy];
}

- (NSSet *)touchesForWindow:(UIWindow *)window
{
    NSMutableSet *touches = [NSMutableSet setWithCapacity:1];
    for (UITouch *touch in [self allTouches]) {
        if (touch.window == window) {
            [touches addObject:touch];
        }
    }
    return touches;
}

- (NSSet *)touchesForView:(UIView *)view
{
    NSMutableSet *touches = [NSMutableSet setWithCapacity:1];
    for (UITouch *touch in [self allTouches]) {
        if (touch.view == view) {
            [touches addObject:touch];
        }
    }
    return touches;
}

- (NSSet *)touchesForGestureRecognizer:(UIGestureRecognizer *)gesture
{
    NSMutableSet *touches = [NSMutableSet setWithCapacity:1];
    for (UITouch *touch in [self allTouches]) {
        if ([touch.gestureRecognizers containsObject:gesture]) {
            [touches addObject:touch];
        }
    }
    return touches;
}

- (UIEventSubtype)subtype
{
    return UIEventSubtypeNone;
}

- (void)_setTimestamp:(NSTimeInterval)timestamp
{
    _timestamp = timestamp;
}

@end

@implementation UIEvent (Android)

/*
 * Android Event Handle
 
 Infomation from AInputEvent
 
 Event type:  AInputEvent_getType
 AINPUT_EVENT_TYPE_MOTION: a touch event type
 AINPUT_EVENT_TYPE_KEY: a keyboard event type
 
 For touch event:
 eventTime:  AMotionEvent_getEventTime()
 touchCount: AMotionEvent_getPointerCount()
 pointerID:  AMotionEvent_getPointerId()
 motionFlag: AMotionEvent_getFlags() , non-needs
 metaState:  AMotionEvent_getMetaState(), non-needs
 edgeFlags: AMotionEvent_getEdgeFlags(), non-needs
 downTime: AMotionEvent_getDownTime(), originally touch down time
 
 masked action: AMotionEvent_getAction()
 true action:    MaskedAction & AMOTION_EVENT_ACTION_MASK
 AMOTION_EVENT_ACTION_DOWN: touch down
 AMOTION_EVENT_ACTION_UP: touch up
 AMOTION_EVENT_ACTION_MOVE:
 AMOTION_EVENT_ACTION_CANCEL
 AMOTION_EVENT_ACTION_OUTSIDE
 AMOTION_EVENT_ACTION_POINTER_DOWN:
 AMOTION_EVENT_ACTION_POINTER_UP:
 
 // point, window coordinate
 point x:    AMotionEvent_getX
 point y:    AMotionEvent_getY
 
 // point, screen coordinate
 rawX:   AMotionEvent_getRawX()
 rawY    AMotionEvent_getRawY()
 
 // coordinate offset, adjust windows origin
 xOffset:    AMotionEvent_getXOffset()
 yOffset:    AMotionEvent_getYOffset()
 
 // precision, non-used
 xPrecision  AMotionEvent_getXPrecision()
 yPrecision  AMotionEvent_getYPrecision()
 
 pressure AMotionEvent_getPressure(), non-used
 
 AMotionEvent_getSize() fingure size? non-used
 
 // touch area ellipse, non-used
 AMotionEvent_getTouchMajor()
 AMotionEvent_getTouchMinor()
 
 // historical
 
 AMotionEvent_getHistoricalEventTime()
 AMotionEvent_getHistoricalRawX()
 AMotionEvent_getHistoricalRawY()
 AMotionEvent_getHistoricalX()
 AMotionEvent_getHistoricalY()
 AMotionEvent_getHistoricalPressure()
 
 
 */
- (void)_updateWithAEvent:(AInputEvent *)aEvent
{
    [self _updateTouchesWithEvent:aEvent];

    int64_t eventTime = AMotionEvent_getEventTime(aEvent);
    const NSTimeInterval eventTimestamp = eventTime/1000000000.0; // convert nanoSeconds to Seconds
    [self _setTimestamp:eventTimestamp];
    
    int32_t action = AMotionEvent_getAction(aEvent);
    int32_t trueAction = action & AMOTION_EVENT_ACTION_MASK;
    int32_t pointerIndex = (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
    int32_t pointerIdentifier = AMotionEvent_getPointerId(aEvent, pointerIndex);
    float x = AMotionEvent_getRawX(aEvent, pointerIndex);
    float y = AMotionEvent_getRawY(aEvent, pointerIndex);

    CGFloat scale = [[UIScreen mainScreen] scale];
    
    // top-left coordinate
    const CGPoint screenLocation = CGPointMake(x/scale, y/scale);
    NSString *actionName = [self nameForMotionAction:trueAction];
    UITouchPhase phase = [self _phaseForMotionAction:trueAction];
    NSLog(@"action:%@ phase:%@",actionName,[self _nameForPhase:phase]);
    
    UITouch *touch = [self _touchForIdentifier:pointerIdentifier];

    [touch _updatePhase:phase screenLocation:screenLocation timestamp:eventTimestamp];
    UIView *previousView = touch.view;
    UIScreen *theScreen = [UIScreen mainScreen];
    [touch _setTouchedView:[theScreen _hitTest:screenLocation event:self]];
    
    for (UITouch *t in _touches) {
        if (t.identifier == pointerIdentifier) {
            continue;
        }
        
        [t _updatePhase:UITouchPhaseStationary];
    }
}

- (NSString *)_nameForPhase:(UITouchPhase)phase
{
    static NSDictionary *map = nil;
    if (!map) {
        map = @{
                @(UITouchPhaseBegan):@"UITouchPhaseBegan",
                @(UITouchPhaseMoved):@"UITouchPhaseMoved",
                @(UITouchPhaseEnded):@"UITouchPhaseEnded",
                @(UITouchPhaseCancelled):@"UITouchPhaseCancelled",
                @(UITouchPhaseStationary):@"UITouchPhaseStationary",
                @(_UITouchPhaseGestureBegan):@"_UITouchPhaseGestureBegan",
                @(_UITouchPhaseGestureChanged):@"_UITouchPhaseGestureChanged",
                @(_UITouchPhaseGestureEnded):@"_UITouchPhaseGestureEnded",
                @(_UITouchPhaseDiscreteGesture):@"_UITouchPhaseDiscreteGesture",};
    }
    
    return [map objectForKey:@(phase)];
}
- (UITouchPhase)_phaseForMotionAction:(int32_t)action
{
    UITouchPhase phase = UITouchPhaseCancelled;
    switch (action) {
        case AMOTION_EVENT_ACTION_DOWN:
            phase = UITouchPhaseBegan;
            break;
        case AMOTION_EVENT_ACTION_UP:
            phase = UITouchPhaseEnded;
            break;
        case AMOTION_EVENT_ACTION_MOVE:
            phase = UITouchPhaseMoved;
            break;
        case AMOTION_EVENT_ACTION_CANCEL:
            phase = UITouchPhaseCancelled;
            break;
        case AMOTION_EVENT_ACTION_OUTSIDE:
            phase = UITouchPhaseCancelled;
            break;
        case AMOTION_EVENT_ACTION_POINTER_DOWN: //FIXME: what?
            phase = UITouchPhaseBegan;
            break;
        case AMOTION_EVENT_ACTION_POINTER_UP:
            phase = UITouchPhaseEnded;
            break;
        default:
            phase = UITouchPhaseCancelled;
            break;
    }
    
    return phase;
}

- (UITouch *)_touchForIdentifier:(NSInteger)identifier
{
    for (UITouch *touch in [self allTouches]) {
        if (touch.identifier == identifier) {
            return touch;
        }
    }
    return nil;
}

- (void)_updateTouchesWithEvent:(AInputEvent *)aEvent
{
    size_t pointerCount = AMotionEvent_getPointerCount(aEvent);
    
    NSMutableDictionary *prevExists = [_touchesByIdentifier mutableCopy];
    
    for (size_t pointer_index = 0; pointer_index < pointerCount ; pointer_index++) {
        int32_t pointerIdentifier = AMotionEvent_getPointerId(aEvent, pointer_index);
        UITouch *touch = [self _touchForIdentifier:pointerIdentifier];
        if (touch == nil) {
            touch = [[UITouch alloc] init];
            touch.identifier = pointerIdentifier;
            [_touches addObject:touch];
            [_touchesByIdentifier setObject:touch forKey:@(pointerIdentifier)];
        }
        [prevExists removeObjectForKey:@(pointerIdentifier)];
        
//        float rawX = AMotionEvent_getRawX(aEvent, pointer_index);
//        float rawY = AMotionEvent_getRawY(aEvent, pointer_index);
//        
//        NSLog(@"pointerId:%d raw: {%.2f, %.2f}",pointerIdentifier,rawX,rawY);
//        
//        AMotionEvent_getOrientation(aEvent, pointer_index);
//        AMotionEvent_getSize(aEvent, pointer_index);
//        AMotionEvent_getPressure(aEvent, pointer_index);
//        AMotionEvent_getToolMajor(aEvent, pointer_index);
//        AMotionEvent_getToolMinor(aEvent, pointer_index);
//        AMotionEvent_getTouchMajor(aEvent, pointer_index);
//        AMotionEvent_getTouchMinor(aEvent, pointer_index);
//        float x = AMotionEvent_getX(aEvent, pointer_index);
//        float y = AMotionEvent_getY(aEvent, pointer_index);
    }
    
    // clean touch
    if (prevExists.count > 0) {
        for (NSString *key in prevExists.allKeys) {
            UITouch *t = [_touchesByIdentifier objectForKey:key];
            [_touches removeObject:t];
            [_touchesByIdentifier removeObjectForKey:key];
        }
    }
}

- (NSString *)nameForMotionAction:(int32_t)action
{
    NSString *actionName;
    switch (action) {
        case AMOTION_EVENT_ACTION_DOWN:
            actionName = @"down";
            break;
        case AMOTION_EVENT_ACTION_UP:
            actionName = @"up";
            break;
        case AMOTION_EVENT_ACTION_MOVE:
            actionName = @"move";
            break;
        case AMOTION_EVENT_ACTION_CANCEL:
            actionName = @"cancel";
            
            break;
        case AMOTION_EVENT_ACTION_OUTSIDE:
            actionName = @"outside";
            break;
        case AMOTION_EVENT_ACTION_POINTER_DOWN:
            actionName = @"pointer down";
            break;
        case AMOTION_EVENT_ACTION_POINTER_UP:
            actionName = @"pointer up";
            break;
        default:
            actionName = @"unknow";
            break;
    }

    return actionName;
}

- (instancetype)initWithAKeyEvent:(AInputEvent *)aEvent
{
    self = [self initWithEventType:UIEventTypeKeyPress];
    if (self) {
        NSLog(@"Key event: action=%d keyCode=%d metaState=0x%x",
              AKeyEvent_getAction(aEvent),
              AKeyEvent_getKeyCode(aEvent),
              AKeyEvent_getMetaState(aEvent));
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> timestamp:%.0f touches %@",NSStringFromClass(self.class),self, self.timestamp,self.allTouches.allObjects];
}

@end
