//
//  Character.swift
//  AsYouTypeFormatter
//
//  Created by Philip on 16/03/19.
//  Copyright © 2018 Next Generation. All rights reserved.
//

import Foundation

extension Character {
    var isUTF16: Bool {
        return unicodeScalars.count == 1 && !unicodeScalars.contains(where: { unicodeScalar -> Bool in
            unicodeScalar.value > UTF16Char.max
        })
    }
}
