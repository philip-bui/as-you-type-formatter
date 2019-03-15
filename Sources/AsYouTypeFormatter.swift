//
//  AsYouTypeFormatter.swift
//  AsYouTypeFormatter
//
//  Created by Philip on 17/11/18.
//  Copyright © 2018 Next Generation. All rights reserved.
//

import UIKit

public class AsYouTypeFormatter: NSObject, UITextViewDelegate {
    public weak var delegate: AsYouTypeFormatterDelegate?
    private let attributes: [Character?: [NSAttributedString.Key: Any]]
    private var character: Character? {
        didSet {
            guard character != oldValue else {
                return
            }
            delegate?.typeFormatter(self, characterPrefixDidChange: character)
        }
    }
    private var recommendationRange: NSRange? {
        didSet {
            guard let recommendationRange = recommendationRange else {
                return
            }
            delegate?.typeFormatter(self, recommendationRangeDidChange: recommendationRange)
        }
    }
    public func recommendedText(text: String, recommendationRange range: NSRange) -> Substring? {
        guard let unicodeRange = Range(range, in: text) else {
            return nil
        }
        return text[unicodeRange]
    }

    public static var normalAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    public static var tagAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
    public static var mentionAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 16)]
    public static var alphabetAllowed: CharacterSet = CharacterSet.letters.subtracting(CharacterSet.nonBaseCharacters).union(CharacterSet(charactersIn: "0123456789"))
    private var defaultAttributes: [NSAttributedString.Key: Any] {
        return attributes[nil] ?? AsYouTypeFormatter.normalAttributes
    }

    public init(textView: UITextView? = nil, delegate: AsYouTypeFormatterDelegate? = nil, attributes: [Character?: [NSAttributedString.Key: Any]] = [
            "#": AsYouTypeFormatter.tagAttributes,
            "@": AsYouTypeFormatter.mentionAttributes,
            nil: AsYouTypeFormatter.normalAttributes
        ]) {
        self.delegate = delegate
        self.attributes = attributes
        guard attributes[nil] != nil else {
            fatalError("No default textAttributes found")
        }
        super.init()
        textView?.delegate = self
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Range is UTF16, create UnicodeScalar Range to match text.
        guard let unicodeRange = Range(range, in: textView.text) else {
            return true
        }
        let isTypingAtEnd = range.location + range.length == textView.text.utf16.count ||
            (range.location + range.length > textView.text.utf16.count && !textView.text[textView.text.index(unicodeRange.upperBound, offsetBy: 1)].isUTF16)
        let typingAttributes = textView.typingAttributes
        // If prev word ends with emoji, use default attributes instead of Apple Emoji Font.
        let prevWordAttributes = range.location == 0 ||
            !textView.text[textView.text.index(unicodeRange.lowerBound, offsetBy: -1)].isUTF16
            ? defaultAttributes
            : textView.textStorage.attributes(at: range.location - 1, effectiveRange: nil)
        let nextWordAttributes = isTypingAtEnd
            ? prevWordAttributes
            : textView.textStorage.attributes(at: range.location + range.length, effectiveRange: nil)
        if !text.isEmpty {
            // TODO: Merge two loops together for performance.
            // If typingAttributes == nextWordAttributes, and no other attributes besides typingAttributes, let textView handle change.
            if attributes(isEqual: typingAttributes, nextWordAttributes), !text.contains(where: { c -> Bool in
                !attributes(isEqual: attributes(fromCharacter: c), typingAttributes)
            }) {
                return true
            }
            // If firstChar is character prefix or delimiter, (isTypingAtEnd || firstCharAttributes == nextWordAttributes), and no other attributes besides firstCharAttributes, update typingAttributes and let textView handle change.
            if let firstCharAttributes = attributes(fromCharacter: text.first),
                (isTypingAtEnd || attributes(isEqual: firstCharAttributes, nextWordAttributes)),
                !text.contains(where: { c -> Bool in
                    !attributes(isEqual: attributes(fromCharacter: c), firstCharAttributes)
                }) {
                firstCharAttributes.forEach { k, v in
                    textView.typingAttributes[k] = v
                }
                return true
            }
        }
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(textView.typingAttributes, range: NSRange(text.startIndex..<text.endIndex, in: text))
        var textAttributes = prevWordAttributes
        var attributesIndex = 0
        // Starting with prevWordAttributes, iterate through characters finding and applying new textAttributes as required.
        for (i, character) in text.enumerated() {
            if let characterAttributes = attributes(fromCharacter: character) {
                attributedText.addAttributes(textAttributes, range: NSRange(text.index(text.startIndex, offsetBy: attributesIndex)..<text.index(text.startIndex, offsetBy: i), in: text))
                // Mark this index as starting point for new textAttributes.
                textAttributes = characterAttributes
                attributesIndex = i
            }
        }
        attributedText.addAttributes(textAttributes, range: NSRange(text.index(text.startIndex, offsetBy: attributesIndex)..<text.endIndex, in: text))
        // If nextWordAttributes doesn't match with current textAttributes, apply textAttributes to nextWord.
        if !isTypingAtEnd, !attributes(isEqual: textAttributes, nextWordAttributes) {
            let unicodeRangeEnd = unicodeRange.upperBound
            let firstWord = textView.text?[unicodeRangeEnd..<textView.text.endIndex].enumerated().first { _, character -> Bool in
                attributes(fromCharacter: character) != nil
            }
            let range: NSRange
            if let firstWord = firstWord {
                range = NSRange(unicodeRangeEnd..<textView.text.index(unicodeRangeEnd, offsetBy: firstWord.offset), in: textView.text)
            } else {
                range = NSRange(unicodeRangeEnd..<textView.text.endIndex, in: textView.text)
            }
            textView.textStorage.addAttributes(textAttributes, range: range)
        }
        textView.textStorage.replaceCharacters(in: range, with: attributedText)
        // Assign new range at replacedText location + newText count.
        textView.selectedRange = NSRange(location: range.location + text.utf16.count, length: 0)
        return false
    }

    private func attributes(isEqual lhs: [NSAttributedString.Key: Any]?, _ rhs: [NSAttributedString.Key: Any]?) -> Bool {
        guard let lhs = lhs else {
            return rhs == nil
        }
        guard let rhs = rhs else {
            return false
        }
        if let delegate = delegate {
            return delegate.typeFormatter(self, attributesIsEqual: lhs, rhs)
        }
        return lhs[NSAttributedString.Key.font] as? UIFont == rhs[NSAttributedString.Key.font] as? UIFont
    }

    public func typeFormatter(attributesIsEqual lhs: [NSAttributedString.Key: Any], _ rhs: [NSAttributedString.Key: Any]) -> Bool {
        return lhs[NSAttributedString.Key.font] as? UIFont == rhs[NSAttributedString.Key.font] as? UIFont
    }

    private func attributes(fromCharacter character: Character?) -> [NSAttributedString.Key: Any]? {
        guard let character = character else {
            return nil
        }
        guard let textAttributes = attributes[character] else {
            return isDelimiter(character) ? attributes[nil] : nil
        }
        return textAttributes
    }

    private func isDelimiter(_ character: Character) -> Bool {
        if let delegate = delegate {
            return delegate.typeFormatter(self, isDelimiter: character)
        }
        return typeFormatter(isDelimiter: character)
    }

    public func typeFormatter(isDelimiter character: Character) -> Bool {
        return !character.isUTF16 || character.unicodeScalars.contains { unicodeScalar in
            !AsYouTypeFormatter.alphabetAllowed.contains(unicodeScalar)
        }
    }

    private func characterSetNil() {
        // NOTE: didSet does not invoke on nil being set on optional properties.
        if character != nil {
            delegate?.typeFormatter(self, characterPrefixDidChange: nil)
        }
        character = nil
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        // If user is selecting multiple characters, don't provide suggestions.
        guard textView.selectedRange.length == 0 else {
            characterSetNil()
            return
        }
        // Find first delimiter, or character prefix. If not found, return nil.
        guard let unicodeRange = Range(textView.selectedRange, in: textView.text),
            let firstWord = textView.text[textView.text.startIndex..<unicodeRange.lowerBound].reversed()
                .enumerated()
                .first(where: { _, character -> Bool in
                attributes(fromCharacter: character) != nil
            }) else {
            characterSetNil()
            return
        }
        // If not delimiter, we provide a recommendation range.
        guard attributes[firstWord.element] != nil else {
            characterSetNil()
            return
        }
        character = firstWord.element
        let firstWordIndex = textView.text.index(unicodeRange.lowerBound, offsetBy: -firstWord.offset)
        guard let secondWord = textView.text[firstWordIndex..<textView.text.endIndex].enumerated().first(where: { _, c -> Bool in
            attributes(fromCharacter: c) != nil
        }) else {
            // No delimiter or new word found.
            recommendationRange = NSRange(firstWordIndex..<textView.text.endIndex, in: textView.text)
            return
        }
        recommendationRange = NSRange(firstWordIndex..<textView.text.index(firstWordIndex, offsetBy: secondWord.offset), in: textView.text)
    }

    public func typeFormatter(_ textView: UITextView, replaceRecommendationRange recommendationRange: NSRange, withText text: String) {
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(textView.typingAttributes, range: NSRange(location: 0, length: text.utf16.count))
        textView.textStorage.replaceCharacters(in: recommendationRange, with: attributedText)
        // Assign new range at replacedText location + newText count.
        textView.selectedRange = NSRange(location: recommendationRange.location + text.utf16.count, length: 0)
    }
}

public protocol AsYouTypeFormatterDelegate: AnyObject {
    func typeFormatter(_ formatter: AsYouTypeFormatter, characterPrefixDidChange character: Character?)
    func typeFormatter(_ formatter: AsYouTypeFormatter, recommendationRangeDidChange range: NSRange)
    func typeFormatter(_ formatter: AsYouTypeFormatter, isDelimiter character: Character) -> Bool
    func typeFormatter(_ formatter: AsYouTypeFormatter, attributesIsEqual lhs: [NSAttributedString.Key: Any], _ rhs: [NSAttributedString.Key: Any]) -> Bool
}
