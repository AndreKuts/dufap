//
//  InjectorRegistryTests.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import XCTest
import Dufap

final class InjectorRegistryTests: XCTestCase {

    func test_RegisterAndResolveInjector() {

        let mock = DependencyInjector()
        InjectorRegistry.register(mock)
        let resolved = InjectorRegistry.resolve()

        XCTAssertNotNil(resolved)
        XCTAssertTrue(resolved is DependencyInjector)
    }

    func test_ThreadSafetyInjector() {

        let concurrentCount = 100
        let expectation = XCTestExpectation(description: "Thread safety sync")
        expectation.expectedFulfillmentCount = concurrentCount
        let mock = DependencyInjector()

        DispatchQueue.concurrentPerform(iterations: concurrentCount) { _ in
            InjectorRegistry.register(mock)
            let resolved = InjectorRegistry.resolve()
            XCTAssertNotNil(resolved)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
