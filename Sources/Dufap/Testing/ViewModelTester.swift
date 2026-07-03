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

import Foundation

@MainActor
public final class ViewModelTester<V: ViewModelProtocol> {

    public let viewModel: V
    public let erasedViewModel: AnyViewModel<V.S, V.A>

    public init(_ viewModel: V) {
        self.viewModel = viewModel
        self.erasedViewModel = AnyViewModel(viewModel)
    }

    @discardableResult
    public func send(_ action: V.A) async -> V.S {
        erasedViewModel.trigger(action: action)
        await Task.yield()
        return erasedViewModel.state
    }

    public var state: V.S {
        erasedViewModel.state
    }

    public func stateMatches(_ predicate: (V.S) -> Bool) -> Bool {
        predicate(erasedViewModel.state)
    }
}
