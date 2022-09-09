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
