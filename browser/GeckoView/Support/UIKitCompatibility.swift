//
//  UIKitCompatibility.swift
//  GeckoView
//
//  Created by Codex on 9/6/26.
//

import UIKit

extension UIImage {
    static func reynardSystemImage(named name: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: name) ?? UIImage(named: name)
        }
        
        return UIImage(named: name)
    }
}

extension UIColor {
    static var reynardSystemBackground: UIColor {
        if #available(iOS 13.0, *) { return .systemBackground }
        return .white
    }
}

extension UITableView.Style {
    static var reynardInsetGrouped: UITableView.Style {
        if #available(iOS 13.0, *) { return .insetGrouped }
        return .grouped
    }
}
