//
//  KeyboardDismissButton.swift
//  Reynard
//
//  Created by Minh Ton on 5/3/26.
//

import UIKit

final class KeyboardDismissButton {
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.isHidden = true
        button.backgroundColor = .reynardChromeBackground
        button.tintColor = .reynardLabel
        if #available(iOS 13.0, *) { button.layer.cornerCurve = .continuous }
        button.layer.cornerRadius = 21
        button.layer.shadowColor = UIColor.reynardChromeShadow.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.masksToBounds = false
        button.setImage(UIImage.reynardSystemImage(named: "xmark"), for: .normal)
        button.reynardSetPreferredSymbolConfiguration(pointSize: 20)
        return button
    }()
    
    var trailingPhoneConstraint: NSLayoutConstraint!
    var trailingPadConstraint: NSLayoutConstraint!
    var trailingCompactPadConstraint: NSLayoutConstraint!
    var centerYConstraint: NSLayoutConstraint!
    var widthConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
}
