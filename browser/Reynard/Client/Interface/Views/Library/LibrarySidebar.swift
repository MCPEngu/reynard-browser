//
//  LibrarySidebar.swift
//  Reynard
//
//  Created by Minh Ton on 10/3/26.
//

import UIKit

final class LibrarySidebarViewController: UIViewController,
                                          UICollectionViewDataSource,
                                          UICollectionViewDelegateFlowLayout,
                                          UINavigationControllerDelegate {
    private let cellReuseIdentifier = "LibrarySidebarCell"
    private let sections = LibrarySection.allCases
    private lazy var sidebarButton = makeLibrarySidebarButton(target: self, action: #selector(collapseSidebarFromRoot))
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .reynardSystemGray6
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .reynardSystemGray6
        configureCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
        navigationController?.setNavigationBarHidden(false, animated: animated)
        SidebarToggleButtonConfiguration.configure(sidebarButton, in: splitViewController)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: sidebarButton)
        navigationItem.rightBarButtonItem = nil
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController === self {
            SidebarToggleButtonConfiguration.configure(sidebarButton, in: splitViewController)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: sidebarButton)
            navigationItem.rightBarButtonItem = nil
            return
        }
        
        let button = makeLibrarySidebarButton(target: self, action: #selector(collapseSidebarFromAnyChild(_:)))
        SidebarToggleButtonConfiguration.configure(button, in: splitViewController)
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    private func configureCollectionView() {
        collectionView.contentInset.top = 32
        collectionView.verticalScrollIndicatorInsets.top = 32
        collectionView.register(LibrarySidebarCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.item) else {
            return
        }
        
        showSection(sections[indexPath.item], animated: true)
    }
    
    func showSection(_ section: LibrarySection, animated: Bool) {
        loadViewIfNeeded()
        
        let indexPath = sections.firstIndex(of: section).map { IndexPath(item: $0, section: 0) }
        
        if let indexPath {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
        
        let viewController = makeSectionViewController(for: section)
        navigationController?.setViewControllers([self, viewController], animated: animated)
        if let indexPath {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        if let sidebarCell = cell as? LibrarySidebarCell,
           sections.indices.contains(indexPath.item) {
            let section = sections[indexPath.item]
            sidebarCell.configure(title: section.title, symbolName: section.symbolName)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 48)
    }
    
    private func makeSectionViewController(for section: LibrarySection) -> UIViewController {
        let contentViewController: UIViewController
        
        switch section {
        case .bookmarks:
            contentViewController = LibrarySidebarHostedSectionViewController(hostedView: BookmarksManagerView())
        case .history:
            contentViewController = LibrarySidebarHostedSectionViewController(hostedView: HistoryManagerView())
        case .downloads:
            contentViewController = LibrarySidebarHostedSectionViewController(hostedView: DownloadsManagerView())
        case .settings:
            contentViewController = SettingsRootViewController()
        }
        
        return LibrarySidebarDetailViewController(
            title: section.title,
            contentViewController: contentViewController
        )
    }
    
    @objc private func collapseSidebarFromRoot() {
        (splitViewController as? BrowserSplitViewController)?.setLibrarySidebarVisible(false)
    }
    
    @objc private func collapseSidebarFromAnyChild(_ sender: UIButton) {
        (splitViewController as? BrowserSplitViewController)?.collapseLibrarySidebar(from: sender)
    }
}

private final class LibrarySidebarCell: UICollectionViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .reynardLabel
        if #available(iOS 13.0, *) {
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        }
        contentView.addSubview(iconView)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .reynardLabel
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String, symbolName: String) {
        titleLabel.text = title
        iconView.image = UIImage.reynardSystemImage(named: symbolName)
    }
}

private func makeLibrarySidebarButton(target: AnyObject, action: Selector) -> UIButton {
    let button = MakeButtons.makeToolbarButton(target: target, imageName: "sidebar.left", action: action)
    button.widthAnchor.constraint(equalToConstant: 30).isActive = true
    button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    return button
}

private final class LibrarySidebarHostedSectionViewController: UIViewController {
    private let hostedView: UIView
    
    init(hostedView: UIView) {
        self.hostedView = hostedView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .reynardSystemGray6
        
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostedView)
        
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}

private final class LibrarySidebarDetailViewController: UIViewController {
    private let contentViewController: UIViewController
    private let detailTitle: String
    private let maximumContentWidth: CGFloat = 360
    
    init(title: String, contentViewController: UIViewController) {
        self.detailTitle = title
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = detailTitle
        
        addChild(contentViewController)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentViewController.view)
        
        NSLayoutConstraint.activate([
            contentViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        contentViewController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.leftItemsSupplementBackButton = false
        navigationItem.leftBarButtonItem = nil
    }
}

final class LibraryEmptyBackgroundView: UIView {
    private var contentInsets: UIEdgeInsets = .zero {
        didSet {
            guard oldValue != contentInsets else {
                return
            }
            
            setNeedsLayout()
        }
    }
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .reynardSecondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    var message: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
            setNeedsLayout()
        }
    }
    
    init(message: String) {
        super.init(frame: .zero)
        label.text = message
        addSubview(label)
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateContentInsets(from tableView: UITableView) {
        let contentFrame = tableView.layoutMarginsGuide.layoutFrame
        contentInsets = UIEdgeInsets(
            top: 0,
            left: contentFrame.minX,
            bottom: 0,
            right: max(tableView.bounds.width - contentFrame.maxX, 0)
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let availableWidth = max(bounds.width - contentInsets.left - contentInsets.right, 0)
        let fittingSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = label.sizeThatFits(fittingSize)
        label.frame = CGRect(
            x: contentInsets.left,
            y: (bounds.height - labelSize.height) / 2,
            width: availableWidth,
            height: labelSize.height
        ).integral
    }
}
