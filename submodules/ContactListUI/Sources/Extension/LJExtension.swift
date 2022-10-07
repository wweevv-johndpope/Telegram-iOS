//
//  LJExtension.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation

struct LJExtension<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

protocol LJExtensionCompatible {}

extension LJExtensionCompatible {
    static var lj: LJExtension<Self>.Type {
        get { LJExtension<Self>.self }
        set {}
    }
    
    var lj: LJExtension<Self> {
        get { LJExtension(self) }
        set {}
    }
    
}


class DictionaryEncoder {
    private let jsonEncoder = JSONEncoder()

    /// Encodes given Encodable value into an array or dictionary
    func encode<T>(_ value: T) throws -> Any where T: Encodable {
        let jsonData = try jsonEncoder.encode(value)
        return try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
    }
}

class DictionaryDecoder {
    private let jsonDecoder = JSONDecoder()

    /// Decodes given Decodable type from given array or dictionary
    func decode<T>(_ type: T.Type, from json: Any) throws -> T where T: Decodable {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return try jsonDecoder.decode(type, from: jsonData)
    }
}
