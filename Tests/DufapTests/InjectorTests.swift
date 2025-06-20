//
//  InjectorTests.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import XCTest
import Dufap

struct TestService: Equatable {
    let id: UUID
}

class InjectorTests: XCTestCase {

    var injector: (any Injector)!

    override func setUp() {
        super.setUp()
        injector = DependencyInjector()
    }

    override func tearDown() {
        injector = nil
        super.tearDown()
    }

    func test_ExtractReturnsSameInstance() {

        let service = TestService(id: .init())
        injector.inject(for: .singleton) { _ in service }

        let extracted: TestService = injector.extract(from: .singleton)
        XCTAssertEqual(extracted, service, "Singleton extract should return the same instance that was injected")
    }

    func test_ExtractReturnsNewInstanceEachTime() {

        injector.inject(for: .factory) { _ in TestService(id: .init()) }

        let a: TestService = injector.extract(from: .factory)
        let b: TestService = injector.extract(from: .factory)

        XCTAssertNotEqual(a, b, "Factory extract should return a new instance on each call")
    }

    func test_ExtractSingletonThenFactory() {

        let uuid = UUID()
        injector.inject(for: .both) { _ in TestService(id: uuid) }

        let singleton: TestService = injector.extract(from: .singleton)
        let factory: TestService = injector.extract(from: .factory)

        XCTAssertEqual(singleton.id, uuid, "Singleton ID should match injected UUID")
        XCTAssertEqual(factory.id, uuid, "Factory ID should match injected UUID")
    }

    func test_RemovesOnlySingleton() {

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

    func test_RemovesOnlyFactory() {

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

    func test_RemovesBoth() {

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

    func test_MissingSingletonThrowsError() {

        XCTAssertThrowsError(
            try injector.extractThrows(from: .singleton) as TestService,
            "Expected error when extracting unregistered singleton"
        ) { error in
            XCTAssertTrue(error is InjectorError)
        }
    }

    func test_MissingFactoryThrowsError() {

        XCTAssertThrowsError(
            try injector.extractThrows(from: .factory) as TestService,
            "Expected error when extracting unregistered factory")
        { error in
            XCTAssertTrue(error is InjectorError)
        }
    }

    func test_MissingBothThrowsError() {

        XCTAssertThrowsError(
            try injector.extractThrows(from: .both) as TestService,
            "Expected error when extracting unregistered type from both"
        ) { error in
            XCTAssertTrue(error is InjectorError)
        }
    }

    func test_GetBothByDefault() {

        injector.inject(for: .both) { _ in TestService(id: .init()) }

        let extracted: TestService = injector.extract()
        XCTAssertNotNil(extracted, "Expected a valid instance using default extract() with .both")
    }
}
