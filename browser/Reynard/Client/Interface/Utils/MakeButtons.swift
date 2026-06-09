//
//  MakeButtons.swift
//  Reynard
//
//  Created by Minh Ton on 5/3/26.
//

import UIKit
import Darwin

enum MakeButtons {
    static let hasLiquidGlass = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "_UISolariumEnabled") != nil && _UISolariumEnabled()
    static let bookmarksLibraryActionBarButtonTag = 8701
    static let historyLibraryActionBarButtonTag = 8702
    static let downloadsLibraryActionBarButtonTag = 8703
    static let libraryActionBarButtonTags: Set<Int> = [
        bookmarksLibraryActionBarButtonTag,
        historyLibraryActionBarButtonTag,
        downloadsLibraryActionBarButtonTag,
    ]
    
    private static func toolbarImage(for imageName: String) -> UIImage? {
        if let image = UIImage.reynardSystemImage(named: imageName) {
            return image
        }
        
        if let image = UIImage(named: imageName) {
            return image
        }
        
        switch imageName {
        case "chevron.backward":
            return UIImage.reynardSystemImage(named: "chevron.left")
        case "chevron.forward":
            return UIImage.reynardSystemImage(named: "chevron.right")
        case "list.bullet.below.rectangle":
            return UIImage.reynardSystemImage(named: "line.horizontal.3")
        default:
            return nil
        }
    }
    
    static func makeToolbarButton(target: AnyObject, imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(toolbarImage(for: imageName), for: .normal)
        if imageName == "plus" {
            button.reynardSetPreferredSymbolConfiguration(pointSize: 20)
        }
        button.tintColor = .reynardLabel
        button.addTarget(target, action: action, for: .touchUpInside)
        button.layer.cornerRadius = 10
        if #available(iOS 13.0, *) { button.layer.cornerCurve = .continuous }
        return button
    }
    
    static func makeDownloadToolbarButton(target: AnyObject, action: Selector) -> DownloadToolbarButton {
        let button = DownloadToolbarButton()
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
    
    static func makeLibraryActionsButton(target: AnyObject, imageName: String, action: Selector) -> UIButton {
        let button = LibraryActionsButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .reynardLabel
        if #available(iOS 13.0, *) { button.layer.cornerCurve = .continuous }
        button.layer.masksToBounds = true
        button.addTarget(target, action: action, for: .touchUpInside)
        updateLibraryActionsButton(button, imageName: imageName)
        return button
    }
    
    static func updateLibraryActionsButton(_ button: UIButton, imageName: String) {
        button.setImage(toolbarImage(for: imageName), for: .normal)
        button.backgroundColor = .reynardQuaternarySystemFill
    }
    
    static func installLibraryActionBarButton(_ item: UIBarButtonItem, in navigationItem: UINavigationItem) {
        navigationItem.leftItemsSupplementBackButton = true
        let existingItems = navigationItem.leftBarButtonItems?.filter {
            !libraryActionBarButtonTags.contains($0.tag)
        } ?? []
        navigationItem.leftBarButtonItems = existingItems + [item]
    }
    
    static func removeLibraryActionBarButtons(from navigationItem: UINavigationItem) {
        let remainingItems = navigationItem.leftBarButtonItems?.filter {
            !libraryActionBarButtonTags.contains($0.tag)
        }
        navigationItem.leftBarButtonItems = remainingItems?.isEmpty == true ? nil : remainingItems
    }
    
    static func makeTabOverviewBarButton(controller: BrowserViewController, imageName: String, isFilled: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(toolbarImage(for: imageName), for: .normal)
        button.reynardSetPreferredSymbolConfiguration(pointSize: 17)
        button.tintColor = isFilled ? .reynardSystemBackground : .reynardLabel
        button.backgroundColor = isFilled ? .reynardLabel : .reynardQuaternarySystemFill
        button.layer.borderWidth = isFilled ? 0 : 1
        button.layer.borderColor = isFilled ? UIColor.clear.cgColor : UIColor.reynardSystemFill.cgColor
        if #available(iOS 13.0, *) { button.layer.cornerCurve = .continuous }
        button.layer.cornerRadius = 21
        button.addTarget(controller, action: action, for: .touchUpInside)
        return button
    }
    
    static func makeTabOverviewBarButtonItem(controller: BrowserViewController, systemItem: UIBarButtonItem.SystemItem, action: Selector) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: systemItem, target: controller, action: action)
        item.tintColor = .reynardLabel
        return item
    }
}

private final class LibraryActionsButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !MakeButtons.hasLiquidGlass else {
            return
        }
        
        layer.cornerRadius = bounds.height / 2
    }
}

final class DownloadToolbarButton: UIButton {
    private let buttonSideLength: CGFloat = 40
    private let progressTrackWidth: CGFloat = 18
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.tintColor = .reynardLabel
        view.clipsToBounds = false
        return view
    }()
    
    private let progressTrackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .reynardTertiarySystemFill
        view.layer.cornerRadius = 1.25
        view.isHidden = true
        return view
    }()
    
    private let progressFillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .reynardLabel
        view.layer.cornerRadius = 1.25
        view.isHidden = true
        return view
    }()
    
    private lazy var progressFillWidthConstraint = progressFillView.widthAnchor.constraint(equalToConstant: 0)
    
    private(set) var isShowingDownloads = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tintColor = .reynardLabel
        layer.cornerRadius = 10
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        layer.masksToBounds = false
        clipsToBounds = false
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setImage(nil, for: .normal)
        
        addSubview(iconView)
        addSubview(progressTrackView)
        addSubview(progressFillView)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            progressTrackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressTrackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            progressTrackView.widthAnchor.constraint(equalToConstant: progressTrackWidth),
            progressTrackView.heightAnchor.constraint(equalToConstant: 2.5),
            
            progressFillView.leadingAnchor.constraint(equalTo: progressTrackView.leadingAnchor),
            progressFillView.centerYAnchor.constraint(equalTo: progressTrackView.centerYAnchor),
            progressFillView.heightAnchor.constraint(equalTo: progressTrackView.heightAnchor),
            progressFillWidthConstraint,
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: buttonSideLength, height: buttonSideLength)
    }
    
    func apply(summary: DownloadStoreSummary) {
        let shouldShowDownloads = summary.showsToolbarButton
        if shouldShowDownloads != isShowingDownloads {
            isShowingDownloads = shouldShowDownloads
            if shouldShowDownloads {
                playBounceAnimation()
            }
        }
        
        iconView.image = UIImage.reynardSystemImage(named: "arrow.down.circle", pointSize: 17)
        
        let progress = min(max(CGFloat(summary.aggregateProgress), 0), 1)
        let showsProgress = summary.activeCount > 0
        progressTrackView.isHidden = !showsProgress
        progressFillView.isHidden = !showsProgress
        progressFillWidthConstraint.constant = progressTrackWidth * progress
        accessibilityLabel = "Downloads"
    }
    
    private func playBounceAnimation() {
        iconView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.45,
            initialSpringVelocity: 0.6,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                self.iconView.transform = .identity
            }
        )
    }
}
