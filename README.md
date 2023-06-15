<img src="https://cloud.githubusercontent.com/assets/232113/15371638/505de80a-1cf1-11e6-9e16-d462e02d9e45.png" height="140" />

Kronos is an NTP client library written in Swift. It supports
sub-seconds precision and provides a stable monotonic clock that won't
be affected by changes in the clock.

## Example app

[This](https://github.com/MobileNativeFoundation/Kronos/blob/master/Example/main.swift) is an
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

### [CocoaPods](http://cocoapods.org)

Add Kronos to your `Podfile`:

```ruby
pod 'Kronos'
```

### Swift Package Manager

Add Kronos to your `Pacakge.swift`:

```bash
.package(name: "Kronos", url: "https://github.com/MobileNativeFoundation/Kronos.git", .upToNextMajor(from: "TAG")),
```

### Bazel

Add Kronos to your `WORKSPACE`:

```bzl
http_archive(
    name = "Kronos",
    sha256 = "",
    strip_prefix = "Kronos-TAG/",
    url = "https://github.com/MobileNativeFoundation/Kronos/archive/TAG.tar.gz",
)
```

Then depend on `@Kronos//:Kronos`

### Android

Check out [Kronos for Android](https://github.com/lyft/Kronos-Android)
