#if canImport(DufapMacros)

import DufapMacros
import MacroTesting
import XCTest

final class DufapTests: XCTestCase {

    override func invokeTest() {
        withMacroTesting(
            macros: [
                ViewModelMacro.self,
                ViewStateActionMacro.self,
            ]
        ) {
            super.invokeTest()
        }
    }

    func testViewModelMacro() throws {
        assertMacro {
            """
            struct TestState: StateProtocol {}
            enum TestAction: ActionProtocol {}
            @ViewModel
            class TestViewModel {
                let state = TestState()
                func trigger(action: TestAction) { }
            }
            @ViewWith(state: TestState, action: TestAction)
            struct TestView: View {
                var body: some View {
                    Text("TestView")
                }
            }
            """
        } expansion: {
            """
            struct TestState: StateProtocol {}
            enum TestAction: ActionProtocol {}
            class TestViewModel {
                @Published
                let state = TestState()
                func trigger(action: TestAction) { }

                var updateStateQueue = DispatchQueue(label: "com.dufap.state.update.testviewmodel")
            }
            @ViewWith(state: TestState, action: TestAction)
            struct TestView: View {
                var body: some View {
                    Text("TestView")
                }
            }

            extension TestViewModel: ViewModelProtocol {
            }
            """
        }
    }

}

#endif
