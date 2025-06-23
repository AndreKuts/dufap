//
//  MacrosTest.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import MacroTesting
import SwiftSyntaxMacros
import XCTest
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

        var updateStateQueue = DispatchQueue(label: "com.dufap.state.update.myviewmodel")

        var statePublisher: Published<S>.Publisher { $state }

        deinit { 
            bag.cancelAll()
        }
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

    override func invokeTest() {
        withMacroTesting(
            macros: [
                "Action": ActionMacro.self,
                "ViewModel": ViewModelMacro.self,
                "ViewMacro": ViewStateActionMacro.self,
                "Pathable": PathMacro.self,
            ]
        ) {
            super.invokeTest()
        }
    }

    func test_ActionMacro() {
        assertMacro {
            myAction
        } expansion: {
            self.myActionExpansion
        }
    }

    func test_ViewModelMacro() {
        assertMacro {
            myViewModel
        } expansion: {
            self.myViewModelExpansion
        }
    }

    func test_PathMacro() {
        assertMacro {
            pathMacro
        } expansion: {
            self.pathMacroExpansion
        }
    }

    func test_ViewStateActionMacro() {
        assertMacro {
            viewMacro
        } expansion: {
            self.viewMacroExpansion
        }
    }
}
