#  Dufap is an Xcode Package for Architecture Patterns.

### D - Declarative
### U - Unidirectional
### F - Functional
### A - Architectural
### P - Pattern


# Overview
This Xcode package implements the View-Action-State MVVM architectural pattern for iOS applications, designed to streamline and enhance the management of user interactions and state changes within the app. 
The View-Action-State MVVM pattern introduces a clear separation between the view's actions and its state, providing a more structured approach to handling user interactions and updating the UI. 

This approach is based on a combination of two patterns: Redux and MVVM.

Inspired by these resources: 

### ViewState MVVM 
- https://github.com/quickbirdeng/SwiftUI-Architectures
- https://quickbirdstudios.com/blog/swiftui-architecture-redux-mvvm/
### TCA
- https://github.com/pointfreeco/swift-composable-architecture
- https://www.pointfree.co/collections/composable-architecture


## Visual diagrams:

![Dufap drawio](https://github.com/user-attachments/assets/45a8cdfa-da99-4b98-874d-5e4c917839ed)


## Key Concepts
  - **Action**: Represents user interactions or events that the ViewModel needs to handle. Actions are sent from the View to the ViewModel to initiate data processing or state changes.
  - **State**: A structure that encapsulates the state of the View. The ViewModel updates the State based on the actions received and the current state.
  - **ViewModel**: The intermediary between the Model and the View. It processes user actions, interacts with the Model, and updates the State. The ViewModel exposes actions that the View can invoke and publishes state changes.
  - **View**: The user interface layer that displays the data and captures user interactions. The view binds to the ViewModel and updates itself based on the State changes.
  - **Model**: The data layer of the application, is responsible for managing the data and business logic. It handles data retrieval, persistence, and any other data-related operations.

## Benefits of View-Action-State MVVM
  - Clear Separation of Concerns: By isolating actions and state, this pattern ensures a clean separation between user interactions and UI state, enhancing modularity and maintainability.
  - Enhanced State Management: The ViewState pattern provides a clear and consistent way to manage UI state, making it easier to understand and debug state changes.
  - Improved Testability: Actions and state updates can be tested independently, ensuring that the ViewModel behaves correctly under different scenarios.
  - Scalable Architecture: This pattern is suitable for applications of all sizes, from simple apps to complex, large-scale projects, providing a scalable and maintainable architecture.

## Features

- State updates should only occur in the ViewModel layer as the View layer only has visibility for reading State.
- Receiving state changes occurs on the Main thread by default, so it's safe to update from any thread.
- Macros are useful for reducing the number of lines of code.
- Protected state the updates.

## Installation

### Swift Package Manager
You can add the package using the Swift Package Manager.


## Examples: 

```swift
// 1. Import Packages
import Dufap
import SwiftUI

// 2. Define State
struct State: StateProtocol {
    var number = 0
    var textInput = ""
}

// 3. Define Actions
enum Action: ActionProtocol {
    case incrementNumber
    case updateTextField(String)
}

// 4. Define View using macro
@ViewWith(state: State, action: Action)
struct ContentView: View {

    var body: some View {
        VStack {
            Text("Hello, world!")
            Text("Incrementing view \(viewModel.number)")
            TextField("TextField", text: .init(get: { viewModel.textInput }, set: { viewModel.trigger(action: .updateTextField($0)) } ))
        }
        .padding()
        .onAppear(perform: testMultiThread)
    }

    private func testMultiThread() {
        for number in 1...3 {
            print("Run test number \(number)")
            DispatchQueue.global().async {
                for _ in 0..<1000000 {
                    viewModel.trigger(action: .incrementNumber)
                }
                print("Finished test number \(number)")
            }
        }
    }
}

// 5. Define ViewModel using macro
@ViewModel
class ContentViewModel {

    // 6. define a state
    var state: State

    init(state: State = State()) {
        self.state = state
    }

    // 7. Define action handler function
    func trigger(action: Action) {

        // 8. handle actions
        switch action {
        case .incrementNumber:

            // 9. Update state
            updateState { $0.number += 1 }

            // This state update method is not protected if the actions co-occur from different threads
            // state.number += 1

        case .updateTextField(let newText):
            updateState { $0.textInput = newText }
        }
    }
}

// 10. App usage
@main
struct TMPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel())
        }
    }
}
