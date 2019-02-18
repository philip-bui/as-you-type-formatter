# As You Type Formatter
[![CI Status](http://img.shields.io/travis/philip-bui/as-you-type-formatter.svg?style=flat)](https://travis-ci.org/philip-bui/as-you-type-formatter)
[![CodeCov](https://codecov.io/gh/philip-bui/as-you-type-formatter/branch/master/graph/badge.svg)](https://codecov.io/gh/philip-bui/as-you-type-formatter)
[![Version](https://img.shields.io/cocoapods/v/AsYouTypeFormatter.svg?style=flat)](http://cocoapods.org/pods/AsYouTypeFormatter)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AsYouTypeFormatter.svg?style=flat)](http://cocoapods.org/pods/AsYouTypeFormatter)
[![License](https://img.shields.io/cocoapods/l/AsYouTypeFormatter.svg?style=flat)](https://github.com/philip-bui/as-you-type-formatter/blob/master/LICENSE)

As You Type Formatter. By assuming text is always in a state of correctness, this library aims to make the minimal amount of state changes; only overriding the text change process when multiple text attributes are needed or existing text needs to be changed.

- Performant - `O(newText.count + nextWord.count)` worst case.
- Customization - Provide own character prefixes and formats.
- Suggestions - Detects when customized words has been selected, and methods to replace these words.
- Delegate - Methods to detect when different text formats are in use, and new suggestions are required.

## Requirements

- iOS 8.0+ / tvOS 9.0+ 
- Xcode 10.3+
- Swift 4.2+

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate AsYouTypeFormatter into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'AsYouTypeFormatter'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate AsYouTypeFormatter into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "philip-bui/as-you-type-formatter"
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but As You Type Formatter does support its use on supported platforms.

Once you have your Swift package set up, adding AsYouTypeFormatter as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/philip-bui/as-you-type-formatter.git", from: "1.0.0"))
]
```

## Usage

- Character Prefix. Default `#` `@`, words beginning with character prefixes use their assigned text attributes.

- Delimiters. Default ` ` `\n`, delimiters indicate when a word has ended to use normal text attributes.

AsYouTypeFormatter overrides two `UITextView` methods, `textView(shouldChangeTextIn:text:)` and `textViewDidChangeSelection()`. You can delegate your `UITextView` or call the methods within your own delegate.

```swift
import AsYouTypeFormatter

// AppDelegate.swift - Modify global defaults.
AsYouTypeFormatter.normalAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
AsYouTypeFormatter.tagAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
AsYouTypeFormatter.mentionAttributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 16)]

// ViewController.swift - Customize own character prefixes and formats.
private lazy var typeFormatter: AsYouTypeFormatter = {
    // Implicit return.
    AsYouTypeFormatter(delegate: self, attributes: [
	"#": [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)],
	nil: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    ])
}()
```
 
## Design Decisions

- Default Delimiters. The default delimiters are ` ` and `\n`. This means that other special characters `?` do not delimit a word, but delegate methods can customize this.
- No suggestion support for `UITextField`. Suggestion support replies on detecting when the user selects a new word, and `UITextFieldDelegate` doesn't expose text selection events.
- Link supports. Enabling selectable and clickable text is not very practical.
- On multi-text selection, suggestions are disabled. The assumption is that text is usually selected when the user wants to copy and paste.

## License

AsYouTypeFormatter is available under the MIT license. [See LICENSE](https://github.com/philip-bui/as-you-type-formatter/blob/master/LICENSE) for details.
