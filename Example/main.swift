import Darwin.ncurses
import Foundation
import Kronos

private let kClockWidth = 26
private let kPositionOffsetByBit = [(1, 1), (1, 0), (2, 0), (2, 1), (2, 3), (1, 3), (0, 1)]
private let kLEDDigits: [Int32] = [
    0b1111110, 0b0110000, 0b1101101, 0b1111001, 0b0110011,
    0b1011011, 0b1011111, 0b1110000, 0b1111111, 0b1111011,
]

private struct Curses {
    static func clear(x x: Int32, y: Int32, width: Int32, height: Int32) {
        for x in x ..< x + width {
            for y in y ..< y + height {
                Curses.mvprintw(y, x, " ")
            }
        }
    }

    static func mvprintw(y: Int32, _ x: Int32, _ message: String) {
        move(y, x)
        addstr(message)
    }
}

final class ASCIIClock {
    private var timer: NSTimer?

    private func start() {
        initscr() // Init window. Must be first
        keypad(stdscr, true) // Enable function and arrow keys
        noecho()
        curs_set(0) // Set cursor to invisible

        start_color()
        use_default_colors()
        init_pair(1, Int16(COLOR_GREEN), -1)
        attron(COLOR_PAIR(1))
        refresh()

        // Handle window resizing
        let handleWinch: @convention(c) Int32 -> Void = { signal in
            endwin()
            refresh()
            clear()
        }
        signal(SIGWINCH, handleWinch)

        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
                                                            selector: #selector(ASCIIClock.tick),
                                                            userInfo: nil, repeats: true)
        self.timer?.fire()

        // Initial NTP date is 0:0:0
        self.drawClock(hour: 0, minute: 0, second: 0,
                       title: "Not sync'ed", x: getmaxx(stdscr) / 3 - (kClockWidth / 2))
        self.loop()
    }

    func printDigit(digit: Int, y: Int32, x: Int32) {
        let digitMask = kLEDDigits[digit]

        for bit in 0 ..< 7 where (digitMask >> Int32(bit)) & 1 == 1 {
            let (yOffset, xOffset) = kPositionOffsetByBit[bit]
            let ascii = bit % 3 == 0 ? "__" : "|"
            Curses.mvprintw(y + yOffset, x + xOffset, ascii)
        }
    }

    @objc
    private func tick() {
        let calendar = NSCalendar.currentCalendar()
        let now = calendar.components([.Hour, .Minute, .Second], fromDate: NSDate())

        let column = getmaxx(stdscr), row = getmaxy(stdscr)
        Curses.mvprintw(row - 1, 0, "(q)uit, (s)ync")

        self.drawClock(hour: now.hour, minute: now.minute, second: now.second,
                       title: "Clock date", x: column * 2 / 3 - (kClockWidth / 2))

        if let date = Clock.now {
            let now = calendar.components([.Hour, .Minute, .Second], fromDate: date)
            self.drawClock(hour: now.hour, minute: now.minute, second: now.second,
                           title: "NTP date", x: column / 3 - (kClockWidth / 2))
        }
    }

    private func drawClock(hour hour: Int, minute: Int, second: Int, title: String, x: Int32) {
        let y: Int32 = getmaxy(stdscr) / 2 - 1

        Curses.clear(x: x, y: y - 1, width: Int32(kClockWidth), height: 5)
        for (index, component) in [hour, minute, second].enumerate() {
            printDigit(component / 10, y: y, x: x + 9 * index)
            printDigit(component % 10, y: y, x: x + 9 * index + 4)

            if index != 0 {
                mvaddch(y + 2, x + 9 * index - 1, 0x3a)
            }
        }

        Curses.mvprintw(y - 1, x,
                        title.stringByPaddingToLength(kClockWidth, withString: " ", startingAtIndex: 0))
        refresh()
    }

    private func loop() {
        let runLoop = NSRunLoop.currentRunLoop()
        nodelay(stdscr, true)
        loop: while runLoop.runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05)) {
            switch getch() {
                case 0x73: // s
                    self.drawClock(hour: 0, minute: 0, second: 0,
                                   title: "Syncing", x: getmaxx(stdscr) / 3 - (kClockWidth / 2))
                    Clock.sync()

                case 0x71: // q
                    endwin()
                    break loop

                default:
                    break
            }
        }
    }
}

ASCIIClock().start()
