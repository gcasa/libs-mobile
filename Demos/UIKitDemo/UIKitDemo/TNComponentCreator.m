//
//  TNComponentCreator.m
//  UIKitDemo
//
//  Created by TaoZeyu on 15/2/27.
//  Copyright (c) 2015年 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "TNComponentCreator.h"
#import "TNTestViewController.h"
#import "TNChangeValueSlider.h"

#define DefaultLineWidth 2.0
#define DefaultLineColor [UIColor blackColor]

@implementation TNComponentCreator

+ (void)makeSwitchItemWithTitle:(NSString *)title at:(CGFloat)yLocation withControl:(TNTestViewController *)testControl action:(SEL)action
{
    UISwitch *switchItem = [[UISwitch alloc] initWithFrame:CGRectMake(50, yLocation, 0, 0)];
    [switchItem addTarget:testControl action:action forControlEvents:UIControlEventValueChanged];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, yLocation, 100, 50)];
    titleLabel.text = title;
    
    [testControl.view addSubview:switchItem];
    [testControl.view addSubview:titleLabel];
}

+ (void)makeChangeValueSliderWithTitle:(NSString *)title at:(CGFloat)yLocation withControl:(UIViewController *)controller withMaxValue:(CGFloat)maxValue whenValueChanged:(void (^)(float value))action
{
    CGPoint point = CGPointMake(200, yLocation);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, yLocation, 175, 35)];
    TNChangeValueSlider *slider = [[TNChangeValueSlider alloc] initAt:point withMaxValue:maxValue whenValueChanged:^(float value) {
        NSString *titleContent = [NSString stringWithFormat:@"%@:%f", title, value];
        [label setText:titleContent];
        action(value);
    }];
    [controller.view addSubview:label];
    [controller.view addSubview:slider];
    [label setText:title];
}

+ (UIButton *)createButtonWithTitle:(NSString *)title withFrame:(CGRect)rect withBackgroundColor:(UIColor *)backgroundColor
{
    UIButton *button = [self createButtonWithTitle:title withFrame:rect];
    button.backgroundColor = backgroundColor;
    return button;
}

+ (UIButton *)createButtonWithTitle:(NSString *)title withFrame:(CGRect)rect
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.frame = rect;
    return button;
}

+ (UIImage *)createRectangleWithSize:(CGSize)size withColor:(UIColor *)color
{
    return [TNComponentCreator _createImageWithSize:size andDrawIn:^(CGContextRef context) {
        [TNComponentCreator _setGraphWithSize:size withColor:color withContextRef:context];
        CGContextAddRect(context, [TNComponentCreator _getRectangleWithSize:size withLineWidth:DefaultLineWidth]);
        CGContextDrawPath(context, kCGPathFillStroke);
    }];
}

+ (UIImage *)createEllipseWithSize:(CGSize)size withColor:(UIColor *)color
{
    return [TNComponentCreator _createImageWithSize:size andDrawIn:^(CGContextRef context) {
        [TNComponentCreator _setGraphWithSize:size withColor:color withContextRef:context];
        CGContextAddEllipseInRect(context, [TNComponentCreator _getRectangleWithSize:size withLineWidth:DefaultLineWidth]);
        CGContextDrawPath(context, kCGPathFillStroke);
    }];
}

+ (void)_setGraphWithSize:(CGSize)size withColor:(UIColor *)color withContextRef:(CGContextRef)context
{
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextSetStrokeColorWithColor(context, [DefaultLineColor CGColor]);
    CGContextSetLineWidth(context, DefaultLineWidth);
}

+ (CGRect)_getRectangleWithSize:(CGSize)size withLineWidth:(CGFloat)width
{
    return CGRectMake(width, width, size.width - width, size.height - width);
}

+ (UIImage *)_createImageWithSize:(CGSize)size andDrawIn:(void (^)(CGContextRef))drawInContext
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    drawInContext(context);
    CGContextRestoreGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
