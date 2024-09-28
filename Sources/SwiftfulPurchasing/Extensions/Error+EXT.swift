//
//  Error+EXT.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import Foundation

extension Error {
    var eventParameters: [String: Any] {
        [
            "error_description": self.localizedDescription
        ]
    }
}
