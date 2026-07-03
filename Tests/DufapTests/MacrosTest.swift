//
//  Copyright 2025 Andrew Kuts
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import SwiftSyntaxMacrosTestSupport
import DufapMacros

class MacrosTest: XCTestCase {

    private let myAction: String = """
    @Action
    enum MyAction {
        case start
        case updateIncr(incr: Int)
        case viewAll
    }
    """

    private let myActionExpansion = """
    enum MyAction {
        case start
        case updateIncr(incr: Int)
        case viewAll

        var cancelID: String {
            switch self {
            case .start:
                return "cancel_start"
            case .updateIncr:
                return "cancel_updateIncr"
            case .viewAll:
                return "cancel_viewAll"
            }
        }

        enum SyncAction: SyncActionProtocol {

            init?(from original: any ActionProtocol) {
                guard let original = original as? MyAction else {
                    return nil
                }
                switch original {
                    case .start:
                    self = .start
                case .updateIncr(let incr):
                    self = .updateIncr(incr: incr)
                case .viewAll:
                    self = .viewAll

                }
            }

            case start
            case updateIncr(incr: Int)
            case viewAll
        }

        typealias SA = SyncAction

        typealias AA = Never
    }

    extension MyAction: ActionProtocol {
    }
    """

    private let myState: String = "struct MyState: StateProtocol { }"

    private let myViewModel: String = """
    @MainActor
    @ViewModel(action: MyAction.self)
    class MyViewModel {

        var state: MyState

        init(state: MyState = MyState()) {
            self.state = state
        }

        func trigger(action: MyAction.SA) {}

        func triggerAsync(action: MyAction.AA) async {}
    }
    """

    private let myViewModelExpansion: String = """
    @MainActor
    class MyViewModel {
        @Published

        var state: MyState

        init(state: MyState = MyState()) {
            self.state = state
        }

        func trigger(action: MyAction.SA) {}

        func triggerAsync(action: MyAction.AA) async {}

        typealias A = MyAction

        var bag: CancellableBag = CancellableBag()

        var statePublisher: Published<S>.Publisher { $state }
    }

    extension MyViewModel: ViewModelProtocol {
    }
    """

    private let attributedViewModel: String = """
    @available(iOS 15, *)
    @MainActor
    @ViewModel(action: MyAction.self)
    class AttributedViewModel {

        var state: MyState

        init(state: MyState = MyState()) {
            self.state = state
        }

        func trigger(action: MyAction.SA) {}

        func triggerAsync(action: MyAction.AA) async {}
    }
    """

    private let attributedViewModelExpansion: String = """
    @available(iOS 15, *)
    @MainActor
    class AttributedViewModel {
        @Published

        var state: MyState

        init(state: MyState = MyState()) {
            self.state = state
        }

        func trigger(action: MyAction.SA) {}

        func triggerAsync(action: MyAction.AA) async {}

        typealias A = MyAction

        var bag: CancellableBag = CancellableBag()

        var statePublisher: Published<S>.Publisher { $state }
    }

    extension AttributedViewModel: ViewModelProtocol {
    }
    """

    private let pathMacro: String =
    """
    @Pathable
    enum MyPath {
        case firstScreen
        case secondScreen
    }
    """

    private let explicitCasePathMacro: String =
    """
    @Pathable(.case)
    enum MyCasePath {
        case firstScreen
        case secondScreen
    }
    """

    private let explicitCasePathMacroExpansion: String =
    """
    enum MyCasePath {
        case firstScreen
        case secondScreen
    }

    extension MyCasePath: Hashable, Equatable, Identifiable {

        static func == (lhs: MyCasePath, rhs: MyCasePath) -> Bool {
            lhs.index == rhs.index
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
        }

        var index: Int {
            switch self {
            case .firstScreen:
                return 0
            case .secondScreen:
                return 1
            }
        }

        var id: Int {
            index
        }

    }
    """

    private let valuePathMacro: String =
    """
    @Pathable(.value)
    enum MyValuePath {
        case firstScreen
        case details(id: String)
    }
    """

    private let valuePathMacroExpansion: String =
    """
    enum MyValuePath {
        case firstScreen
        case details(id: String)
    }

    extension MyValuePath: Hashable, Equatable, Identifiable {

        var id: Self {
            self
        }

    }
    """

    private let invalidPathMacro: String =
    """
    @Pathable(.id)
    enum MyInvalidPath {
        case firstScreen
    }
    """

    private let invalidPathMacroExpansion: String =
    """
    enum MyInvalidPath {
        case firstScreen
    }
    """

    private let invalidViewModelMissingAction: String =
    """
    @MainActor
    @ViewModel
    final class InvalidViewModel {
        var state: MyState
    }
    """

    private let invalidViewModelMissingActionExpansion: String =
    """
    @MainActor
    final class InvalidViewModel {
        var state: MyState
    }
    """

    private let invalidViewModelActionWithoutSelf: String =
    """
    @MainActor
    @ViewModel(action: MyAction)
    final class InvalidViewModel {
        var state: MyState
    }
    """

    private let invalidViewModelActionWithoutSelfExpansion: String =
    """
    @MainActor
    final class InvalidViewModel {
        var state: MyState
    }
    """

    private let invalidActionOnClass: String =
    """
    @Action
    final class InvalidAction {
    }
    """

    private let invalidActionOnClassExpansion: String =
    """
    final class InvalidAction {
    }
    """

    private let invalidViewWithMissingArguments: String =
    """
    @ViewWith
    struct InvalidView: View {
    }
    """

    private let invalidViewWithMissingArgumentsExpansion: String =
    """
    struct InvalidView: View {
    }
    """

    private let pathMacroExpansion: String =
    """
    enum MyPath {
        case firstScreen
        case secondScreen
    }

    extension MyPath: Hashable, Equatable, Identifiable {

        static func == (lhs: MyPath, rhs: MyPath) -> Bool {
            lhs.index == rhs.index
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
        }

        var index: Int {
            switch self {
            case .firstScreen:
                return 0
            case .secondScreen:
                return 1
            }
        }

        var id: Int {
            index
        }

    }
    """

    private let viewMacro: String =
    """
    @ViewMacro(state: MyState.self, action: MyActionView.self)
    struct SomeView: View {

        @ObservedObject
        var viewModel: AnyViewModel<MyState, MyActionView>

        init(_ viewModel: AnyViewModel<MyState, MyActionView>) {
            self.viewModel = viewModel
        }
    }
    """

    private let viewMacroExpansion: String =
    """
    struct SomeView: View {

        @ObservedObject
        var viewModel: AnyViewModel<MyState, MyActionView>

        init(_ viewModel: AnyViewModel<MyState, MyActionView>) {
            self.viewModel = viewModel
        }
    }

    extension SomeView: ViewProtocol {
    }
    """

    func test_ActionMacro() {
        assertMacroExpansion(
            myAction,
            expandedSource: myActionExpansion,
            macros: ["Action": ActionMacro.self]
        )
    }

    func test_ViewModelMacro() {
        assertMacroExpansion(
            myViewModel,
            expandedSource: myViewModelExpansion,
            macros: ["ViewModel": ViewModelMacro.self]
        )
    }

    func test_ViewModelMacroReadsItsOwnArgumentsWhenOtherAttributesComeFirst() {
        assertMacroExpansion(
            attributedViewModel,
            expandedSource: attributedViewModelExpansion,
            macros: ["ViewModel": ViewModelMacro.self]
        )
    }

    func test_PathMacro() {
        assertMacroExpansion(
            pathMacro,
            expandedSource: pathMacroExpansion,
            macros: ["Pathable": PathMacro.self]
        )
    }

    func test_PathMacroExplicitCaseIdentity() {
        assertMacroExpansion(
            explicitCasePathMacro,
            expandedSource: explicitCasePathMacroExpansion,
            macros: ["Pathable": PathMacro.self]
        )
    }

    func test_PathMacroValueIdentity() {
        assertMacroExpansion(
            valuePathMacro,
            expandedSource: valuePathMacroExpansion,
            macros: ["Pathable": PathMacro.self]
        )
    }

    func test_PathMacroInvalidIdentityModeEmitsDiagnostic() {
        assertMacroExpansion(
            invalidPathMacro,
            expandedSource: invalidPathMacroExpansion,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@Pathable` supports `.case` and `.value` identity modes.",
                    line: 1,
                    column: 1
                )
            ],
            macros: ["Pathable": PathMacro.self]
        )
    }

    func test_ViewModelMacroMissingActionEmitsDiagnostic() {
        assertMacroExpansion(
            invalidViewModelMissingAction,
            expandedSource: invalidViewModelMissingActionExpansion,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@ViewModel` requires an action type. Use `@ViewModel(action: MyAction.self)`.",
                    line: 2,
                    column: 1
                )
            ],
            macros: ["ViewModel": ViewModelMacro.self]
        )
    }

    func test_ViewModelMacroActionWithoutSelfEmitsDiagnostic() {
        assertMacroExpansion(
            invalidViewModelActionWithoutSelf,
            expandedSource: invalidViewModelActionWithoutSelfExpansion,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@ViewModel` action argument must use `.self`. Use `@ViewModel(action: MyAction.self)`.",
                    line: 2,
                    column: 12
                )
            ],
            macros: ["ViewModel": ViewModelMacro.self]
        )
    }

    func test_ActionMacroOnClassEmitsDiagnostic() {
        assertMacroExpansion(
            invalidActionOnClass,
            expandedSource: invalidActionOnClassExpansion,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@Action` can only be applied to an enum. Use `@Action enum MyAction { ... }`.",
                    line: 1,
                    column: 1
                )
            ],
            macros: ["Action": ActionMacro.self]
        )
    }

    func test_ViewWithMacroMissingArgumentsEmitsDiagnostic() {
        assertMacroExpansion(
            invalidViewWithMissingArguments,
            expandedSource: invalidViewWithMissingArgumentsExpansion,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@ViewWith` requires state and action types. Use `@ViewWith(state: MyState.self, action: MyAction.self)`.",
                    line: 1,
                    column: 1
                )
            ],
            macros: ["ViewWith": ViewStateActionMacro.self]
        )
    }

    func test_ViewStateActionMacro() {
        assertMacroExpansion(
            viewMacro,
            expandedSource: viewMacroExpansion,
            macros: ["ViewMacro": ViewStateActionMacro.self]
        )
    }
}
