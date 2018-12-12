//
// SwiftGameClock
//
// Copyright (c) 2018 Jason Rodriguez

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

private class GameClockEvent {

    let key: String
    let event: () -> Void

    init(key: String, event: @escaping () -> Void) {
        self.key = key
        self.event = event
    }

    func execute() {
        self.event()
    }
}

private class OnceGameClockEvent: GameClockEvent {

    override func execute() {
        self.event()
        SwiftGameClock.unregisterEvent(self.key)
    }
}

private class IntervalGameClockEvent: GameClockEvent {

    let interval: Int
    var currentInterval: Int = 0


    init(key: String, interval: Int, executeImmediately: Bool, event: @escaping () -> Void) {
        if executeImmediately {
            self.currentInterval = interval - 1
        }
        self.interval = interval
        super.init(key: key, event: event)
    }

    override func execute() {
        self.currentInterval += 1
        if self.currentInterval == self.interval {
            self.event()
            self.currentInterval = 0
        }
    }
}

open class SwiftGameClock {

    /// Class Constants

    private static let CHANGE_KEY = "SWIFT_GAME_CLOCK_CHANGE_INTERVAL_KEY"
    private static let QUEUE_KEY = "SwiftGameClock"

    /// Priority Queue for event bus.

    private static let queue: DispatchQueue = DispatchQueue(label: QUEUE_KEY, qos: DispatchQoS.userInteractive)

    /// The tick interval used by the GameClock.

    private(set) static var tickInterval: TimeInterval = 1.0

    /// The timer used to execute clicks

    private(set) static var timer: Timer?

    /// Queue for Events that execute a single time on the next tick.

    private static var eventQueue: [String: GameClockEvent] = [:]

    /// Returns true if the timer is running.

    class var isRunning: Bool {
        get {
            return timer != nil
        }
    }

    /**
     The main event loop for the GameClock. All Queued Events are executed here.
     */

    @objc class func tick() {
        self.eventQueue.forEach({ (key, event) in
            self.queue.sync {
                event.execute()
            }
        })
    }


    /// Starts the GameClock.

    public class func start() {
        SwiftGameClock.changeInterval(0.6.seconds)
        timer = Timer.scheduledTimer(
            timeInterval: tickInterval,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true)
    }

    /// Stops the GameClock.

    public class func stop() {
        timer?.invalidate()
        timer = nil
    }

    /**
     Changes the interval after the next Tick unless specified.
     - Parameters:
       - interval: TimeInterval for the GameClock to use.
       - afterNextTick: If true, waits until the next tick to execute the change. If false, it invalidates the timer and makes the change immediately. Defaults to true.
     */

    public class func changeInterval(_ interval: TimeInterval, _ afterNextTick: Bool = true) {
        if isRunning {
            if afterNextTick {
                self.once(CHANGE_KEY) {
                    changeIntervalHelper(interval)
                }
            } else {
                changeIntervalHelper(interval)
            }
        } else {
            self.tickInterval = interval
        }
    }

    /**
     Helper function that stops the timer when running, changes the interval, and then restarts the timer.
     - Parameters
       - interval: The new time interval for the game clock
     */

    private class func changeIntervalHelper(_ interval: TimeInterval) {
        self.stop()
        self.tickInterval = interval
        self.start()
    }

    // MARK: - Queue Manipulation Funcs

    /**
     Adds a GameClockEvent that only executes once and then removes itself.
     - Parameters:
        - key: The key used to reference the event in the queue.
        - event: The event closure box to execute.
    */

    public class func once(_ key: String, event: @escaping () -> ()) {
        self.eventQueue[key] = OnceGameClockEvent(key: key, event: event)
    }

    /**
     Adds a GameClockEvent that executes every tick.
     - Parameters:
        - key: The key used to reference the event in the queue.
        - event: The event closure box to execute.
     */

    public class func onTick(_ key: String, event: @escaping () -> ()) {
        self.eventQueue[key] = GameClockEvent(key: key, event: event)
    }

    /**
     Adds a GameClockEvent that executes every set number of ticks.
     - Parameters:
        - key: The key used to reference the event in the queue.
        - interval: The interval which to execute the event.
        - executeImmediately: If true, executes the event next tick. If false, it waits the interval before executing. Defaults to false.
        - event: The event closure box to execute.
     */

    public class func onInterval(_ key: String, _ interval: Int, executeImmediately: Bool = false, event: @escaping () -> ()) {
        self.eventQueue[key] = IntervalGameClockEvent(key: key, interval: interval, executeImmediately: executeImmediately, event: event)
    }

    /**
     Unregisters the event specified by the key provided from the event queue and returns the event function.
     - Parameters
     - key: The key for the event to remove.
     
     - Returns: The event closure.
     */

    @discardableResult
    public class func unregisterEvent(_ key: String) -> (() -> ())? {
        return self.eventQueue.removeValue(forKey: key)?.event
    }
}

// MARK: - Time Helpers

//
// SwiftyTimer
//
// Copyright (c) 2015-2016 Radosław Pietruszewski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
extension Double {
    public var millisecond: TimeInterval { return self / 1000 }
    public var milliseconds: TimeInterval { return self / 1000 }
    public var ms: TimeInterval { return self / 1000 }

    public var second: TimeInterval { return self }
    public var seconds: TimeInterval { return self }

    public var minute: TimeInterval { return self * 60 }
    public var minutes: TimeInterval { return self * 60 }

    public var hour: TimeInterval { return self * 3600 }
    public var hours: TimeInterval { return self * 3600 }

    public var day: TimeInterval { return self * 3600 * 24 }
    public var days: TimeInterval { return self * 3600 * 24 }
}
