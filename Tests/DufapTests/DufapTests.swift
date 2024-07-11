import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DufapMacros)
import DufapMacros

let testMacros: [String: Macro.Type] = [
    "viewStateAction": ViewStateActionMacro.self,
]

final class DufapTests: XCTestCase {
    func testMacro() throws {
    }
}

#endif
