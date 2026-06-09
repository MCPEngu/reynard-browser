//
//  TabBarCell.swift
//  Reynard
//
//  Created by Minh Ton on 5/3/26.
//

import UIKit

final class TabBarCell: UICollectionViewCell {
    enum LayoutMode {
        case expanded
        case faviconOnly
    }
    
    static let reuseIdentifier = "TabBarCell"
    static let expandedMinimumWidth: CGFloat = 220
    static let collapsedMinimumWidth: CGFloat = 96
    
    private static let fallbackFavicon = UIImage.reynardSystemImage(named: "globe")
    
    var onClose: (() -> Void)?
    
    private let faviconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .reynardSecondaryLabel
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .reynardSecondaryLabel
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.reynardSystemImage(named: "x.square.fill"), for: .normal)
        button.reynardSetPreferredSymbolConfiguration(pointSize: 14)
        button.tintColor = .reynardSecondaryLabel
        button.isHidden = true
        return button
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .reynardSeparator
        return view
    }()
    
    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        return stackView
    }()
    
    private var titleStackExpandedTrailingConstraint: NSLayoutConstraint!
    private var titleStackCollapsedTrailingConstraint: NSLayoutConstraint!
    private var titleStackExpandedLeadingConstraint: NSLayoutConstraint!
    private var titleStackCollapsedLeadingConstraint: NSLayoutConstraint!
    private var titleLabelExpandedWidthConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 0
        
        contentView.addSubview(titleStackView)
        titleStackView.addArrangedSubview(faviconImageView)
        titleStackView.addArrangedSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(separatorView)
        
        faviconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        faviconImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        faviconImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        titleStackExpandedTrailingConstraint = titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -34)
        titleStackCollapsedTrailingConstraint = titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
        titleStackExpandedLeadingConstraint = titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 10)
        titleStackCollapsedLeadingConstraint = titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8)
        titleLabelExpandedWidthConstraint = titleLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -58)
        
        NSLayoutConstraint.activate([
            titleStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleStackExpandedLeadingConstraint,
            titleStackExpandedTrailingConstraint,
            
            faviconImageView.widthAnchor.constraint(equalToConstant: 16),
            faviconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabelExpandedWidthConstraint,
            
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            closeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 22),
            closeButton.heightAnchor.constraint(equalToConstant: 22),
            
            separatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 2 / UIScreen.main.scale),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        faviconImageView.image = Self.fallbackFavicon
        titleLabel.isHidden = false
        titleStackView.spacing = 6
        titleStackExpandedLeadingConstraint.isActive = true
        titleStackCollapsedLeadingConstraint.isActive = false
        titleStackExpandedTrailingConstraint.isActive = true
        titleStackCollapsedTrailingConstraint.isActive = false
        titleLabelExpandedWidthConstraint.isActive = true
        onClose = nil
    }
    
    func configure(tab: Tab, selected: Bool, layoutMode: LayoutMode, itemWidth: CGFloat) {
        let displayTitle = tab.title.isEmpty ? "Homepage" : tab.title
        titleLabel.text = displayTitle
        faviconImageView.image = tab.favicon ?? Self.fallbackFavicon
        contentView.backgroundColor = selected ? .reynardSystemGray6 : .reynardSystemGray5
        titleLabel.textColor = selected ? .reynardLabel : .reynardSecondaryLabel
        faviconImageView.tintColor = selected ? .reynardLabel : .reynardSecondaryLabel
        let minimumVisibleTitle = "WWWWW" as NSString
        let minimumTitleWidth = minimumVisibleTitle.size(withAttributes: [.font: titleLabel.font as Any]).width
        let estimatedTitleBudget = itemWidth - 58
        let isTooNarrowForTitle = estimatedTitleBudget < minimumTitleWidth
        let isCollapsed = layoutMode == .faviconOnly || isTooNarrowForTitle
        
        titleLabel.isHidden = isCollapsed
        titleStackView.spacing = isCollapsed ? 0 : 6
        titleStackExpandedLeadingConstraint.isActive = !isCollapsed
        titleStackCollapsedLeadingConstraint.isActive = isCollapsed
        titleStackExpandedTrailingConstraint.isActive = !isCollapsed
        titleStackCollapsedTrailingConstraint.isActive = isCollapsed
        titleLabelExpandedWidthConstraint.isActive = !isCollapsed
        closeButton.isHidden = isCollapsed || !selected
        separatorView.isHidden = selected
    }
    
    func containsCloseButton(point: CGPoint) -> Bool {
        guard !closeButton.isHidden else {
            return false
        }
        
        let pointInContentView = convert(point, to: contentView)
        return closeButton.frame.contains(pointInContentView)
    }
    
    @objc private func closeTapped() {
        onClose?()
    }
}
