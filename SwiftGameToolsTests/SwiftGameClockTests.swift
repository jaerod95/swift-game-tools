//
//  JRGameClockTests.swift
//  JRGameClockTests
//
//  Created by Jason Rodriguez on 12/6/18.
//

import XCTest
@testable import SwiftGameClock

class SwiftGameClockTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_time_intervals_are_correct() {
        assert(1.second == 1.0)
        assert(1.minute == 60.0)
        assert(1.hour == 1.minute * 60)
        assert(1.2.seconds == 1.2)
        assert(1.5.minutes == 90.0)
        assert(1.5.hours == 5400.0)
        assert(0.2.millisecond == 0.0002)
        assert(1.3.milliseconds == 0.0013)
        assert(1000.ms == 1.0000)
        assert(0.5.day == 43_200)
        assert(1.day == 86_400 )
        assert(2.days == 172_800)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
