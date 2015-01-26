//
//  Array+Extensions.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/26/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import Foundation

extension Array {
    func find(includedElement: T -> Bool) -> T? {
        for (idx, element) in enumerate(self) {
            if includedElement(element) {
                return element
            }
        }
        return nil
    }
}