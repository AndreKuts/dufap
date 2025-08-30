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

    private let pathMacro: String =
    """
    @Pathable
    enum MyPath {
        case firstScreen
        case secondScreen
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

    func test_PathMacro() {
        assertMacroExpansion(
            pathMacro,
            expandedSource: pathMacroExpansion,
            macros: ["Pathable": PathMacro.self]
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
