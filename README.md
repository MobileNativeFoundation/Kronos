<img src="https://cloud.githubusercontent.com/assets/232113/15371638/505de80a-1cf1-11e6-9e16-d462e02d9e45.png" height="140" />

Kronos is an NTP client library written in Swift. It supports
sub-seconds precision and provides an stable monotonic clock that won't
be affected by clock changes.

## Example app

[This](https://github.com/lyft/Kronos/blob/master/Example/main.swift) is an
example app that displays the monotonic `Clock.now` on the left and the
system clock (initially out of date) on the right.

![ascii-clock](https://cloud.githubusercontent.com/assets/232113/15371331/c24e8570-1cef-11e6-8598-428a0b5d66f9.gif)

## Usage

### Sync clock using a pool of NTP servers

Calling `Clock.sync` will fire a bunch of NTP requests to up to 5 of the
servers on the given NTP pool (default is `time.apple.com`). As soon as
we get the first response, the given closure is called but the `Clock`
will keep trying to get a more accurate response.

```swift
Clock.sync { date, offset in
    // This is the first sync (note that this is the fastest but not the
    // most accurate run
    print(date)
}
```

### Get an NTP sync'ed date

`Clock.now` is a monotonic NSDate that won't be affected by clock
changes.

```swift
NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
                                       selector: #selector(Example.tick),
                                       userInfo: nil, repeats: true)

@objc func tick() {
    print(Clock.now) // Note that this clock will get more accurate as
                     // more NTP servers respond.
}
```

## Installation

> **Embedded frameworks require a minimum deployment target of iOS 8 or OS
> X Mavericks (10.9).**

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.
You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build Kronos.

To integrate Kronos into your Xcode project using CocoaPods, specify it in
your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'Kronos'
```

Then, run the following command:

```bash
$ pod install
```

### Swift package manager (experimental)

[Swift PM](https://github.com/apple/swift-package-manager/) is a tool for
managing distribution of source code.

To integrate Kronos into your project using Swift PM use:

```bash
$ export SWIFT_EXEC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
$ swift build
```

## License

Kronos is maintained by [Lyft](https://www.lyft.com/) and released under
the Apache 2.0 license. See LICENSE for details.
