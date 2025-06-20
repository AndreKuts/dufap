//
//  InjectedPropertyWrapperTests.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Dufap
import XCTest

fileprivate struct MockService: Equatable { }

final class InjectedPropertyWrapperTests: XCTestCase {

    func test_InjectedResolvesValue() {

        struct TestStruct {
            @Injected var service: MockService
        }

        let injector = DependencyInjector()
        injector.inject(for: .both) { _ in MockService() }
        InjectorRegistry.register(injector)

        var instance = TestStruct()

        XCTAssertEqual(instance.service, MockService())
    }

    func test_InjectedOptional() {

        struct TestStruct {
            @Injected var service: MockService?
        }

        let injector = DependencyInjector()
        injector.inject(for: .both) { _ in MockService() }
        InjectorRegistry.register(injector)

        var instance = TestStruct()

        XCTAssertNotNil(instance.service)
    }
}
