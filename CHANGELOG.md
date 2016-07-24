# Change Log
All notable changes to this project will be documented in this file.
`Kronos` adheres to [Semantic Versioning](http://semver.org/).

## [0.1.0](https://github.com/Reflejo/Kronos/releases/tag/0.1.0)

- Added IPv6 support

---

## [0.0.4](https://github.com/Reflejo/Kronos/releases/tag/0.0.4)

- Renamed `NSTimer` to `BlockTimer` to avoid collisions on dynamic dispatching
in case other modules are defining invokeFromTimer.

---

## [0.0.3](https://github.com/Reflejo/Kronos/releases/tag/0.0.3)

- Make sure progress callback is called even when DNS or NTP requests time out.
