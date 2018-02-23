# UnReswift

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Redux style reducers, as are used in the ReSwift library and others, are a mostly useless artifact emanating from Javascript's lack of static typing. Programming elements consisting of a large switch statement applied to a bunch of constant strings are not necessary in a static language like Swift. From my experience, Reducers look and sound cool in theory, they have that Functional Programming buzz around them, but in practice it's usually just an additional element of indirection cluttering your project.

While keeping the familiar Store/Dispatch based interface, UnReswift removes reducers altogether and move the act of reducing your `Store`'s state to the `Action`s themselves.

The `Action` Protocol is very simple:

```
public protocol Action: AnyAction {
    associatedtype ActionStateType: StateType

    func reduce(_ state: ActionStateType) -> ActionStateType
}
```

Notice the `reduce` function requirement. Traditionally, the store state modification routine happens inside a switch case of one of your reducers. In UnReswift, that routine is the `reduce` function of an `Action` itself.

Here is an example applied to the common counter problem:

```
struct AppState: StateType {
    var counter: Int = 0
}

struct CounterActionIncrease: Action {
    typealias ActionStateType = AppState

    func reduce(_ state: AppState) -> AppState {
        var state = state
        state.counter += 1
        return state
    }
}

let store = Store(state: AppState())

store.dispatch(CounterActionIncrease())
```

Very simple and hopefully familiar for most people with a Redux/ReSwift background.


## Installation

### CocoaPods

Currently not supported.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate UnReswift into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "jordanebelanger/UnReswift"
```


## Author

Jordane Belanger


## License

UnReswift is available under the MIT license. See the LICENSE file for more info.
