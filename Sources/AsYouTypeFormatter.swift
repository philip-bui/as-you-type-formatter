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

    public static var normalAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    public static var tagAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
    public static var mentionAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 16)]

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
        let isTypingAtEnd = range.location + range.length == textView.text.count
        let typingAttributes = textView.typingAttributes
        guard let prevWordAttributes = range.location == 0
            ? attributes[nil]
            : textView.attributedText.attributes(at: range.location - 1, effectiveRange: nil) else {
                fatalError("Invalid prevWordAttributes")
        }
        let nextWordAttributes = isTypingAtEnd
            ? prevWordAttributes
            : textView.attributedText.attributes(at: range.location + range.length, effectiveRange: nil)
        if !text.isEmpty {
            // TODO: Merge two loops together for performance.
            // If typingAttributes == nextWordAttributes, and no other attributes besides typingAttributes, let textView handle change.
            if attributes(isEqual: typingAttributes, nextWordAttributes), !text.contains(where: { c -> Bool in
                !attributes(isEqual: attributes(fromCharacter: c), typingAttributes)
            }) {
                return true
            }
            // If firstChar is character prefix or delimiter, (isTypingAtEnd || firstCharAttributes == nextWordAttributes), and no other attributes besides firstCharAttributes, merge typingAttributes and let textView handle change.
            if let firstCharAttributes = attributes(fromCharacter: textView.text.first),
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
        attributedText.addAttributes(textView.typingAttributes, range: NSRange(location: 0, length: text.count))
        var textAttributes = prevWordAttributes
        var attributesIndex = 0
        // Starting with prevWordAttributes, iterate through characters finding and applying new textAttributes as required.
        for (i, character) in text.enumerated() {
            if let characterAttributes = attributes(fromCharacter: character) {
                attributedText.addAttributes(textAttributes, range: NSRange(location: attributesIndex, length: i - attributesIndex))
                // Mark this index as starting point for new textAttributes.
                textAttributes = characterAttributes
                attributesIndex = i
            }
        }
        attributedText.addAttributes(textAttributes, range: NSRange(location: attributesIndex, length: text.count - attributesIndex))
        guard let mutableText = textView.attributedText.mutableCopy() as? NSMutableAttributedString else {
            fatalError("Invalid attributedText")
        }
        // If nextWordAttributes doesn't match with current textAttributes, apply textAttributes to nextWord.
        if !isTypingAtEnd, !attributes(isEqual: textAttributes, nextWordAttributes) {
            let firstWord = textView.text[range.location + range.length..<textView.text.count].enumerated().first { _, character -> Bool in
                attributes(fromCharacter: character) != nil
            }
            let length: Int
            if let firstWord = firstWord {
                length = firstWord.offset
            } else {
                length = textView.text.count - range.location - range.length
            }
            mutableText.addAttributes(textAttributes, range: NSRange(location: range.location + range.length, length: length))
        }
        mutableText.replaceCharacters(in: range, with: attributedText)
        textView.attributedText = mutableText.copy() as? NSAttributedString
        // Assign new range at replacedText location + newText count.
        textView.selectedRange = NSRange(location: range.location + text.count, length: 0)
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
        return character == " " || character == "\n"
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let firstWord = textView.text[0..<textView.selectedRange.lowerBound]
            .reversed().enumerated().first(where: { _, character -> Bool in
                attributes(fromCharacter: character) != nil
            }) else {
                character = nil
                return
        }
        // If not delimiter, we provide a recommendation range.
        guard attributes[firstWord.element] != nil else {
            character = nil
            return
        }
        // If user is selecting multiple characters, don't provide suggestions.
        guard textView.selectedRange.length == 0 else {
            character = nil
            return
        }
        character = firstWord.element
        let firstWordIndex = textView.selectedRange.lowerBound - firstWord.offset
        guard let secondWord = textView.text[firstWordIndex..<textView.text.count].enumerated().first(where: { _, c -> Bool in
            attributes(fromCharacter: c) != nil
        }) else {
            // No delimiter or new word found.
            recommendationRange = NSRange(location: firstWordIndex, length: textView.text.count - firstWordIndex)
            return
        }
        recommendationRange = NSRange(location: firstWordIndex, length: secondWord.offset)
    }

    public func typeFormatter(_ textView: UITextView, replaceRecommendationRange recommendationRange: NSRange, withText text: String) {
        guard let mutableText = textView.attributedText.mutableCopy() as? NSMutableAttributedString else {
            fatalError("Invalid attributedText")
        }
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(textView.typingAttributes, range: NSRange(location: 0, length: text.count))
        mutableText.replaceCharacters(in: recommendationRange, with: attributedText)
        textView.attributedText = mutableText.copy() as? NSAttributedString
        // Assign new range at replacedText location + newText count.
        textView.selectedRange = NSRange(location: recommendationRange.location + text.count, length: 0)
    }
}

public protocol AsYouTypeFormatterDelegate: AnyObject {
    func typeFormatter(_ formatter: AsYouTypeFormatter, characterPrefixDidChange character: Character?)
    func typeFormatter(_ formatter: AsYouTypeFormatter, recommendationRangeDidChange range: NSRange)
    func typeFormatter(_ formatter: AsYouTypeFormatter, isDelimiter character: Character) -> Bool
    func typeFormatter(_ formatter: AsYouTypeFormatter, attributesIsEqual lhs: [NSAttributedString.Key: Any], _ rhs: [NSAttributedString.Key: Any]) -> Bool
}
