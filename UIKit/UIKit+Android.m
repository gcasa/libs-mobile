//
//  UIKit+Android.m
//  NextBook
//
//  Created by Chen Yonghui on 4/1/14.
//  Copyright (c) 2014 Shanghai TinyNetwork. All rights reserved.
//

#import "UIKit+Android.h"

#import <CoreFoundation/CoreFoundation.h>

@implementation NSString (Android)

- (void)enumerateSubstringsInRange:(NSRange)range options:(NSStringEnumerationOptions)opts usingBlock:(void (^)(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop))block
{
    NSLog(@"%s UNIMPLEMENTED",__PRETTY_FUNCTION__);
    
    BOOL isReverse = opts & NSStringEnumerationReverse;
    BOOL isLocalized = opts & NSStringEnumerationLocalized;
    BOOL isSubstringNotRequired = opts & NSStringEnumerationSubstringNotRequired;
    NSStringEnumerationOptions by = opts & 0x0001111111;
    
    NSUInteger length = self.length;
    NSRange subStringRange = NSMakeRange(0, length);

    if (by == NSStringEnumerationByWords) {
    } else if (by == NSStringEnumerationByLines) {
        
    } else {
        NSLog(@"unimplemented options:%d",opts);
    }
    BOOL shouldStop = NO;
    @autoreleasepool {
        block(self,subStringRange,subStringRange,&shouldStop);
    }
    
}

@end
@implementation NSFileManager (Android)
- (NSArray *)URLsForDirectory:(NSSearchPathDirectory)directory inDomains:(NSSearchPathDomainMask)domainMask
{
    NSLog(@"%s UNIMPLEMENTED",__PRETTY_FUNCTION__);
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *path = [bundlePath stringByDeletingLastPathComponent];
    NSString *result = nil;
    switch (directory) {
        case NSCachesDirectory:
            result = [path stringByAppendingPathComponent:@"Caches"];
            break;
        case NSDocumentDirectory:
            result = [path stringByAppendingPathComponent:@"Document"];
            break;
        case NSLibraryDirectory:
            result = [path stringByAppendingPathComponent:@"Library"];
            break;
        default:
            NSLog(@"unknow search path directory:%d",directory);
            break;
    }
    if (result) {
        NSLog(@"%@",result);
        return @[[NSURL fileURLWithPath:result]];
    }
    
    return @[];
}

@end

@implementation NSAttributedString (Android)
- (void)enumerateAttributesInRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(NSDictionary *attrs, NSRange range, BOOL *stop))block
{
    BOOL isLongestEffectiveRangeNotRequired = opts & NSAttributedStringEnumerationLongestEffectiveRangeNotRequired;
    BOOL isReverse = opts & NSAttributedStringEnumerationReverse;
    if (isReverse) {
        NSLog(@"NSAttributedStringEnumerationReverse option unimplemented");
    }

    BOOL shouldStop = NO;
    NSInteger pos = enumerationRange.location;
    NSInteger end = NSMaxRange(enumerationRange);
    
    while (pos < end) {
        NSRange effectiveRange;
        NSDictionary *attributes = nil;
        
        if (isLongestEffectiveRangeNotRequired) {
            attributes = [self attributesAtIndex:enumerationRange.location effectiveRange:&effectiveRange];
        } else {
            attributes = [self attributesAtIndex:pos longestEffectiveRange:&effectiveRange inRange:enumerationRange];
        }

        block(attributes,effectiveRange,&shouldStop);
        
        pos = NSMaxRange(effectiveRange);
        if (shouldStop) {
            break;
        }
    }
}

- (void)enumerateAttribute:(NSString *)attrName inRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(id, NSRange, BOOL *))block
{
    BOOL isLongestEffectiveRangeNotRequired = opts & NSAttributedStringEnumerationLongestEffectiveRangeNotRequired;
    BOOL isReverse = opts & NSAttributedStringEnumerationReverse;
    
    if (isReverse) {
        NSLog(@"NSAttributedStringEnumerationReverse option unimplemented");
    }
    
    BOOL shouldStop = NO;
    NSInteger pos = enumerationRange.location;
    NSInteger end = NSMaxRange(enumerationRange);
    while (pos < end) {
        NSRange effectiveRange;
        id attribute = nil;
        if (isLongestEffectiveRangeNotRequired) {
            attribute = [self attribute:attrName atIndex:pos effectiveRange:&effectiveRange];
        } else {
            attribute = [self attribute:attrName atIndex:pos longestEffectiveRange:&effectiveRange inRange:enumerationRange];
        }
        
        block(attribute,effectiveRange,&shouldStop);
        
        pos = NSMaxRange(effectiveRange);
        if (shouldStop) {
            break;
        }
    }

}

@end

@interface NSBlockOperation ()
@property (nonatomic, strong) NSMutableArray *blocks;
@end
@implementation NSBlockOperation

+ (id)blockOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation *op = [[self alloc] init];
    [op addExecutionBlock:block];
    
    return op;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _blocks = [NSMutableArray array];
    }
    return self;
}

- (void)addExecutionBlock:(void (^)(void))block
{
    [_blocks addObject:[block copy]];
}

- (NSArray *)executionBlocks
{
    return _blocks;
}

- (void)main
{
    for (void (^b)(void) in _blocks) {
        if (self.isCancelled) {
            break;
        }
        
        b();
    }
}

@end

@implementation NSOperationQueue (Android)

- (void)addOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation *blockOP = [NSBlockOperation blockOperationWithBlock:block];
    [self addOperation:blockOP];
}

@end

@implementation NSURL (Android)

+ (id)fileURLWithPath:(NSString *)path isDirectory:(BOOL) isDir
{
    return [NSURL fileURLWithPath:path];
}

@end

@implementation NSIndexSet (Android)

- (NSIndexSet *)indexesInRange:(NSRange)range options:(NSEnumerationOptions)opts passingTest:(BOOL (^)(NSUInteger idx, BOOL *stop))predicate
{
    NSLog(@"%s UNIMPLEMENTED",__PRETTY_FUNCTION__);
    return nil;
}

@end

@implementation NSObject (Android)

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context
{
    NSLog(@"%s UNIMPLEMENTED",__PRETTY_FUNCTION__);
}

@end


CFIndex CFStringGetHyphenationLocationBeforeIndex(CFStringRef string, CFIndex location, CFRange limitRange, CFOptionFlags options, CFLocaleRef locale, UTF32Char *character)
{
    NSLog(@"%s UNIMPLEMENTED",__PRETTY_FUNCTION__);
    return 0;
}
