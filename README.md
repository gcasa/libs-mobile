# Mirai-UIKit

**Mirai-UIKit** is a cross-platform mobile development framework that brings iOS's UIKit framework to Android devices. It allows developers to write iOS-style applications using familiar UIKit APIs and run them natively on Android.

## Project Overview

Mirai-UIKit is a native implementation of Apple's UIKit framework for Android devices. It enables developers to create applications using standard iOS development patterns and APIs, then deploy them on Android without major rewrites.

## Key Components

### 🎯 **Core Framework (UIKit/)**

- **Native UIKit Implementation**: Complete reimplementation of core UIKit classes including:
  - `UIApplication`, `UIView`, `UIViewController`
  - `UIButton`, `UILabel`, `UITextField`, `UIScrollView`
  - `UIGestureRecognizer` family (tap, pan, pinch, rotation)
  - `UIAlertView`, `UIActionSheet`, `UITabBarController`
  - Text rendering system (`NSAttributedString`, `NSTextContainer`, etc.)

### 🌉 **Java Bridge System**

- **TNJavaBridge** components provide seamless communication between Objective-C and Java/Android
- Handles method calls, callbacks, and data marshaling between the two runtime environments
- `TNJavaBridgeProxy` manages cross-platform object proxying

### 📱 **Android Integration**

- **CocoaActivity**: Android activity that hosts the UIKit application
- **AndroidMain**: Entry point that bridges Android's native app lifecycle to UIKit's application model
- Uses Android NDK for native code execution
- Integrates with Android's event system and OpenGL rendering

### 🎮 **Input & Touch Handling**

- Multi-touch gesture recognition system
- Touch event processing that maps Android touch events to iOS-style touch handling
- Support for complex gestures (simultaneous, failure relationships, etc.)

## Architecture

The project follows a layered architecture:

1. **Android Layer**: Standard Android app with NDK integration
2. **Bridge Layer**: Java↔Objective-C communication bridge
3. **UIKit Layer**: iOS-compatible UI framework implementation
4. **Application Layer**: Your actual UIKit app code

## Developer Experience

Developers can write applications using standard iOS patterns:

```objc
// Familiar iOS code that runs on Android
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

## Demo Application

The included **UIKitDemo** (`Demos/UIKitDemo/`) showcases extensive functionality testing various UIKit components, gestures, view controllers, and UI elements - proving that complex iOS applications can run on Android.

## Build System

- Uses Xcode projects with custom build configurations for Android targets
- Cross-compilation toolchain for building Objective-C code for Android (`toolchain_build.sh`)
- Integration with Android NDK build system
- Support for multiple Android architectures (ARM, x86)

## Getting Started

1. Set up the build environment with Android NDK
2. Configure the toolchain using `toolchain_build.sh`
3. Build the framework libraries (TNJavaHelper, UIKit)
4. Create your UIKit application following iOS development patterns
5. Build and deploy to Android devices

This project represents a significant engineering achievement - creating a complete UI framework compatibility layer that allows iOS developers to target Android without rewriting their applications from scratch.
