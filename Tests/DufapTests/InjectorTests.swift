//
//  InjectorTests.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import XCTest
@testable import Dufap

class TestInjector: Injector {
    let updateStateQueue: DispatchQueue = .init(label: "dufap.test.injector.queue")
    var state: InjectorState = .init()
}

struct TestService: Equatable {
    let id: UUID
}

class InjectorTests: XCTestCase {

    var injector: TestInjector!

    override func setUp() {
        super.setUp()
        injector = TestInjector()
    }

    override func tearDown() {
        injector = nil
        super.tearDown()
    }

    func testExtractReturnsSameInstance() {

        let service = TestService(id: .init())
        injector.inject(for: .singleton) { _ in service }

        let extracted: TestService = injector.extract(from: .singleton)
        XCTAssertEqual(extracted, service, "Singleton extract should return the same instance that was injected")
    }

    func testExtractReturnsNewInstanceEachTime() {

        injector.inject(for: .factory) { _ in TestService(id: .init()) }

        let a: TestService = injector.extract(from: .factory)
        let b: TestService = injector.extract(from: .factory)
        XCTAssertNotEqual(a, b, "Factory extract should return a new instance on each call")
    }

    func testExtractSingletonThenFactory() {

        let uuid = UUID()
        injector.inject(for: .both) { _ in TestService(id: uuid) }

        let singleton: TestService = injector.extract(from: .singleton)
        let factory: TestService = injector.extract(from: .factory)

        XCTAssertEqual(singleton.id, uuid, "Singleton ID should match injected UUID")
        XCTAssertEqual(factory.id, uuid, "Factory ID should match injected UUID")
    }

    func testRemovesOnlySingleton() {

        injector.inject(for: .both) { _ in TestService(id: .init()) }
        injector.eject(type: TestService.self, from: .singleton)

        XCTAssertThrowsError(
            try injector.extractThrows(from: .singleton) as TestService,
            "Expected error when extracting ejected singleton"
        )

        XCTAssertNoThrow(
            try injector.extractThrows(from: .factory) as TestService,
            "Factory should still be available after singleton ejection"
        )
    }

    func testRemovesOnlyFactory() {

        injector.inject(for: .both) { _ in TestService(id: .init()) }
        injector.eject(type: TestService.self, from: .factory)

        XCTAssertNoThrow(
            try injector.extractThrows(from: .singleton) as TestService,
            "Singleton should still be available after factory ejection"
        )

        XCTAssertThrowsError(
            try injector.extractThrows(from: .factory) as TestService,
            "Expected error when extracting ejected factory"
        )
    }

    func testRemovesBoth() {

        injector.inject(for: .both) { _ in TestService(id: .init()) }
        injector.eject(type: TestService.self, from: .both)

        XCTAssertThrowsError(
            try injector.extractThrows(from: .singleton) as TestService,
            "Expected error when extracting ejected singleton"
        )

        XCTAssertThrowsError(
            try injector.extractThrows(from: .factory) as TestService,
            "Expected error when extracting ejected factory"
        )
    }

    func testMissingSingletonThrowsError() {

        XCTAssertThrowsError(
            try injector.extractThrows(from: .singleton) as TestService,
            "Expected error when extracting unregistered singleton"
        ) { error in
            XCTAssertTrue(error is InjectorError)
        }
    }

    func testMissingFactoryThrowsError() {

        XCTAssertThrowsError(
            try injector.extractThrows(from: .factory) as TestService,
            "Expected error when extracting unregistered factory")
        { error in
            XCTAssertTrue(error is InjectorError)
        }
    }

    func testMissingBothThrowsError() {

        XCTAssertThrowsError(
            try injector.extractThrows(from: .both) as TestService,
            "Expected error when extracting unregistered type from both"
        ) { error in
            XCTAssertTrue(error is InjectorError)
        }
    }

    func testGetBothByDefault() {

        injector.inject(for: .both) { _ in TestService(id: .init()) }

        let extracted: TestService = injector.extract()
        XCTAssertNotNil(extracted, "Expected a valid instance using default extract() with .both")
    }
}
