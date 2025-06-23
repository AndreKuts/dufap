//
//  AsyncDependencyInjectorTests.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import XCTest
import Dufap

class AsyncDependencyInjectorTests: XCTestCase {

    struct TestService: Equatable {
        let id: Int
    }

    func test_SingletonInjectionAndExtraction() async {
        let injector = AsyncDependencyInjector()
        let expected = TestService(id: 42)
        await injector.inject(for: .singleton) { _ in expected }
        let actual: TestService = await injector.extract(from: .singleton)

        XCTAssertEqual(actual, expected)
    }

    func test_FactoryInjectionAndExtraction() async {
        let injector = AsyncDependencyInjector()
        await injector.inject(for: .factory) { _ in TestService(id: Int.random(in: 1...1000)) }
        let first: TestService = await injector.extract(from: .factory)
        let second: TestService = await injector.extract(from: .factory)

        XCTAssertNotEqual(first.id, second.id, "Factory should return different instances")
    }

    func test_BothInjectionShouldReturnSingletonFirst() async {
        let injector = AsyncDependencyInjector()
        let expected = TestService(id: 777)
        await injector.inject(for: .both) { _ in expected }
        let actual: TestService = await injector.extract(from: .both)

        XCTAssertEqual(actual, expected)
    }

    func test_ExtractOptionalFoundAndMissing() async {
        let injector = AsyncDependencyInjector()
        await injector.inject(for: .singleton) { _ in TestService(id: 99) }
        let found: TestService? = await injector.extractOptional(from: .singleton)

        XCTAssertEqual(found?.id, 99)

        let notFound: String? = await injector.extractOptional(from: .singleton)

        XCTAssertNil(notFound)
    }

    func test_EjectRemovesValue() async {
        let injector = AsyncDependencyInjector()
        await injector.inject(for: .singleton) { _ in TestService(id: 123) }
        await injector.eject(type: TestService.self, from: .singleton)
        let result: TestService? = await injector.extractOptional(from: .singleton)

        XCTAssertNil(result, "Ejected dependency should no longer be found")
    }

    func test_ExtractThrows_success() async throws {
        let injector = AsyncDependencyInjector()
        await injector.inject(for: .singleton) { _ in TestService(id: 88) }
        let value: TestService = try await injector.extractThrows(from: .singleton)

        XCTAssertEqual(value.id, 88)
    }

    func test_ExtractThrows_failure() async {
        let injector = AsyncDependencyInjector()

        do {
            let _: TestService = try await injector.extractThrows(from: .singleton)
            XCTFail("Should have thrown error for unregistered type")
        } catch let error as InjectorError {
            guard case .typeNotFound(let message) = error else {
                return XCTFail("Unexpected error: \(error)")
            }

            XCTAssertTrue(message?.contains("TestService") == true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
