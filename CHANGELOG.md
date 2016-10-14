# Change Log
All notable changes to this project will be documented in this file.
`Kronos` adheres to [Semantic Versioning](http://semver.org/).

## [0.2.1](https://github.com/lyft/Kronos/releases/tag/0.2.1)
- Fix crash on DNS timeout after Swift 3 integration

## [0.2.0](https://github.com/lyft/Kronos/releases/tag/0.2.0)
- Added Swift 3 support

## [0.1.1](https://github.com/lyft/Kronos/releases/tag/0.1.1)
- Added IPv6 support

---

## [0.0.4](https://github.com/lyft/Kronos/releases/tag/0.0.4)

- Renamed `NSTimer` to `BlockTimer` to avoid collisions on dynamic dispatching
in case other modules are defining invokeFromTimer.

---

## [0.0.3](https://github.com/lyft/Kronos/releases/tag/0.0.3)

- Make sure progress callback is called even when DNS or NTP requests time out.

---

## [0.0.2](https://github.com/lyft/Kronos/releases/tag/0.0.2)

- Invalidate socket after use

---

## [0.0.1](https://github.com/lyft/Kronos/releases/tag/0.0.1)

Initial release
