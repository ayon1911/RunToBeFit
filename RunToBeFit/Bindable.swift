//
//  Bindable.swift
//  RunToBeFit
//
//  Created by krAyon on 26.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import Foundation

class Bindable<T> {
    var value: T? {
        didSet {
            observer?(value)
        }
    }
    var observer: ((T?) -> ())?
    
    func bind(observer: @escaping (T?) -> ()) {
        self.observer = observer
    }
}
