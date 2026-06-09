//
//  UIKitCompatibility.swift
//  Reynard
//
//  Created by Codex on 9/6/26.
//

import UIKit

enum ReynardSymbolWeight {
    case ultraLight
    case regular
    case medium
}

extension UIImage {
    static func reynardSystemImage(named name: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: name) ?? UIImage(named: name)
        }
        
        return UIImage(named: name)
    }
    
    static func reynardSystemImage(named name: String, pointSize: CGFloat, weight: ReynardSymbolWeight = .regular) -> UIImage? {
        if #available(iOS 13.0, *) {
            let symbolWeight: UIImage.SymbolWeight
            switch weight {
            case .ultraLight:
                symbolWeight = .ultraLight
            case .regular:
                symbolWeight = .regular
            case .medium:
                symbolWeight = .medium
            }
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: symbolWeight)
            return UIImage(systemName: name, withConfiguration: configuration) ?? UIImage(named: name)
        }
        
        return UIImage(named: name)
    }
}

extension UIButton {
    func reynardSetPreferredSymbolConfiguration(pointSize: CGFloat, weight: ReynardSymbolWeight = .regular) {
        guard #available(iOS 13.0, *) else {
            return
        }
        
        let symbolWeight: UIImage.SymbolWeight
        switch weight {
        case .ultraLight:
            symbolWeight = .ultraLight
        case .regular:
            symbolWeight = .regular
        case .medium:
            symbolWeight = .medium
        }
        setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: pointSize, weight: symbolWeight),
            forImageIn: .normal
        )
    }
}

extension UIColor {
    static var reynardLabel: UIColor {
        if #available(iOS 13.0, *) { return .label }
        return .black
    }
    
    static var reynardSecondaryLabel: UIColor {
        if #available(iOS 13.0, *) { return .secondaryLabel }
        return .darkGray
    }
    
    static var reynardTertiaryLabel: UIColor {
        if #available(iOS 13.0, *) { return .tertiaryLabel }
        return .gray
    }
    
    static var reynardSystemBackground: UIColor {
        if #available(iOS 13.0, *) { return .systemBackground }
        return .white
    }
    
    static var reynardSecondarySystemBackground: UIColor {
        if #available(iOS 13.0, *) { return .secondarySystemBackground }
        return UIColor(white: 0.95, alpha: 1)
    }
    
    static var reynardTertiarySystemBackground: UIColor {
        if #available(iOS 13.0, *) { return .tertiarySystemBackground }
        return UIColor(white: 0.9, alpha: 1)
    }
    
    static var reynardSystemGroupedBackground: UIColor {
        if #available(iOS 13.0, *) { return .systemGroupedBackground }
        return UIColor(white: 0.94, alpha: 1)
    }
    
    static var reynardSecondarySystemGroupedBackground: UIColor {
        if #available(iOS 13.0, *) { return .secondarySystemGroupedBackground }
        return .white
    }
    
    static var reynardSystemFill: UIColor {
        if #available(iOS 13.0, *) { return .systemFill }
        return UIColor(white: 0.72, alpha: 0.35)
    }
    
    static var reynardSecondarySystemFill: UIColor {
        if #available(iOS 13.0, *) { return .secondarySystemFill }
        return UIColor(white: 0.78, alpha: 0.3)
    }
    
    static var reynardTertiarySystemFill: UIColor {
        if #available(iOS 13.0, *) { return .tertiarySystemFill }
        return UIColor(white: 0.84, alpha: 0.28)
    }
    
    static var reynardQuaternarySystemFill: UIColor {
        if #available(iOS 13.0, *) { return .quaternarySystemFill }
        return UIColor(white: 0.88, alpha: 0.25)
    }
    
    static var reynardSeparator: UIColor {
        if #available(iOS 13.0, *) { return .separator }
        return UIColor(white: 0.78, alpha: 1)
    }
    
    static var reynardPlaceholderText: UIColor {
        if #available(iOS 13.0, *) { return .placeholderText }
        return .gray
    }
    
    static var reynardSystemGray4: UIColor {
        if #available(iOS 13.0, *) { return .systemGray4 }
        return UIColor(white: 0.82, alpha: 1)
    }

    static var reynardSystemGray5: UIColor {
        if #available(iOS 13.0, *) { return .systemGray5 }
        return UIColor(white: 0.9, alpha: 1)
    }

    static var reynardSystemGray6: UIColor {
        if #available(iOS 13.0, *) { return .systemGray6 }
        return UIColor(white: 0.96, alpha: 1)
    }
    
    static var reynardChromeBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .tertiarySystemBackground : .systemBackground
            }
        }
        
        return .white
    }
    
    static var reynardChromeShadow: UIColor {
        if #available(iOS 13.0, *), UITraitCollection.current.userInterfaceStyle == .dark {
            return UIColor.white.withAlphaComponent(0.3)
        }
        
        return .black
    }
}

extension UITableView.Style {
    static var reynardInsetGrouped: UITableView.Style {
        if #available(iOS 13.0, *) { return .insetGrouped }
        return .grouped
    }
}

extension UISearchBar {
    var reynardTextField: UITextField {
        if #available(iOS 13.0, *) {
            return searchTextField
        }

        if let textField = value(forKey: "searchField") as? UITextField {
            return textField
        }

        return firstDescendantTextField() ?? UITextField(frame: bounds)
    }

    private func firstDescendantTextField() -> UITextField? {
        for subview in subviews {
            if let textField = subview as? UITextField {
                return textField
            }
            if let textField = subview.firstDescendantTextField() {
                return textField
            }
        }
        return nil
    }
}

private extension UIView {
    func firstDescendantTextField() -> UITextField? {
        for subview in subviews {
            if let textField = subview as? UITextField {
                return textField
            }
            if let textField = subview.firstDescendantTextField() {
                return textField
            }
        }
        return nil
    }
}
