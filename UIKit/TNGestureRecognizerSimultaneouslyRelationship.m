//
//  UIGestureRecognizerSimultaneouslyGroup.m
//  UIKit
//
//  Created by TaoZeyu on 15/9/9.
//  Copyright (c) 2015年 Shanghai Tinynetwork Inc. All rights reserved.
//

#import "TNGestureRecognizerSimultaneouslyRelationship.h"

#import "UIView.h"
#import "UIGestureRecognizer+UIPrivate.h"
#import "UIGestureRecognizerSubclass.h"
#import "TNGestureRecognizeProcess.h"

@implementation TNGestureRecognizerSimultaneouslyRelationship
{
    NSSet *_currentChoosedGroup;
    NSMutableSet *_allSimulataneouslyGroups;
    NSMutableDictionary *_recognizerToGroupDictionary;
    NSArray *_allGestureRecognizersCache;
}

- (instancetype)initWithGestureRecognizeProcessArray:(NSArray *)gestureRecognizeProcessArray
{
    if (self = [self init]) {
        _allSimulataneouslyGroups = [NSMutableSet set];
        _recognizerToGroupDictionary = [NSMutableDictionary dictionary];
        [self _collectGestureRecognizeProcesses:gestureRecognizeProcessArray];
    }
    return self;
}

- (void)dealloc
{
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        for (UIGestureRecognizer *recognizer in group) {
            [recognizer _unbindRecognizeProcess];
        }
    }
}

- (NSString *)description
{
    NSMutableArray *groupsInfo = [NSMutableArray array];
    for (NSSet *group in _allSimulataneouslyGroups) {
        NSMutableArray *groupInfo = [NSMutableArray array];
        for (UIGestureRecognizer *recognizer in group) {
            [groupInfo addObject:[recognizer _description]];
        }
        NSString *strGroup = [groupInfo componentsJoinedByString:@", "];
        if (_currentChoosedGroup == group) {
            strGroup = [NSString stringWithFormat:@"[*]%@", strGroup];
        }
        [groupsInfo addObject:[NSString stringWithFormat:@"{ %@ }", strGroup]];
    }
    return [groupsInfo componentsJoinedByString:@", "];
}

#pragma mark - read properties.

- (NSUInteger)count
{
    return _recognizerToGroupDictionary.count;
}

- (NSUInteger)countOfGestureRecongizeProcess:(TNGestureRecognizeProcess *)process
{
    __block NSUInteger count = 0;
    [self eachGestureRecognizerFrom:process loop:^(UIGestureRecognizer *recognizer) {
        count++;
    }];
    return count;
}

- (void)chooseSimultaneouslyGroupWhoIncludes:(UIGestureRecognizer *)recongizer
{
    _currentChoosedGroup = [self simultaneouslyGroupIncludes:recongizer];
}

- (BOOL)hasChoosedAnySimultaneouslyGroup
{
    return _currentChoosedGroup != nil;
}

- (BOOL)canRecongizerBeHandledSimultaneously:(UIGestureRecognizer *)recongizer
{
    if (_currentChoosedGroup) {
        return [_currentChoosedGroup containsObject:recongizer];
    } else {
        return YES;
    }
}

- (void)_clearChoosedSimultaneouslyGroup
{
    _currentChoosedGroup = nil;
}

- (void)removeGestureRecognizer:(UIGestureRecognizer *)recognizer
{
    NSAssert2(recognizer.state == UIGestureRecognizerStatePossible,
              @"when remove %@, it's state is %zi", recognizer.className, recognizer.state);
    
    NSValue *recognizerKey = [NSValue valueWithNonretainedObject:recognizer];
    NSMutableSet *includesRecognizerGroup = [_recognizerToGroupDictionary objectForKey:recognizerKey];
    
    if (includesRecognizerGroup) {
        [_recognizerToGroupDictionary removeObjectForKey:recognizerKey];
        [includesRecognizerGroup removeObject:recognizer];
        
        if (includesRecognizerGroup.count == 0) {
            [_allSimulataneouslyGroups removeObject:includesRecognizerGroup];
        }
        [recognizer _unbindRecognizeProcess];
    }
    [self _clearCache];
}

- (void)removeSimultaneouslyGroup:(NSSet *)group
{
    for (UIGestureRecognizer *recognizer in group) {
        NSValue *recognizerKey = [NSValue valueWithNonretainedObject:recognizer];
        [_recognizerToGroupDictionary removeObjectForKey:recognizerKey];
        [recognizer _unbindRecognizeProcess];
        
        NSAssert2(recognizer.state == UIGestureRecognizerStatePossible,
                  @"when remove %@, it's state is %zi", recognizer.className, recognizer.state);
    }
    [_allSimulataneouslyGroups removeObject:group];
    
    if (_currentChoosedGroup == group) {
        [self _clearChoosedSimultaneouslyGroup];
    }
}

- (void)removeWithCondition:(BOOL (^)(UIGestureRecognizer *))conditionMethod
{
    NSMutableSet *groupToRemove = [NSMutableSet set];
    
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        NSMutableSet *recognizerToRemove = [NSMutableSet set];
        for (UIGestureRecognizer *recognizer in group) {
            if (conditionMethod(recognizer)) {
                [recognizerToRemove addObject:recognizer];
                NSValue *recognizerKey = [NSValue valueWithNonretainedObject:recognizer];
                [_recognizerToGroupDictionary removeObjectForKey:recognizerKey];
                [recognizer _unbindRecognizeProcess];
            }
        }
        [group minusSet:recognizerToRemove];
        if (group.count == 0) {
            [groupToRemove addObject:group];
        }
    }
    [self _clearCache];
}

- (NSSet *)allSimulataneouslyGroups
{
    return _allSimulataneouslyGroups;
}

- (NSArray *)allGestureRecognizers
{
    if (_allGestureRecognizersCache) {
        return _allGestureRecognizersCache;
    }
    NSMutableArray *cache = [NSMutableArray array];
    
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        for (UIGestureRecognizer *recognizer in group) {
            [cache addObject:recognizer];
        }
    }
    _allGestureRecognizersCache = cache;
    return cache;
}

- (NSSet *)simultaneouslyGroupIncludes:(UIGestureRecognizer *)recognizer
{
    return [_recognizerToGroupDictionary objectForKey:[NSValue valueWithNonretainedObject:recognizer]];
}


- (void)eachGestureRecognizerFrom:(TNGestureRecognizeProcess *)process
                             loop:(void (^)(UIGestureRecognizer *))blockMethod
{
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        for (UIGestureRecognizer *recognizer in group) {
            if ([recognizer _bindedRecognizeProcess] == process) {
                blockMethod(recognizer);
            }
        }
    }
}

- (void)eachGestureRecognizerThatNotChoosedFrom:(TNGestureRecognizeProcess *)process
                                           loop:(void (^)(UIGestureRecognizer *))blockMethod
{
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        if (group != _currentChoosedGroup) {
            for (UIGestureRecognizer *recognizer in group) {
                if ([recognizer _bindedRecognizeProcess] == process) {
                    blockMethod(recognizer);
                }
            }
        }
    }
}

- (void)eachGestureRecognizerThatNotChoosed:(void (^)(UIGestureRecognizer *))blockMethod
{
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        if (group != _currentChoosedGroup) {
            for (UIGestureRecognizer *recognizer in group) {
                blockMethod(recognizer);
            }
        }
    }
}

- (UIGestureRecognizer *)findGestureRecognizer:(BOOL (^)(UIGestureRecognizer *recognizer))finderMethod
{
    for (NSMutableSet *group in _allSimulataneouslyGroups) {
        for (UIGestureRecognizer *recognizer in group) {
            if (finderMethod(recognizer)) {
                return recognizer;
            }
        }
    }
    return nil;
}

- (void)_clearCache
{
    _allGestureRecognizersCache = nil;
}

#pragma mark collect gesture recognizers

- (void)_collectGestureRecognizeProcesses:(NSArray *)gestureRecognizeProcessArray
{
    NSMutableArray *recongizers = [NSMutableArray array];
    for (TNGestureRecognizeProcess *gestureRecognizeProcess in gestureRecognizeProcessArray) {
        for (UIGestureRecognizer *recongizer in gestureRecognizeProcess.view.gestureRecognizers) {
            [recongizer _bindRecognizeProcess:gestureRecognizeProcess];
            [recongizers addObject:recongizer];
        }
    }
    
    [self _searchAndGenerateGroupsFrom: recongizers];
    
    for (UIGestureRecognizer *recongizer in recongizers) {
        if (![self simultaneouslyGroupIncludes:recongizer]) {
            NSMutableSet *singleGroup = [[NSMutableSet alloc] initWithObjects:recongizer, nil];
            [self _saveGroup:singleGroup forRecognizer:recongizer];
            [_allSimulataneouslyGroups addObject:singleGroup];
        }
    }
}

- (void)_searchAndGenerateGroupsFrom:(NSArray *)recognizers
{
    NSMutableArray *recognizersPool = [[NSMutableArray alloc] initWithArray:recognizers];
    while (recognizersPool.count > 0) {
        NSSet *group = [self _splitGroupFromPool:recognizersPool];
        [_allSimulataneouslyGroups addObject:group];
    }
}

- (NSSet *)_splitGroupFromPool:(NSMutableArray *)recognizersPool
{
    NSMutableSet *group = [[NSMutableSet alloc] init];
    [group addObject:[recognizersPool objectAtIndex:0]];
    
    for (UIGestureRecognizer *checkedRecognizer in recognizersPool) {
        if (![self _anyCanNotSimultaneouslyWith:checkedRecognizer inGroup:group]) {
            [group addObject:checkedRecognizer];
        }
    }
    for (UIGestureRecognizer *recognizer in group) {
        [recognizersPool removeObject:recognizer];
        [self _saveGroup:group forRecognizer:recognizer];
    }
    return group;
}

- (BOOL)_anyCanNotSimultaneouslyWith:(UIGestureRecognizer *)recognizer inGroup:(NSSet *)group
{
    for (UIGestureRecognizer *recognizerInGroup in group) {
        if (![self _isRecongizer:recognizer shouldRecongizeSimultaneouslyWithRecongizer:recognizerInGroup]) {
            return YES;
        }
    }
    return NO;
}

// I can't make sure this method is right, so I replace it with _searchAndGenerateGroupsFrom:
- (void)_findRecongizer0:(UIGestureRecognizer *)r0 recongizer1:(UIGestureRecognizer *)r1
{
    if ([self _isRecongizer:r0 shouldRecongizeSimultaneouslyWithRecongizer:r1]) {
        
        NSMutableSet *group0 = (NSMutableSet *)[self simultaneouslyGroupIncludes:r0];
        NSMutableSet *group1 = (NSMutableSet *)[self simultaneouslyGroupIncludes:r1];
        
        [self _standardizeGroup0:&group0 group1:&group1];
        
        if (group0 == nil && group1 == nil) {
            NSMutableSet *group = [[NSMutableSet alloc] initWithObjects:r0, r1, nil];
            [self _saveGroup:group forRecognizer:r0];
            [self _saveGroup:group forRecognizer:r1];
            [_allSimulataneouslyGroups addObject:group];
            
        } else if (group0 != nil && group1 == nil) {
            [group0 addObject:r1];
            [self _saveGroup:group0 forRecognizer:r1];
            
        } else if (group0 != nil && group1 != nil) {
            
            if (group0 != group1) {
                for (UIGestureRecognizer *otherRecongizer in group1) {
                    [group0 addObject:otherRecongizer];
                    [self _saveGroup:group0 forRecognizer:otherRecongizer];
                }
                [_allSimulataneouslyGroups removeObject:group1];
            }
            
        } else {
            NSLog(@"ERROR: Invalid Condition!");
        }
    }
}

- (void)_standardizeGroup0:(NSMutableSet **)group0 group1:(NSMutableSet **)group1
{
    NSUInteger count0 = 0;
    NSUInteger count1 = 0;
    
    if (*group0) {
        count0 = (*group0).count;
    }
    if (*group1) {
        count1 = (*group1).count;
    }
    
    if (count0 < count1) {
        NSMutableSet *temp = *group0;
        *group0 = *group1;
        *group1 = temp;
    }
}

- (BOOL)_isRecongizer:(UIGestureRecognizer *)r0 shouldRecongizeSimultaneouslyWithRecongizer:(UIGestureRecognizer *)r1
{
    BOOL shouldSimultaneously = NO;
    
    if ([r0.delegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        shouldSimultaneously = [r0.delegate gestureRecognizer:r0
           shouldRecognizeSimultaneouslyWithGestureRecognizer:r1];
    }
    
    if (!shouldSimultaneously && [r1 _hasBeenPreventedByOtherGestureRecognizer]) {
        shouldSimultaneously = ![r0 canBePreventedByGestureRecognizer:r0] &&
                               ![r1 canPreventGestureRecognizer:r0];
    }
    return shouldSimultaneously;
}

- (void)_saveGroup:(NSSet *)group forRecognizer:(UIGestureRecognizer *)recognizer
{
    NSValue *recognizerKey = [NSValue valueWithNonretainedObject:recognizer];
    [_recognizerToGroupDictionary setObject:group forKey:recognizerKey];
}

@end
