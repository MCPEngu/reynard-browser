//
//  BrowserViewController+UI.swift
//  Reynard
//
//  Created by Minh Ton on 15/5/26.
//

import ObjectiveC
import GeckoView
import UIKit

private enum UIAssociatedKeys {
    static var browserUI = 0
    static var addressBarGestures = 0
    static var searchController = 0
    static var searchViewController = 0
    static var isSearchFocused = 0
    static var activeReorderingCell = 0
    static var activeDragSnapshotView = 0
    static var pendingReorderStartWorkItem = 0
    static var isInteractiveReorderActive = 0
    static var activeDragOffset = 0
    static var tabOverviewCardAnimationState = 0
    static var activeTabBarReorderSourceIndex = 0
    static var activeTabBarReorderTargetIndex = 0
    static var searchScrollDismissal = 0
    static var preserveSuggestions = 0
    static var suggestionsTop = 0
    static var suggestionsBottom = 0
    static var suggestionsLeading = 0
    static var suggestionsTrailing = 0
    static var suggestionsCenterX = 0
    static var suggestionsWidth = 0
    static var suggestionsHeight = 0
    static var suggestionsContentHeight = 0
    static var searchScrollMode = 0
    static var autocompleteDeleteText = 0
}

private final class TabOverviewCardAnimationState {
    var hasIdentitySnapshot = false
    var regularTabIDs: [UUID] = []
    var privateTabIDs: [UUID] = []
    var fakeInsertionMode: TabOverviewCollection.Mode?
}

extension BrowserViewController: AddressBarDelegate, BottomToolbarDelegate {
    var overviewInset: CGFloat {
        16
    }
    
    var overviewSpacing: CGFloat {
        16
    }
    
    var browserUI: BrowserUI {
        get {
            if let ui = objc_getAssociatedObject(self, &UIAssociatedKeys.browserUI) as? BrowserUI {
                return ui
            }
            
            let ui = BrowserUI(controller: self, tabCollectionHandler: self)
            objc_setAssociatedObject(self, &UIAssociatedKeys.browserUI, ui, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return ui
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.browserUI, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var addressBarGestures: AddressBarGestures {
        get {
            if let gestures = objc_getAssociatedObject(self, &UIAssociatedKeys.addressBarGestures) as? AddressBarGestures {
                return gestures
            }
            
            let gestures = AddressBarGestures(controller: self)
            objc_setAssociatedObject(self, &UIAssociatedKeys.addressBarGestures, gestures, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return gestures
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.addressBarGestures, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isSearchFocused: Bool {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.isSearchFocused) as? NSNumber)?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.isSearchFocused, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    func currentInterfaceOrientationForLayout() -> UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            return view.window?.windowScene?.interfaceOrientation
        }
        
        return UIApplication.shared.statusBarOrientation
    }
    
    var usesCompactPadChrome: Bool {
        if isPad && traitCollection.horizontalSizeClass == .compact { return true }
        return usesTopPhoneAddressBar
    }
    
    var usesPadChrome: Bool {
        if isPad { return true }
        if usesTopPhoneAddressBar { return true }
        if let orientation = currentInterfaceOrientationForLayout() {
            return orientation.isLandscape
        }
        return view.bounds.width > view.bounds.height
    }
    
    var usesDetachedSuggestions: Bool {
        if usesCompactPadChrome {
            return false
        }
        
        if isPad {
            return true
        }
        
        if let orientation = currentInterfaceOrientationForLayout() {
            return orientation.isLandscape
        }
        
        return view.bounds.width > view.bounds.height
    }
    
    var usesTopPhoneAddressBar: Bool {
        guard !isPad else { return false }
        let isLandscape: Bool
        if let orientation = currentInterfaceOrientationForLayout() {
            isLandscape = orientation.isLandscape
        } else {
            isLandscape = view.bounds.width > view.bounds.height
        }
        guard !isLandscape else { return false }
        return Prefs.AppearanceSettings.addressBarPosition == .top
    }
    
    var autocompleteDeleteText: String? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.autocompleteDeleteText) as? String
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.autocompleteDeleteText, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var usesBottomPhoneOverview: Bool {
        guard !isPad else { return false }
        return usesTopPhoneAddressBar || !usesPadChrome
    }
    
    var activeAddressBar: AddressBar {
        browserUI.addressBar
    }
    
    @objc func applyUpdateMenuButtonBadge() {
        browserUI.bottomToolbar.setMenuButtonIndicatesUpdate(true)
        browserUI.topBarButtons.setMenuButtonIndicatesUpdate(true)
    }
    
    func setSearchFocused(_ focused: Bool, animated: Bool) {
        browserUI.setSearchFocused(focused, animated: animated)
    }
    
    func applyChromeLayout(animated: Bool) {
        browserUI.applyChromeLayout(animated: animated)
    }
    
    func updateNavigationButtons() {
        guard let tab = tabManager.selectedTab else {
            return
        }
        
        browserUI.bottomToolbar.updateBackButton(canGoBack: tab.canNavigateBack)
        browserUI.bottomToolbar.updateForwardButton(canGoForward: tab.canNavigateForward)
        let shareEnabled = tabManager.shareableURL(for: tab) != nil
        browserUI.bottomToolbar.updateShareButton(isEnabled: shareEnabled)
        browserUI.topBarButtons.shareButton.isEnabled = shareEnabled
        browserUI.topBarButtons.backButton.isEnabled = tab.canNavigateBack
        browserUI.topBarButtons.forwardButton.isEnabled = tab.canNavigateForward
    }
    
    @objc func addressBarPositionDidChange() {
        browserUI.applyChromeLayout(animated: true)
        searchViewController.setUsesTopAddressBarMode(usesTopPhoneAddressBar)
        searchViewController.setUsesPadChromeMode(usesPadChrome)
        updateSuggestionsLayoutIfNeeded()
    }
    
    @objc func landscapeTabBarDidChange() {
        browserUI.applyChromeLayout(animated: true)
        searchViewController.setUsesTopAddressBarMode(usesTopPhoneAddressBar)
        searchViewController.setUsesPadChromeMode(usesPadChrome)
        updateSuggestionsLayoutIfNeeded()
    }
    
    func syncBrowserNavigationChrome(animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationItem.leftItemsSupplementBackButton = false
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItems = []
        navigationItem.leftBarButtonItem = nil
    }
    
    private func activeTabBarHeight() -> CGFloat {
        let activeTabs = tabManager.selectedTabMode == .private ? tabManager.privateTabs : tabManager.regularTabs
        guard usesPadChrome,
              activeTabs.count > 1 else {
            return 0
        }
        
        if !isPad {
            guard Prefs.AppearanceSettings.showsLandscapeTabBar else {
                return 0
            }
            let isLandscape: Bool
            if let orientation = currentInterfaceOrientationForLayout() {
                isLandscape = orientation.isLandscape
            } else {
                isLandscape = view.bounds.width > view.bounds.height
            }
            guard isLandscape else {
                return 0
            }
        }
        
        return 36
    }
    
    func tabPreviewAspectRatio() -> CGFloat {
        let bounds = browserUI.geckoView.bounds
        let width = max(bounds.width, 1)
        let height = max(bounds.height + activeTabBarHeight(), 1)
        return height / width
    }
    
    func captureThumbnail(for index: Int) {
        let activeTabs = tabManager.selectedTabMode == .private ? tabManager.privateTabs : tabManager.regularTabs
        guard !browserUI.geckoView.isHidden,
              let tab = activeTabs[safe: index],
              browserUI.geckoView.session === tab.session else {
            return
        }
        
        let bounds = browserUI.geckoView.bounds
        guard bounds.width > 1, bounds.height > 1 else {
            return
        }
        
        browserUI.geckoView.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { context in
            browserUI.geckoView.layer.render(in: context.cgContext)
        }
        tabManager.updateThumbnail(image, forTabAt: index)
    }
    
    func dismissalContentFrame() -> CGRect {
        let frame = browserUI.geckoView.frame
        let tabBarHeight = activeTabBarHeight()
        guard tabBarHeight > 0,
              usesPadChrome,
              tabOverviewPresentation.isVisible else {
            return frame
        }
        
        return CGRect(
            x: frame.minX,
            y: frame.minY + tabBarHeight,
            width: frame.width,
            height: max(1, frame.height - tabBarHeight)
        )
    }
    
    func syncAddressBarLoadingState(progress: Float, isLoading: Bool) {
        browserUI.addressBar.setLoadingProgress(progress, isLoading: isLoading)
    }
    
    func refreshAddressBar() {
        let selectedTab = tabManager.selectedTab
        let pendingDisplayText = selectedTab?.pendingDisplayText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPendingDisplayText = !(pendingDisplayText?.isEmpty ?? true)
        let selectedURL = selectedTab?.url
        let displayedText = hasPendingDisplayText ? pendingDisplayText : selectedURL
        let shouldPreserveSearchComposingText = isSearchScrollMode && searchViewController.parent != nil
        if !browserUI.addressBar.isEditingText && !shouldPreserveSearchComposingText {
            browserUI.addressBar.setText(
                displayedText,
                locationText: selectedURL,
                locationTitle: selectedTab?.title,
                showsBarMenu: !hasPendingDisplayText && selectedURL?.isEmpty == false
            )
        }
        browserUI.addressBar.setLoadingProgress(selectedTab?.progress ?? 0, isLoading: selectedTab?.isLoading ?? false)
        addonController.prepareVisibleAddonIcons()
        if #available(iOS 13.0, *) {
            let addonItems = addonController.visibleMenuItemsForCurrentSite().map { item in
                AddressBarMenu.AddonItem(menuItem: item, image: addonController.iconImage(for: item.addon))
            }
            browserUI.addressBar.setAddonsMenu(
                AddressBarMenu.makeMenu(
                    selectedTab: selectedTab,
                    selectedURL: selectedURL,
                    addonItems: addonItems
                )
            )
        } else {
            browserUI.addressBar.setAddonsMenu(nil)
        }
    }
    func addressBarDidTapTrailingButton(_ addressBar: AddressBar) {
        guard let selectedTab = tabManager.selectedTab else {
            return
        }
        
        if selectedTab.isLoading {
            selectedTab.session.stop()
            return
        }
        
        selectedTab.session.reload()
    }
}

final class BrowserUI {
    typealias TabCollectionHandler = UICollectionViewDataSource & UICollectionViewDelegate & UICollectionViewDelegateFlowLayout
    
    let geckoView: GeckoView = {
        let view = GeckoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let bottomContainer = BottomContainer()
    
    let addressBar: AddressBar = {
        let bar = AddressBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    let keyboardDismissButton = KeyboardDismissButton()
    
    let bottomToolbar: BottomToolbar = {
        let bar = BottomToolbar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    let topBar = TopBar()
    let topBarButtons: TopBarButtons
    let tabBar: TabBar
    
    let tabOverview = TabOverview()
    let tabOverviewCollection: TabOverviewCollection
    let tabOverviewBottomBar = TabOverviewBottomBar()
    let tabOverviewTopBar = TabOverviewTopBar()
    let tabOverviewBarButtons: TabOverviewBarButtons
    
    var geckoTopPhoneConstraint: NSLayoutConstraint!
    var geckoTopPadConstraint: NSLayoutConstraint!
    var geckoBottomPhoneConstraint: NSLayoutConstraint!
    var geckoBottomPhoneSearchPinnedConstraint: NSLayoutConstraint!
    var geckoBottomPhoneKeyboardOverlayConstraint: NSLayoutConstraint!
    var geckoBottomPadConstraint: NSLayoutConstraint!
    var geckoBottomCompactPadConstraint: NSLayoutConstraint!
    var geckoLeadingPhoneConstraint: NSLayoutConstraint!
    var geckoTrailingPhoneConstraint: NSLayoutConstraint!
    var geckoLeadingPadConstraint: NSLayoutConstraint!
    var geckoTrailingPadConstraint: NSLayoutConstraint!
    var geckoTopFullscreenConstraint: NSLayoutConstraint!
    var geckoBottomFullscreenConstraint: NSLayoutConstraint!
    
    var bottomContainerBottomConstraint: NSLayoutConstraint!
    var bottomContainerHeightConstraint: NSLayoutConstraint!
    var bottomToolbarHeightConstraint: NSLayoutConstraint!
    var bottomToolbarTopConstraint: NSLayoutConstraint!
    var bottomToolbarCompactPadTopConstraint: NSLayoutConstraint!
    var addressBarPhoneLeadingConstraint: NSLayoutConstraint!
    var addressBarPhoneTrailingFullConstraint: NSLayoutConstraint!
    var addressBarPhoneTrailingFocusedConstraint: NSLayoutConstraint!
    var addressBarPhoneTopConstraint: NSLayoutConstraint!
    var addressBarPhoneHeightConstraint: NSLayoutConstraint!
    var addressBarPadLeadingConstraint: NSLayoutConstraint!
    var addressBarPadTrailingConstraint: NSLayoutConstraint!
    var addressBarCompactPadLeadingConstraint: NSLayoutConstraint!
    var addressBarCompactPadTrailingConstraint: NSLayoutConstraint!
    var addressBarPadCenterYConstraint: NSLayoutConstraint!
    var addressBarPadHeightConstraint: NSLayoutConstraint!
    
    private unowned let controller: BrowserViewController
    private let tabCollectionHandler: TabCollectionHandler
    private var keyboardHeight: CGFloat = 0
    private var keyboardFrame: CGRect = .zero
    private var focusedInputBottomRatio: CGFloat?
    private var geckoPhoneVerticalOffset: CGFloat = 0
    private var focusedInputMetricsTask: Task<Void, Never>?
    
    init(
        controller: BrowserViewController,
        tabCollectionHandler: TabCollectionHandler
    ) {
        self.controller = controller
        self.tabCollectionHandler = tabCollectionHandler
        
        topBarButtons = TopBarButtons(controller: controller)
        tabBar = TabBar(tabCollectionHandler: tabCollectionHandler)
        tabOverviewCollection = TabOverviewCollection(
            overviewInset: controller.overviewInset,
            overviewSpacing: controller.overviewSpacing,
            tabCollectionHandler: tabCollectionHandler
        )
        tabOverviewBarButtons = TabOverviewBarButtons(controller: controller)
        
        addressBar.configure(delegate: controller)
        keyboardDismissButton.button.addTarget(controller, action: #selector(BrowserViewController.dismissKeyboardTapped), for: .touchUpInside)
        bottomToolbar.delegate = controller
    }
    
    deinit {
        focusedInputMetricsTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    func configureLayout() {
        let ui = controller.browserUI
        let view = controller.view!
        
        view.addSubview(ui.bottomContainer.bottomSafeAreaFillView)
        view.addSubview(ui.geckoView)
        view.addSubview(ui.bottomContainer.containerView)
        view.addSubview(ui.topBar.safeAreaFillView)
        ui.bottomContainer.containerView.addSubview(ui.addressBar)
        
        ui.bottomContainer.containerView.addSubview(ui.bottomToolbar)
        
        view.addSubview(ui.topBar.barView)
        ui.topBar.barView.addSubview(ui.topBar.contentView)
        ui.topBar.contentView.addSubview(ui.topBarButtons.leftStack)
        ui.topBar.contentView.addSubview(ui.topBarButtons.rightStack)
        
        setAddressBarHost(isPad: controller.usesPadChrome)
        setKeyboardDismissButtonHost(isPad: controller.usesPadChrome)
        
        ui.topBar.barView.addSubview(ui.tabBar.collectionView)
        
        view.addSubview(ui.tabOverview.containerView)
        ui.tabOverview.containerView.addSubview(ui.tabOverviewCollection.privateTabsCollection)
        ui.tabOverview.containerView.addSubview(ui.tabOverviewCollection.tabsCollection)
        ui.tabOverview.containerView.addSubview(ui.tabOverviewBottomBar.barView)
        ui.tabOverview.containerView.addSubview(ui.tabOverviewTopBar.barView)
        ui.tabOverviewBarButtons.attach(to: ui.tabOverviewBottomBar.barView, verticalPhoneMode: true)
        
        ui.geckoTopPhoneConstraint = ui.geckoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ui.geckoTopPadConstraint = ui.geckoView.topAnchor.constraint(equalTo: ui.topBar.barView.bottomAnchor)
        ui.geckoBottomPhoneConstraint = ui.geckoView.bottomAnchor.constraint(equalTo: ui.bottomContainer.containerView.topAnchor)
        ui.geckoBottomPhoneSearchPinnedConstraint = ui.geckoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -94)
        ui.geckoBottomPhoneKeyboardOverlayConstraint = ui.geckoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ui.geckoBottomPadConstraint = ui.geckoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ui.geckoBottomCompactPadConstraint = ui.geckoView.bottomAnchor.constraint(equalTo: ui.bottomContainer.containerView.topAnchor)
        ui.geckoLeadingPhoneConstraint = ui.geckoView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ui.geckoTrailingPhoneConstraint = ui.geckoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ui.geckoLeadingPadConstraint = ui.geckoView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ui.geckoTrailingPadConstraint = ui.geckoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ui.geckoTopFullscreenConstraint = ui.geckoView.topAnchor.constraint(equalTo: view.topAnchor)
        ui.geckoBottomFullscreenConstraint = ui.geckoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        ui.bottomContainerBottomConstraint = ui.bottomContainer.containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ui.bottomContainerHeightConstraint = ui.bottomContainer.containerView.heightAnchor.constraint(equalToConstant: 94)
        ui.bottomToolbarHeightConstraint = ui.bottomToolbar.heightAnchor.constraint(equalToConstant: 30)
        ui.bottomToolbarTopConstraint = ui.bottomToolbar.topAnchor.constraint(equalTo: ui.addressBar.bottomAnchor, constant: 7)
        ui.bottomToolbarCompactPadTopConstraint = ui.bottomToolbar.topAnchor.constraint(equalTo: ui.bottomContainer.containerView.topAnchor, constant: 7)
        
        ui.addressBarPhoneLeadingConstraint = ui.addressBar.leadingAnchor.constraint(equalTo: ui.bottomContainer.containerView.leadingAnchor, constant: 12)
        ui.addressBarPhoneTrailingFullConstraint = ui.addressBar.trailingAnchor.constraint(equalTo: ui.bottomContainer.containerView.trailingAnchor, constant: -12)
        ui.addressBarPhoneTrailingFocusedConstraint = ui.addressBar.trailingAnchor.constraint(equalTo: ui.keyboardDismissButton.button.leadingAnchor, constant: -9)
        ui.addressBarPhoneTopConstraint = ui.addressBar.topAnchor.constraint(equalTo: ui.bottomContainer.containerView.topAnchor, constant: 8)
        ui.addressBarPhoneHeightConstraint = ui.addressBar.heightAnchor.constraint(equalToConstant: 42)
        
        ui.addressBarPadLeadingConstraint = ui.addressBar.leadingAnchor.constraint(equalTo: ui.topBarButtons.leftStack.trailingAnchor, constant: 12)
        ui.addressBarPadTrailingConstraint = ui.addressBar.trailingAnchor.constraint(equalTo: ui.topBarButtons.rightStack.leadingAnchor, constant: -12)
        ui.addressBarCompactPadLeadingConstraint = ui.addressBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12)
        ui.addressBarCompactPadTrailingConstraint = ui.addressBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ui.addressBarPadCenterYConstraint = ui.addressBar.centerYAnchor.constraint(equalTo: ui.topBar.contentView.centerYAnchor)
        ui.addressBarPadHeightConstraint = ui.addressBar.heightAnchor.constraint(equalToConstant: 38)
        
        ui.keyboardDismissButton.trailingPhoneConstraint = ui.keyboardDismissButton.button.trailingAnchor.constraint(equalTo: ui.bottomContainer.containerView.trailingAnchor, constant: -12)
        ui.keyboardDismissButton.trailingPadConstraint = ui.keyboardDismissButton.button.trailingAnchor.constraint(equalTo: ui.topBarButtons.rightStack.leadingAnchor, constant: -12)
        ui.keyboardDismissButton.trailingCompactPadConstraint = ui.keyboardDismissButton.button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ui.keyboardDismissButton.centerYConstraint = ui.keyboardDismissButton.button.centerYAnchor.constraint(equalTo: ui.addressBar.centerYAnchor)
        ui.keyboardDismissButton.widthConstraint = ui.keyboardDismissButton.button.widthAnchor.constraint(equalToConstant: 42)
        ui.keyboardDismissButton.heightConstraint = ui.keyboardDismissButton.button.heightAnchor.constraint(equalToConstant: 42)
        
        ui.topBar.heightConstraint = ui.topBar.barView.heightAnchor.constraint(equalToConstant: 52)
        ui.topBar.topConstraint = ui.topBar.barView.topAnchor.constraint(equalTo: view.topAnchor)
        ui.topBar.contentHeightConstraint = ui.topBar.contentView.heightAnchor.constraint(equalToConstant: 52)
        
        ui.topBarButtons.leftLeadingConstraint = ui.topBarButtons.leftStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12)
        ui.topBarButtons.rightTrailingConstraint = ui.topBarButtons.rightStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ui.topBarButtons.leftWidthConstraint = ui.topBarButtons.leftStack.widthAnchor.constraint(equalToConstant: 126)
        ui.topBarButtons.rightWidthConstraint = ui.topBarButtons.rightStack.widthAnchor.constraint(equalToConstant: 126)
        ui.topBarButtons.leftHeightConstraint = ui.topBarButtons.leftStack.heightAnchor.constraint(equalToConstant: 30)
        ui.topBarButtons.rightHeightConstraint = ui.topBarButtons.rightStack.heightAnchor.constraint(equalToConstant: 30)
        
        ui.tabBar.heightConstraint = ui.tabBar.collectionView.heightAnchor.constraint(equalToConstant: 36)
        
        ui.tabOverviewCollection.topPhoneConstraint = ui.tabOverviewCollection.tabsCollection.topAnchor.constraint(equalTo: view.topAnchor)
        ui.tabOverviewCollection.bottomPhoneConstraint = ui.tabOverviewCollection.tabsCollection.bottomAnchor.constraint(equalTo: ui.tabOverviewBottomBar.barView.topAnchor)
        ui.tabOverviewCollection.topPadConstraint = ui.tabOverviewCollection.tabsCollection.topAnchor.constraint(equalTo: ui.tabOverviewTopBar.barView.bottomAnchor)
        ui.tabOverviewCollection.bottomPadConstraint = ui.tabOverviewCollection.tabsCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ui.tabOverviewCollection.privateTopPhoneConstraint = ui.tabOverviewCollection.privateTabsCollection.topAnchor.constraint(equalTo: view.topAnchor)
        ui.tabOverviewCollection.privateBottomPhoneConstraint = ui.tabOverviewCollection.privateTabsCollection.bottomAnchor.constraint(equalTo: ui.tabOverviewBottomBar.barView.topAnchor)
        ui.tabOverviewCollection.privateTopPadConstraint = ui.tabOverviewCollection.privateTabsCollection.topAnchor.constraint(equalTo: ui.tabOverviewTopBar.barView.bottomAnchor)
        ui.tabOverviewCollection.privateBottomPadConstraint = ui.tabOverviewCollection.privateTabsCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        ui.tabOverviewBottomBar.bottomConstraint = ui.tabOverviewBottomBar.barView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ui.tabOverviewBottomBar.heightConstraint = ui.tabOverviewBottomBar.barView.heightAnchor.constraint(equalToConstant: 144)
        ui.tabOverviewTopBar.heightConstraint = ui.tabOverviewTopBar.barView.heightAnchor.constraint(equalToConstant: 76)
        
        NSLayoutConstraint.activate([
            ui.geckoLeadingPhoneConstraint,
            ui.geckoTrailingPhoneConstraint,
            ui.geckoTopPhoneConstraint,
            ui.geckoBottomPhoneConstraint,
            
            ui.bottomContainer.containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ui.bottomContainer.containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ui.bottomContainerBottomConstraint,
            ui.bottomContainerHeightConstraint,
            
            ui.bottomContainer.bottomSafeAreaFillView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ui.bottomContainer.bottomSafeAreaFillView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ui.bottomContainer.bottomSafeAreaFillView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            ui.bottomContainer.bottomSafeAreaFillView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ui.addressBarPhoneLeadingConstraint,
            ui.addressBarPhoneTrailingFullConstraint,
            ui.addressBarPhoneTopConstraint,
            ui.addressBarPhoneHeightConstraint,
            
            ui.keyboardDismissButton.trailingPhoneConstraint,
            ui.keyboardDismissButton.centerYConstraint,
            ui.keyboardDismissButton.widthConstraint,
            ui.keyboardDismissButton.heightConstraint,
            
            ui.bottomToolbar.leadingAnchor.constraint(equalTo: ui.bottomContainer.containerView.leadingAnchor, constant: 24),
            ui.bottomToolbar.trailingAnchor.constraint(equalTo: ui.bottomContainer.containerView.trailingAnchor, constant: -24),
            ui.bottomToolbarTopConstraint,
            ui.bottomToolbarHeightConstraint,
            
            ui.topBar.barView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ui.topBar.barView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ui.topBar.topConstraint,
            ui.topBar.heightConstraint,
            
            ui.topBar.contentView.leadingAnchor.constraint(equalTo: ui.topBar.barView.leadingAnchor),
            ui.topBar.contentView.trailingAnchor.constraint(equalTo: ui.topBar.barView.trailingAnchor),
            ui.topBar.contentView.topAnchor.constraint(equalTo: ui.topBar.barView.topAnchor),
            ui.topBar.contentHeightConstraint,
            
            ui.topBar.safeAreaFillView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ui.topBar.safeAreaFillView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ui.topBar.safeAreaFillView.topAnchor.constraint(equalTo: view.topAnchor),
            ui.topBar.safeAreaFillView.bottomAnchor.constraint(equalTo: ui.topBar.barView.topAnchor),
            
            ui.topBarButtons.leftLeadingConstraint,
            ui.topBarButtons.leftStack.centerYAnchor.constraint(equalTo: ui.topBar.contentView.centerYAnchor),
            ui.topBarButtons.leftWidthConstraint,
            ui.topBarButtons.leftHeightConstraint,
            
            ui.topBarButtons.rightTrailingConstraint,
            ui.topBarButtons.rightStack.centerYAnchor.constraint(equalTo: ui.topBar.contentView.centerYAnchor),
            ui.topBarButtons.rightWidthConstraint,
            ui.topBarButtons.rightHeightConstraint,
            
            ui.tabBar.collectionView.leadingAnchor.constraint(equalTo: ui.topBar.barView.leadingAnchor),
            ui.tabBar.collectionView.trailingAnchor.constraint(equalTo: ui.topBar.barView.trailingAnchor),
            ui.tabBar.collectionView.topAnchor.constraint(equalTo: ui.topBar.contentView.bottomAnchor),
            ui.tabBar.heightConstraint,
            
            ui.tabOverview.containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ui.tabOverview.containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ui.tabOverview.containerView.topAnchor.constraint(equalTo: view.topAnchor),
            ui.tabOverview.containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ui.tabOverviewCollection.tabsCollection.leadingAnchor.constraint(equalTo: ui.tabOverview.containerView.safeAreaLayoutGuide.leadingAnchor),
            ui.tabOverviewCollection.tabsCollection.trailingAnchor.constraint(equalTo: ui.tabOverview.containerView.safeAreaLayoutGuide.trailingAnchor),
            ui.tabOverviewCollection.topPhoneConstraint,
            ui.tabOverviewCollection.bottomPhoneConstraint,
            
            ui.tabOverviewCollection.privateTabsCollection.leadingAnchor.constraint(equalTo: ui.tabOverview.containerView.safeAreaLayoutGuide.leadingAnchor),
            ui.tabOverviewCollection.privateTabsCollection.trailingAnchor.constraint(equalTo: ui.tabOverview.containerView.safeAreaLayoutGuide.trailingAnchor),
            ui.tabOverviewCollection.privateTopPhoneConstraint,
            ui.tabOverviewCollection.privateBottomPhoneConstraint,
            
            ui.tabOverviewBottomBar.barView.leadingAnchor.constraint(equalTo: ui.tabOverview.containerView.leadingAnchor),
            ui.tabOverviewBottomBar.barView.trailingAnchor.constraint(equalTo: ui.tabOverview.containerView.trailingAnchor),
            ui.tabOverviewBottomBar.bottomConstraint,
            ui.tabOverviewBottomBar.heightConstraint,
            
            ui.tabOverviewTopBar.barView.leadingAnchor.constraint(equalTo: ui.tabOverview.containerView.leadingAnchor),
            ui.tabOverviewTopBar.barView.trailingAnchor.constraint(equalTo: ui.tabOverview.containerView.trailingAnchor),
            ui.tabOverviewTopBar.barView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            ui.tabOverviewTopBar.heightConstraint,
        ].compactMap { $0 })
        
        ui.addressBarPadLeadingConstraint.isActive = false
        ui.addressBarPadTrailingConstraint.isActive = false
        ui.addressBarCompactPadLeadingConstraint.isActive = false
        ui.addressBarCompactPadTrailingConstraint.isActive = false
        ui.addressBarPadCenterYConstraint.isActive = false
        ui.addressBarPadHeightConstraint.isActive = false
        ui.bottomToolbarCompactPadTopConstraint.isActive = false
        ui.tabOverviewCollection.topPadConstraint.isActive = false
        ui.tabOverviewCollection.bottomPadConstraint.isActive = false
        ui.tabOverviewCollection.privateTopPadConstraint.isActive = false
        ui.tabOverviewCollection.privateBottomPadConstraint.isActive = false
        ui.geckoBottomCompactPadConstraint.isActive = false
        ui.keyboardDismissButton.trailingPadConstraint.isActive = false
        ui.keyboardDismissButton.trailingCompactPadConstraint.isActive = false
        
        view.sendSubviewToBack(ui.bottomContainer.bottomSafeAreaFillView)
    }
    
    func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func applyChromeLayout(animated: Bool) {
        updateChromeLayoutState()
        
        let layoutBlock = {
            self.controller.view.layoutIfNeeded()
            self.controller.browserUI.tabOverviewCollection.applyTransforms()
            self.updatePhoneDismissKeyboardButtonShadowPath()
        }
        
        if animated {
            UIView.animate(withDuration: 0.22, animations: layoutBlock)
        } else {
            layoutBlock()
        }
    }
    
    private func updateChromeLayoutState() {
        let ui = controller.browserUI
        let pad = controller.usesPadChrome
        let compactPad = controller.usesCompactPadChrome
        let isInFullscreenMedia = controller.isInFullscreenMedia
        
        if isInFullscreenMedia {
            applyMediaFullscreenLayoutState()
            controller.updateNavigationButtons()
            return
        }
        
        setAddressBarHost(isPad: pad)
        setKeyboardDismissButtonHost(isPad: pad)
        ui.topBar.topConstraint.constant = resolvedPadTopInset()
        let shouldShowGeckoBehindKeyboard = !pad
        && controller.isSearchFocused
        && keyboardHeight > 0
        && !controller.tabOverviewPresentation.isVisible
        let shouldPinSearchFocusedGeckoFrame = !pad
        && controller.isSearchFocused
        && !controller.tabOverviewPresentation.isVisible
        let geckoPhoneOffset = resolvedGeckoPhoneVerticalOffset(
            shouldShowGeckoBehindKeyboard: shouldShowGeckoBehindKeyboard
        )
        let isLandscape: Bool
        if let orientation = controller.currentInterfaceOrientationForLayout() {
            isLandscape = orientation.isLandscape
        } else {
            isLandscape = controller.view.bounds.width > controller.view.bounds.height
        }
        
        ui.geckoTopPhoneConstraint.constant = !pad ? -geckoPhoneOffset : 0
        ui.geckoBottomPhoneConstraint.constant = !pad ? -geckoPhoneOffset : 0
        ui.geckoBottomPhoneSearchPinnedConstraint.constant = -94
        ui.geckoBottomPhoneKeyboardOverlayConstraint.constant = 0
        ui.geckoTopPadConstraint.constant = pad ? -geckoPhoneOffset : 0
        ui.geckoBottomCompactPadConstraint.constant = pad && compactPad ? -geckoPhoneOffset : 0
        ui.geckoBottomPadConstraint.constant = pad && !compactPad ? -geckoPhoneOffset : 0
        
        ui.geckoTopPhoneConstraint.isActive = !pad
        ui.geckoBottomPhoneConstraint.isActive = !pad && !shouldPinSearchFocusedGeckoFrame && !shouldShowGeckoBehindKeyboard
        ui.geckoBottomPhoneSearchPinnedConstraint.isActive = shouldPinSearchFocusedGeckoFrame
        ui.geckoBottomPhoneKeyboardOverlayConstraint.isActive = shouldShowGeckoBehindKeyboard && !shouldPinSearchFocusedGeckoFrame
        ui.geckoLeadingPhoneConstraint.isActive = !pad
        ui.geckoTrailingPhoneConstraint.isActive = !pad
        ui.geckoTopPadConstraint.isActive = pad
        ui.geckoBottomPadConstraint.isActive = pad && !compactPad
        ui.geckoBottomCompactPadConstraint.isActive = compactPad
        ui.geckoLeadingPadConstraint.isActive = pad
        ui.geckoTrailingPadConstraint.isActive = pad
        ui.geckoTopFullscreenConstraint.isActive = false
        ui.geckoBottomFullscreenConstraint.isActive = false
        
        let phoneOverview = controller.usesBottomPhoneOverview
        ui.tabOverviewCollection.topPhoneConstraint.isActive = phoneOverview
        ui.tabOverviewCollection.bottomPhoneConstraint.isActive = phoneOverview
        ui.tabOverviewCollection.topPadConstraint.isActive = !phoneOverview
        ui.tabOverviewCollection.bottomPadConstraint.isActive = !phoneOverview
        ui.tabOverviewCollection.privateTopPhoneConstraint.isActive = phoneOverview
        ui.tabOverviewCollection.privateBottomPhoneConstraint.isActive = phoneOverview
        ui.tabOverviewCollection.privateTopPadConstraint.isActive = !phoneOverview
        ui.tabOverviewCollection.privateBottomPadConstraint.isActive = !phoneOverview
        
        let activeTabs = controller.tabManager.selectedTabMode == .private ? controller.tabManager.privateTabs : controller.tabManager.regularTabs
        let showsTabBar = pad && !controller.tabOverviewPresentation.isVisible && activeTabs.count > 1 && (!controller.isPad ? Prefs.AppearanceSettings.showsLandscapeTabBar && isLandscape : true)
        let showsCompactPadBottomToolbar = compactPad && !controller.tabOverviewPresentation.isVisible
        ui.topBar.barView.isHidden = !pad
        ui.topBar.safeAreaFillView.isHidden = !pad
        ui.tabBar.collectionView.isHidden = !showsTabBar
        ui.topBar.heightConstraint.constant = 52 + (showsTabBar ? 36 : 0)
        ui.tabBar.heightConstraint.constant = showsTabBar ? 36 : 0
        
        ui.bottomContainer.containerView.isHidden = (!showsCompactPadBottomToolbar && pad) || controller.tabOverviewPresentation.isVisible
        ui.bottomContainer.bottomSafeAreaFillView.isHidden = (!showsCompactPadBottomToolbar && pad) || controller.tabOverviewPresentation.isVisible
        ui.bottomContainerHeightConstraint.constant = compactPad ? 44 : (controller.isSearchFocused ? 58 : 94)
        ui.bottomContainer.containerView.backgroundColor = controller.isSearchFocused && !pad ? .clear : .reynardSystemGray6
        ui.bottomContainer.bottomSafeAreaFillView.backgroundColor = controller.isSearchFocused && !pad ? .clear : .reynardSystemGray6
        ui.bottomToolbar.alpha = compactPad ? 1 : (controller.isSearchFocused ? 0 : 1)
        ui.bottomToolbar.setButtonsHidden(false)
        
        ui.tabOverviewTopBar.barView.isHidden = phoneOverview
        ui.tabOverviewBottomBar.barView.isHidden = !phoneOverview
        ui.tabOverviewBarButtons.attach(to: phoneOverview ? ui.tabOverviewBottomBar.barView : ui.tabOverviewTopBar.barView, verticalPhoneMode: phoneOverview)
        ui.tabOverviewBarButtons.setTabCount(controller.regularTabCount())
        ui.topBarButtons.updateLayout(isPadLayout: controller.isPad, showsCompactPadChrome: compactPad, sidebarVisible: controller.isLibrarySidebarVisible)
        ui.topBarButtons.leftStack.isHidden = compactPad
        ui.topBarButtons.rightStack.isHidden = compactPad
        ui.topBarButtons.leftWidthConstraint.constant = compactPad ? 0 : resolvedTopBarLeftWidth(
            isPadLayout: controller.isPad,
            sidebarVisible: controller.isLibrarySidebarVisible,
            showsDownloads: ui.topBarButtons.downloadButton.isShowingDownloads
        )
        ui.topBarButtons.rightWidthConstraint.constant = compactPad ? 0 : 126
        
        let showDismissButton = controller.isSearchFocused && !controller.tabOverviewPresentation.isVisible
        ui.addressBarPhoneLeadingConstraint.isActive = !pad
        ui.addressBarPhoneTopConstraint.isActive = !pad
        ui.addressBarPhoneHeightConstraint.isActive = !pad
        ui.addressBarPhoneTrailingFullConstraint.isActive = !pad && !showDismissButton
        ui.addressBarPhoneTrailingFocusedConstraint.isActive = showDismissButton
        
        ui.addressBarPadLeadingConstraint.isActive = pad && !compactPad
        ui.addressBarPadTrailingConstraint.isActive = pad && !compactPad && !showDismissButton
        ui.addressBarCompactPadLeadingConstraint.isActive = pad && compactPad
        ui.addressBarCompactPadTrailingConstraint.isActive = pad && compactPad && !showDismissButton
        ui.addressBarPadCenterYConstraint.isActive = pad
        ui.addressBarPadHeightConstraint.isActive = pad
        ui.keyboardDismissButton.trailingPhoneConstraint.isActive = !pad
        ui.keyboardDismissButton.trailingPadConstraint.isActive = pad && !compactPad
        ui.keyboardDismissButton.trailingCompactPadConstraint.isActive = pad && compactPad
        
        ui.bottomToolbarTopConstraint.isActive = !pad && !compactPad
        ui.bottomToolbarCompactPadTopConstraint.isActive = compactPad
        ui.keyboardDismissButton.centerYConstraint.isActive = true
        
        ui.keyboardDismissButton.button.isHidden = !showDismissButton
        let dismissButtonSize = pad ? ui.addressBarPadHeightConstraint.constant : ui.addressBarPhoneHeightConstraint.constant
        ui.keyboardDismissButton.widthConstraint.constant = dismissButtonSize
        ui.keyboardDismissButton.heightConstraint.constant = dismissButtonSize
        ui.keyboardDismissButton.button.layer.cornerRadius = dismissButtonSize / 2
        ui.keyboardDismissButton.button.layer.shadowOpacity = pad ? 0 : 0.2
        ui.addressBar.setShadowEnabled(!pad)
        ui.addressBar.setHidePlaceholderIcon(controller.usesTopPhoneAddressBar || controller.usesPadChrome)
        
        if controller.isSearchScrollMode && controller.searchViewController.parent != nil {
            if controller.usesDetachedSuggestions {
                ui.bottomToolbar.alpha = 0
                ui.bottomToolbar.setButtonsHidden(false)
                ui.bottomContainer.containerView.isHidden = true
                ui.bottomContainer.bottomSafeAreaFillView.isHidden = true
            } else {
                ui.bottomToolbar.alpha = 1
                ui.bottomToolbar.setButtonsHidden(true)
            }
            if controller.usesTopPhoneAddressBar || controller.usesPadChrome {
                ui.bottomContainer.containerView.isHidden = true
                ui.bottomContainer.containerView.backgroundColor = .clear
                ui.bottomContainer.bottomSafeAreaFillView.backgroundColor = .clear
                ui.bottomContainer.bottomSafeAreaFillView.isHidden = true
            } else if !controller.usesDetachedSuggestions {
                ui.bottomContainer.containerView.isHidden = false
                ui.bottomContainer.containerView.backgroundColor = .reynardSystemGray6
                ui.bottomContainer.bottomSafeAreaFillView.backgroundColor = .reynardSystemGray6
                ui.bottomContainer.bottomSafeAreaFillView.isHidden = false
            }
        }
        
        controller.updateNavigationButtons()
    }
    
    private func applyMediaFullscreenLayoutState() {
        let ui = controller.browserUI
        let pad = controller.usesPadChrome
        
        setAddressBarHost(isPad: pad)
        setKeyboardDismissButtonHost(isPad: pad)
        ui.topBar.topConstraint.constant = resolvedPadTopInset()
        
        ui.geckoTopPhoneConstraint.isActive = false
        ui.geckoBottomPhoneConstraint.isActive = false
        ui.geckoBottomPhoneSearchPinnedConstraint.isActive = false
        ui.geckoBottomPhoneKeyboardOverlayConstraint.isActive = false
        ui.geckoTopPadConstraint.isActive = false
        ui.geckoBottomPadConstraint.isActive = false
        ui.geckoBottomCompactPadConstraint.isActive = false
        ui.geckoLeadingPhoneConstraint.isActive = !pad
        ui.geckoTrailingPhoneConstraint.isActive = !pad
        ui.geckoLeadingPadConstraint.isActive = pad
        ui.geckoTrailingPadConstraint.isActive = pad
        ui.geckoTopFullscreenConstraint.isActive = true
        ui.geckoBottomFullscreenConstraint.isActive = true
        
        ui.topBar.barView.isHidden = true
        ui.topBar.safeAreaFillView.isHidden = true
        ui.tabBar.collectionView.isHidden = true
        ui.topBar.heightConstraint.constant = 52
        ui.tabBar.heightConstraint.constant = 0
        
        ui.bottomContainer.containerView.isHidden = true
        ui.bottomContainer.bottomSafeAreaFillView.isHidden = true
        ui.bottomContainerBottomConstraint.constant = 0
        ui.bottomContainer.containerView.backgroundColor = .reynardSystemGray6
        ui.bottomContainer.bottomSafeAreaFillView.backgroundColor = .reynardSystemGray6
        
        ui.keyboardDismissButton.button.isHidden = true
        ui.keyboardDismissButton.button.alpha = 0
        ui.keyboardDismissButton.centerYConstraint.isActive = true
        ui.keyboardDismissButton.trailingPhoneConstraint.isActive = !pad
        ui.keyboardDismissButton.trailingPadConstraint.isActive = pad && !controller.usesCompactPadChrome
        ui.keyboardDismissButton.trailingCompactPadConstraint.isActive = pad && controller.usesCompactPadChrome
        
        ui.addressBarPhoneLeadingConstraint.isActive = !pad
        ui.addressBarPhoneTopConstraint.isActive = !pad
        ui.addressBarPhoneHeightConstraint.isActive = !pad
        ui.addressBarPhoneTrailingFullConstraint.isActive = !pad
        ui.addressBarPhoneTrailingFocusedConstraint.isActive = false
        ui.addressBarPadLeadingConstraint.isActive = pad && !controller.usesCompactPadChrome
        ui.addressBarPadTrailingConstraint.isActive = pad && !controller.usesCompactPadChrome
        ui.addressBarCompactPadLeadingConstraint.isActive = pad && controller.usesCompactPadChrome
        ui.addressBarCompactPadTrailingConstraint.isActive = pad && controller.usesCompactPadChrome
        ui.addressBarPadCenterYConstraint.isActive = pad
        ui.addressBarPadHeightConstraint.isActive = pad
        
        ui.tabOverviewTopBar.barView.isHidden = controller.usesBottomPhoneOverview
        ui.tabOverviewBottomBar.barView.isHidden = !controller.usesBottomPhoneOverview
        ui.topBarButtons.leftStack.isHidden = controller.usesCompactPadChrome
        ui.topBarButtons.rightStack.isHidden = controller.usesCompactPadChrome
        ui.bottomToolbarTopConstraint.isActive = !pad && !controller.usesCompactPadChrome
        ui.bottomToolbarCompactPadTopConstraint.isActive = controller.usesCompactPadChrome
        
        ui.bottomToolbar.alpha = 1
        ui.bottomToolbar.setButtonsHidden(false)
        ui.addressBar.setShadowEnabled(!pad)
        ui.addressBar.setHidePlaceholderIcon(controller.usesTopPhoneAddressBar || controller.usesPadChrome)
    }
    
    private func resolvedPadTopInset() -> CGFloat {
        guard controller.isPad,
              controller.splitViewController is BrowserSplitViewController else {
            return controller.view.safeAreaInsets.top
        }
        
        if #available(iOS 13.0, *) {
            if let statusBarHeight = controller.view.window?.windowScene?.statusBarManager?.statusBarFrame.height,
               statusBarHeight > 0 {
                return statusBarHeight
            }
        } else if UIApplication.shared.statusBarFrame.height > 0 {
            return UIApplication.shared.statusBarFrame.height
        }
        
        return 24
    }
    
    private func resolvedTopBarLeftWidth(isPadLayout: Bool, sidebarVisible: Bool, showsDownloads: Bool) -> CGFloat {
        guard isPadLayout else {
            return 126
        }
        
        let visibleButtonCount = (sidebarVisible ? 2 : 3) + (showsDownloads ? 1 : 0)
        let buttonWidth: CGFloat = 30
        let spacing: CGFloat = 10
        return (CGFloat(visibleButtonCount) * buttonWidth) + (CGFloat(max(visibleButtonCount - 1, 0)) * spacing)
    }
    
    func setSearchFocused(_ focused: Bool, animated: Bool) {
        let ui = controller.browserUI
        let usesPadChrome = controller.usesPadChrome
        
        controller.isSearchFocused = focused
        if focused {
            resetFocusedInputRelocation()
        }
        if !usesPadChrome {
            ui.bottomToolbarHeightConstraint.constant = focused ? 0 : 30
            ui.bottomContainerHeightConstraint.constant = focused ? 58 : 94
            ui.bottomContainer.containerView.backgroundColor = focused ? .clear : .reynardSystemGray6
            ui.bottomContainer.bottomSafeAreaFillView.backgroundColor = focused ? .clear : .reynardSystemGray6
        }
        updateChromeLayoutState()
        
        let dismissButtonTargetAlpha: CGFloat = focused ? 1 : 0
        if focused {
            ui.keyboardDismissButton.button.isHidden = false
        }
        
        let animations = {
            if !usesPadChrome {
                ui.bottomToolbar.alpha = focused ? 0 : 1
            }
            ui.keyboardDismissButton.button.alpha = dismissButtonTargetAlpha
            self.controller.view.layoutIfNeeded()
            self.updatePhoneDismissKeyboardButtonShadowPath()
        }
        
        let completion: (Bool) -> Void = { _ in
            if !focused {
                ui.keyboardDismissButton.button.isHidden = true
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let ui = controller.browserUI
        updateKeyboardState(screenFrame: frameValue.cgRectValue)
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        requestFocusedInputMetricsIfNeeded(duration: duration, curve: curve)
        
        let shouldDockChromeToKeyboard = !controller.usesPadChrome
        && controller.isSearchFocused
        && !controller.tabOverviewPresentation.isVisible
        && keyboardHeight > 0
        ui.bottomContainerBottomConstraint.constant = shouldDockChromeToKeyboard ? -keyboardHeight : 0
        updateChromeLayoutState()
        
        UIView.animate(withDuration: duration, delay: 0, options: [curve]) {
            self.controller.view.layoutIfNeeded()
            self.updatePhoneDismissKeyboardButtonShadowPath()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        let ui = controller.browserUI
        
        keyboardHeight = 0
        keyboardFrame = .zero
        resetFocusedInputRelocation()
        ui.bottomContainerBottomConstraint.constant = 0
        updateChromeLayoutState()
        
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: [curve]) {
            self.controller.view.layoutIfNeeded()
            self.updatePhoneDismissKeyboardButtonShadowPath()
        }
    }
    
    private func updatePhoneDismissKeyboardButtonShadowPath() {
        let button = controller.browserUI.keyboardDismissButton.button
        guard !controller.usesPadChrome else {
            button.layer.shadowPath = nil
            return
        }
        guard button.bounds.width > 1, button.bounds.height > 1 else {
            button.layer.shadowPath = nil
            return
        }
        button.layer.shadowPath = UIBezierPath(roundedRect: button.bounds, cornerRadius: button.layer.cornerRadius).cgPath
    }
    
    private func updateKeyboardState(screenFrame: CGRect) {
        keyboardFrame = controller.view.convert(screenFrame, from: nil)
        let overlap = max(0, controller.view.bounds.maxY - keyboardFrame.minY)
        let safeBottom = controller.view.safeAreaInsets.bottom
        keyboardHeight = max(0, overlap - safeBottom)
    }
    
    private func setAddressBarHost(isPad: Bool) {
        let ui = controller.browserUI
        let targetHost = isPad ? ui.topBar.contentView : ui.bottomContainer.containerView
        guard ui.addressBar.superview !== targetHost else {
            return
        }
        
        ui.addressBar.removeFromSuperview()
        targetHost.addSubview(ui.addressBar)
    }
    
    private func setKeyboardDismissButtonHost(isPad: Bool) {
        let ui = controller.browserUI
        let targetHost = isPad ? ui.topBar.contentView : ui.bottomContainer.containerView
        guard ui.keyboardDismissButton.button.superview !== targetHost else {
            return
        }
        
        ui.keyboardDismissButton.button.removeFromSuperview()
        targetHost.addSubview(ui.keyboardDismissButton.button)
    }
    
    private func requestFocusedInputMetricsIfNeeded(duration: TimeInterval, curve: UIView.AnimationOptions) {
        guard !controller.isSearchFocused,
              !controller.tabOverviewPresentation.isVisible,
              keyboardHeight > 0,
              let session = controller.tabManager.selectedTab?.session else {
            focusedInputBottomRatio = nil
            applyFocusedInputRelocation(duration: duration, curve: curve)
            return
        }
        
        focusedInputMetricsTask?.cancel()
        focusedInputMetricsTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            
            let bottomRatio = await session.focusedInputBottomRatio()
            guard !Task.isCancelled else {
                return
            }
            
            if let bottomRatio {
                self.focusedInputBottomRatio = bottomRatio
            }
            self.applyFocusedInputRelocation(duration: duration, curve: curve)
        }
    }
    
    private func applyFocusedInputRelocation(duration: TimeInterval, curve: UIView.AnimationOptions) {
        let nextOffset = resolvedGeckoPhoneVerticalOffset(
            shouldShowGeckoBehindKeyboard: false
        )
        guard abs(nextOffset - geckoPhoneVerticalOffset) > 0.5 else {
            return
        }
        
        geckoPhoneVerticalOffset = nextOffset
        updateChromeLayoutState()
        UIView.animate(withDuration: duration, delay: 0, options: [curve, .beginFromCurrentState, .allowUserInteraction]) {
            self.controller.view.layoutIfNeeded()
            self.updatePhoneDismissKeyboardButtonShadowPath()
        }
    }
    
    private func resetFocusedInputRelocation() {
        focusedInputMetricsTask?.cancel()
        focusedInputMetricsTask = nil
        focusedInputBottomRatio = nil
        geckoPhoneVerticalOffset = 0
    }
    
    private func resolvedGeckoPhoneVerticalOffset(
        shouldShowGeckoBehindKeyboard: Bool
    ) -> CGFloat {
        guard !controller.isSearchFocused,
              !controller.tabOverviewPresentation.isVisible,
              !shouldShowGeckoBehindKeyboard,
              keyboardHeight > 0,
              let bottomRatio = focusedInputBottomRatio else {
            return 0
        }
        
        controller.view.layoutIfNeeded()
        let geckoFrame = controller.browserUI.geckoView.frame
        guard geckoFrame.height > 1 else {
            return 0
        }
        
        let unshiftedGeckoMinY: CGFloat
        if controller.usesPadChrome {
            unshiftedGeckoMinY = controller.browserUI.topBar.barView.frame.maxY
        } else {
            unshiftedGeckoMinY = controller.view.safeAreaLayoutGuide.layoutFrame.minY
        }
        
        let currentGeckoShift = max(0, unshiftedGeckoMinY - geckoFrame.minY)
        let unshiftedGeckoMaxY = geckoFrame.maxY + currentGeckoShift
        let keyboardOverlap = max(0, unshiftedGeckoMaxY - keyboardFrame.minY)
        guard keyboardOverlap > 0 else {
            return 0
        }
        
        let focusBottom = geckoFrame.height * bottomRatio
        let visibleBottom = max(0, geckoFrame.height - keyboardOverlap - 12)
        return min(keyboardOverlap, max(0, focusBottom - visibleBottom))
    }
}

@objc
private final class WeakObjectBox: NSObject {
    weak var value: AnyObject?
    
    init(_ value: AnyObject?) {
        self.value = value
    }
}

// Tab Overview & Tab Bar
extension BrowserViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    var activeReorderingCell: UICollectionViewCell? {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.activeReorderingCell) as? WeakObjectBox)?
                .value as? UICollectionViewCell
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.activeReorderingCell,
                WeakObjectBox(newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var activeDragSnapshotView: UIView? {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.activeDragSnapshotView) as? WeakObjectBox)?
                .value as? UIView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.activeDragSnapshotView,
                WeakObjectBox(newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var pendingReorderStartWorkItem: DispatchWorkItem? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.pendingReorderStartWorkItem) as? DispatchWorkItem
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.pendingReorderStartWorkItem,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var isInteractiveReorderActive: Bool {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.isInteractiveReorderActive) as? NSNumber)?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.isInteractiveReorderActive,
                NSNumber(value: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var activeDragOffset: CGPoint {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.activeDragOffset) as? NSValue)?.cgPointValue ?? .zero
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.activeDragOffset,
                NSValue(cgPoint: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var activeTabBarReorderSourceIndex: Int? {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.activeTabBarReorderSourceIndex) as? NSNumber)?.intValue
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.activeTabBarReorderSourceIndex,
                newValue.map { NSNumber(value: $0) },
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var activeTabBarReorderTargetIndex: Int? {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.activeTabBarReorderTargetIndex) as? NSNumber)?.intValue
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIAssociatedKeys.activeTabBarReorderTargetIndex,
                newValue.map { NSNumber(value: $0) },
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    private var tabOverviewCardAnimationState: TabOverviewCardAnimationState {
        if let state = objc_getAssociatedObject(
            self,
            &UIAssociatedKeys.tabOverviewCardAnimationState
        ) as? TabOverviewCardAnimationState {
            return state
        }
        
        let state = TabOverviewCardAnimationState()
        objc_setAssociatedObject(
            self,
            &UIAssociatedKeys.tabOverviewCardAnimationState,
            state,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return state
    }
    
    func usesExpandedTabBarWidth(for tab: Tab) -> Bool {
        let activeTabs = tabManager.selectedTabMode == .private ? tabManager.privateTabs : tabManager.regularTabs
        let selectedTabID = tabManager.selectedTab?.id
        let pendingTabID = pendingExpandedTabBarIndex.flatMap { activeTabs[safe: $0]?.id }
        return tab.id == selectedTabID || tab.id == pendingTabID
    }
    
    func overviewTabs(for mode: TabOverviewCollection.Mode) -> [Tab] {
        switch mode {
        case .privateTabs:
            return tabManager.privateTabs
        case .regularTabs:
            return tabManager.regularTabs
        }
    }
    
    func overviewMode(for collectionView: UICollectionView) -> TabOverviewCollection.Mode? {
        if collectionView === browserUI.tabOverviewCollection.privateTabsCollection {
            return .privateTabs
        }
        
        if collectionView === browserUI.tabOverviewCollection.tabsCollection {
            return .regularTabs
        }
        
        return nil
    }
    
    func overviewItemIndex(forTabAt tabIndex: Int, mode: TabOverviewCollection.Mode? = nil) -> Int? {
        let resolvedMode = mode ?? browserUI.tabOverviewCollection.mode
        guard tabManager.selectedTabMode == (resolvedMode == .privateTabs ? .private : .regular),
              (tabManager.selectedTabMode == .private ? tabManager.privateTabs : tabManager.regularTabs).indices.contains(tabIndex) else {
            return nil
        }
        return tabIndex
    }
    
    func currentOverviewCollectionView() -> UICollectionView {
        switch browserUI.tabOverviewCollection.mode {
        case .privateTabs:
            return browserUI.tabOverviewCollection.privateTabsCollection
        case .regularTabs:
            return browserUI.tabOverviewCollection.tabsCollection
        }
    }
    
    // For anyone wondering what's the fake insertion slot is,
    // it is a transparent cell inserted at the end of the
    // collection view so the overview can scroll to the end
    // first before the new tab card is inserted, which makes
    // the new tab card appear from the bottom of the screen.
    private func hasOverviewFakeInsertionSlot(for mode: TabOverviewCollection.Mode) -> Bool {
        tabOverviewCardAnimationState.fakeInsertionMode == mode
    }
    
    private func isOverviewFakeInsertionSlot(in collectionView: UICollectionView, at indexPath: IndexPath) -> Bool {
        guard let mode = overviewMode(for: collectionView),
              hasOverviewFakeInsertionSlot(for: mode) else {
            return false
        }
        
        return indexPath.item == overviewTabs(for: mode).count
    }
    
    func refreshOverviewCardAnimationSnapshot() {
        let regularIDs = tabManager.regularTabs.map(\.id)
        let privateIDs = tabManager.privateTabs.map(\.id)
        updateOverviewCardAnimationSnapshot(regularIDs: regularIDs, privateIDs: privateIDs)
    }
    
    func reloadOverviewCollections() {
        tabOverviewCardAnimationState.fakeInsertionMode = nil
        browserUI.tabOverviewCollection.tabsCollection.reloadData()
        browserUI.tabOverviewCollection.privateTabsCollection.reloadData()
        refreshOverviewCardAnimationSnapshot()
    }
    
    func prepareOverviewFakeInsertionSlot(for mode: TabOverviewCollection.Mode, completion: @escaping () -> Void) {
        let state = tabOverviewCardAnimationState
        guard tabOverviewPresentation.isVisible,
              !tabOverviewPresentation.isTransitionRunning,
              state.fakeInsertionMode == nil else {
            completion()
            return
        }
        
        let collectionView: UICollectionView
        let itemCount: Int
        switch mode {
        case .privateTabs:
            collectionView = browserUI.tabOverviewCollection.privateTabsCollection
            itemCount = tabManager.privateTabs.count
        case .regularTabs:
            collectionView = browserUI.tabOverviewCollection.tabsCollection
            itemCount = tabManager.regularTabs.count
        }
        
        let fakeIndexPath = IndexPath(item: itemCount, section: 0)
        state.fakeInsertionMode = mode
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: [fakeIndexPath])
            } completion: { _ in
                guard state.fakeInsertionMode == mode,
                      collectionView.numberOfItems(inSection: fakeIndexPath.section) > fakeIndexPath.item else {
                    completion()
                    return
                }
                
                collectionView.layoutIfNeeded()
                guard let targetContentOffset = self.overviewContentOffsetForBottomAlignedItem(at: fakeIndexPath, in: collectionView) else {
                    completion()
                    return
                }
                
                let scrollDuration: TimeInterval = 0.4
                UIView.animate(withDuration: scrollDuration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: [.curveEaseInOut, .allowUserInteraction]) {
                    collectionView.contentOffset = targetContentOffset
                }
                
                self.completeWhenOverviewScrollReachesTarget(
                    collectionView,
                    targetContentOffset: targetContentOffset,
                    timeout: scrollDuration,
                    completion: completion
                )
            }
        }
    }
    
    private func completeWhenOverviewScrollReachesTarget(
        _ collectionView: UICollectionView,
        targetContentOffset: CGPoint,
        timeout: TimeInterval,
        completion: @escaping () -> Void
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        
        func checkScrollPosition() {
            let distance = abs(collectionView.contentOffset.y - targetContentOffset.y)
            if distance <= 1 || Date() >= deadline {
                completion()
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / 60.0)) {
                checkScrollPosition()
            }
        }
        
        DispatchQueue.main.async {
            checkScrollPosition()
        }
    }
    
    private func overviewContentOffsetForBottomAlignedItem(
        at indexPath: IndexPath,
        in collectionView: UICollectionView
    ) -> CGPoint? {
        collectionView.layoutIfNeeded()
        guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else {
            return nil
        }
        
        let inset = collectionView.adjustedContentInset
        let minimumY = -inset.top
        let maximumY = max(minimumY, collectionView.contentSize.height - collectionView.bounds.height + inset.bottom)
        let targetY = attributes.frame.maxY - collectionView.bounds.height + inset.bottom
        let clampedY = min(max(targetY, minimumY), maximumY)
        return CGPoint(x: collectionView.contentOffset.x, y: clampedY)
    }
    
    func refreshVisibleOverviewCard(at index: Int, mode: TabMode) {
        let overviewMode: TabOverviewCollection.Mode = mode == .private ? .privateTabs : .regularTabs
        let tabs = overviewTabs(for: overviewMode)
        guard tabs.indices.contains(index) else {
            return
        }
        
        let collectionView = overviewMode == .privateTabs ?
        browserUI.tabOverviewCollection.privateTabsCollection :
        browserUI.tabOverviewCollection.tabsCollection
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? TabOverviewCard else {
            return
        }
        
        cell.configure(tab: tabs[index])
    }
    
    func applyOverviewTabChanges() {
        let state = tabOverviewCardAnimationState
        let regularIDs = tabManager.regularTabs.map(\.id)
        let privateIDs = tabManager.privateTabs.map(\.id)
        
        guard state.hasIdentitySnapshot,
              tabOverviewPresentation.isVisible,
              !tabOverviewPresentation.isTransitionRunning else {
            reloadOverviewCollections()
            return
        }
        
        let previousRegularCount = state.regularTabIDs.count
        let previousPrivateCount = state.privateTabIDs.count
        let fakeInsertionMode = state.fakeInsertionMode
        let regularFakeDeletion = fakeInsertionMode == .regularTabs ? [IndexPath(item: previousRegularCount, section: 0)] : []
        let privateFakeDeletion = fakeInsertionMode == .privateTabs ? [IndexPath(item: previousPrivateCount, section: 0)] : []
        let regularInsertions = insertedIndexPaths(previousIDs: state.regularTabIDs, currentIDs: regularIDs)
        let privateInsertions = insertedIndexPaths(previousIDs: state.privateTabIDs, currentIDs: privateIDs)
        let regularDeletions = deletedIndexPaths(previousIDs: state.regularTabIDs, currentIDs: regularIDs)
        let privateDeletions = deletedIndexPaths(previousIDs: state.privateTabIDs, currentIDs: privateIDs)
        let hasInsertions = !regularInsertions.isEmpty || !privateInsertions.isEmpty
        let hasDeletions = !regularDeletions.isEmpty || !privateDeletions.isEmpty
        let isPureInsertion = previousRegularCount + regularInsertions.count == regularIDs.count &&
        previousPrivateCount + privateInsertions.count == privateIDs.count
        let isPureDeletion = regularIDs.count + regularDeletions.count == previousRegularCount &&
        privateIDs.count + privateDeletions.count == previousPrivateCount
        
        updateOverviewCardAnimationSnapshot(regularIDs: regularIDs, privateIDs: privateIDs)
        state.fakeInsertionMode = nil
        
        guard (hasInsertions && isPureInsertion) ||
                (hasDeletions && isPureDeletion) else {
            reloadOverviewCollections()
            return
        }
        
        if !regularInsertions.isEmpty {
            insertOverviewItems(
                in: browserUI.tabOverviewCollection.tabsCollection,
                at: regularInsertions,
                deletingFakeSlotAt: regularFakeDeletion,
                previousItemCount: previousRegularCount
            )
        }
        
        if !regularDeletions.isEmpty {
            browserUI.tabOverviewCollection.tabsCollection.layoutIfNeeded()
            browserUI.tabOverviewCollection.tabsCollection.performBatchUpdates {
                browserUI.tabOverviewCollection.tabsCollection.deleteItems(at: regularDeletions)
            }
        }
        
        if !privateInsertions.isEmpty {
            insertOverviewItems(
                in: browserUI.tabOverviewCollection.privateTabsCollection,
                at: privateInsertions,
                deletingFakeSlotAt: privateFakeDeletion,
                previousItemCount: previousPrivateCount
            )
        }
        
        if !privateDeletions.isEmpty {
            browserUI.tabOverviewCollection.privateTabsCollection.layoutIfNeeded()
            browserUI.tabOverviewCollection.privateTabsCollection.performBatchUpdates {
                browserUI.tabOverviewCollection.privateTabsCollection.deleteItems(at: privateDeletions)
            }
        }
    }
    
    private func insertOverviewItems(
        in collectionView: UICollectionView,
        at insertionIndexPaths: [IndexPath],
        deletingFakeSlotAt fakeDeletionIndexPaths: [IndexPath],
        previousItemCount: Int
    ) {
        if fakeDeletionIndexPaths.isEmpty {
            prepareOverviewCollectionForInsertions(
                collectionView,
                insertionIndexPaths: insertionIndexPaths,
                previousItemCount: previousItemCount
            )
        } else {
            collectionView.layoutIfNeeded()
        }
        collectionView.performBatchUpdates {
            if !fakeDeletionIndexPaths.isEmpty {
                collectionView.deleteItems(at: fakeDeletionIndexPaths)
            }
            collectionView.insertItems(at: insertionIndexPaths)
        }
    }
    
    private func updateOverviewCardAnimationSnapshot(regularIDs: [UUID], privateIDs: [UUID]) {
        let state = tabOverviewCardAnimationState
        state.hasIdentitySnapshot = true
        state.regularTabIDs = regularIDs
        state.privateTabIDs = privateIDs
    }
    
    private func insertedIndexPaths(previousIDs: [UUID], currentIDs: [UUID]) -> [IndexPath] {
        let previousIDSet = Set(previousIDs)
        var insertedIndexPaths: [IndexPath] = []
        
        for index in currentIDs.indices where !previousIDSet.contains(currentIDs[index]) {
            insertedIndexPaths.append(IndexPath(item: index, section: 0))
        }
        
        return insertedIndexPaths
    }
    
    private func deletedIndexPaths(previousIDs: [UUID], currentIDs: [UUID]) -> [IndexPath] {
        let currentIDSet = Set(currentIDs)
        var deletedIndexPaths: [IndexPath] = []
        
        for index in previousIDs.indices where !currentIDSet.contains(previousIDs[index]) {
            deletedIndexPaths.append(IndexPath(item: index, section: 0))
        }
        
        return deletedIndexPaths
    }
    
    private func prepareOverviewCollectionForInsertions(
        _ collectionView: UICollectionView,
        insertionIndexPaths: [IndexPath],
        previousItemCount: Int
    ) {
        guard previousItemCount > 0,
              let insertionIndexPath = insertionIndexPaths.last else {
            collectionView.layoutIfNeeded()
            return
        }
        
        let anchorItem = min(max(insertionIndexPath.item - 1, 0), previousItemCount - 1)
        collectionView.scrollToItem(
            at: IndexPath(item: anchorItem, section: 0),
            at: .bottom,
            animated: false
        )
        collectionView.layoutIfNeeded()
    }
    
    func regularTabCount() -> Int {
        tabManager.regularTabs.count
    }
    
    func restoreTabOverviewMode() {
        let snapshot = TabManagementStore.shared.loadSnapshot()
        let restoredMode: TabMode
        if snapshot.selectedTabMode == .private,
           !snapshot.privateTabs.isEmpty {
            restoredMode = .private
        } else if snapshot.selectedTabMode == .regular,
                  !snapshot.regularTabs.isEmpty {
            restoredMode = .regular
        } else if !snapshot.regularTabs.isEmpty {
            restoredMode = .regular
        } else if !snapshot.privateTabs.isEmpty {
            restoredMode = .private
        } else {
            restoredMode = .regular
        }
        
        let mode: TabOverviewCollection.Mode = restoredMode == .private ? .privateTabs : .regularTabs
        browserUI.tabOverviewBarButtons.modeControl.selectedSegmentIndex = mode.rawValue
        browserUI.tabOverviewCollection.setMode(mode, in: browserUI.tabOverview.containerView, animated: false)
        browserUI.tabOverviewBarButtons.setTabCount(regularTabCount())
        refreshOverviewCardAnimationSnapshot()
    }
    
    func setTabOverviewVisible(_ visible: Bool, animated: Bool) {
        if visible && usesDetachedSuggestions {
            hideSuggestionsNow()
        }
        tabOverviewPresentation.setVisible(visible, animated: animated)
    }
    
    @objc func tabOverviewModeChanged(_ segmentedControl: UISegmentedControl) {
        let mode = TabOverviewCollection.Mode(rawValue: segmentedControl.selectedSegmentIndex) ?? .regularTabs
        browserUI.tabOverviewCollection.setMode(mode, in: browserUI.tabOverview.containerView, animated: true)
        TabManagementStore.shared.saveLastTabOverview(mode == .privateTabs ? .private : .regular)
        browserUI.tabOverviewBarButtons.setTabCount(regularTabCount())
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection {
            let count = tabManager.privateTabs.count
            let hasFakeInsertionSlot = hasOverviewFakeInsertionSlot(for: .privateTabs)
            collectionView.backgroundView?.isHidden = count != 0 || hasFakeInsertionSlot
            return count + (hasFakeInsertionSlot ? 1 : 0)
        }
        
        if collectionView === self.browserUI.tabOverviewCollection.tabsCollection {
            return tabManager.regularTabs.count + (hasOverviewFakeInsertionSlot(for: .regularTabs) ? 1 : 0)
        }
        
        return (tabManager.selectedTabMode == .private ? tabManager.privateTabs : tabManager.regularTabs).count
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if isOverviewFakeInsertionSlot(in: collectionView, at: indexPath) {
            return false
        }
        
        return collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
        collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection ||
        collectionView === self.browserUI.tabBar.collectionView
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
            collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection {
            if isOverviewFakeInsertionSlot(in: collectionView, at: indexPath) {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TabOverviewCollection.fakeInsertionReuseIdentifier,
                    for: indexPath
                )
                cell.isHidden = true
                cell.contentView.alpha = 0
                cell.backgroundColor = .clear
                return cell
            }
            
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TabOverviewCard.reuseIdentifier,
                for: indexPath
            ) as? TabOverviewCard else {
                return UICollectionViewCell()
            }
            cell.isHidden = false
            
            guard let mode = overviewMode(for: collectionView),
                  overviewTabs(for: mode).indices.contains(indexPath.item) else {
                return UICollectionViewCell()
            }
            
            let tab = overviewTabs(for: mode)[indexPath.item]
            cell.configure(tab: tab)
            cell.onClose = { [weak self, weak collectionView, weak cell] in
                guard let self,
                      let collectionView,
                      let cell,
                      let currentIndexPath = collectionView.indexPath(for: cell),
                      let overviewMode = self.overviewMode(for: collectionView) else {
                    return
                }
                self.pendingExpandedTabBarIndex = nil
                self.tabManager.removeTab(at: currentIndexPath.item, mode: overviewMode == .privateTabs ? .private : .regular)
            }
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TabBarCell.reuseIdentifier,
            for: indexPath
        ) as? TabBarCell else {
            return UICollectionViewCell()
        }
        
        let activeTabs = self.tabManager.selectedTabMode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs
        let tab = activeTabs[indexPath.item]
        let metrics = self.browserUI.tabBar.layoutMetrics(
            for: indexPath.item,
            fallbackWidth: self.view.bounds.width,
            tabCount: activeTabs.count,
            usesExpandedWidth: { index in
                self.usesExpandedTabBarWidthForLayoutIndex(index)
            }
        )
        cell.configure(
            tab: tab,
            selected: tab.id == self.tabManager.selectedTab?.id,
            layoutMode: metrics.mode,
            itemWidth: metrics.width
        )
        cell.onClose = { [weak self, weak collectionView, weak cell] in
            guard let self,
                  let collectionView,
                  let cell,
                  let currentIndexPath = collectionView.indexPath(for: cell) else {
                return
            }
            self.closeTab(at: currentIndexPath.item)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
            collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection {
            guard let overviewMode = overviewMode(for: collectionView),
                  overviewTabs(for: overviewMode).indices.contains(indexPath.item) else {
                return
            }
            
            let previewImage: UIImage?
            if let cell = collectionView.cellForItem(at: indexPath) as? TabOverviewCard {
                previewImage = cell.currentPreviewImage
            } else {
                previewImage = overviewTabs(for: overviewMode)[safe: indexPath.item]?.thumbnail
            }
            
            self.tabOverviewPresentation.prepareDismissSelection(
                to: indexPath.item,
                mode: overviewMode == .privateTabs ? .private : .regular,
                previewImage: previewImage
            )
            collectionView.reloadData()
            self.setTabOverviewVisible(false, animated: true)
            return
        }
        
        self.selectTab(at: indexPath.item, animated: true)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        guard collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
                collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection ||
                collectionView === self.browserUI.tabBar.collectionView else {
            return
        }
        
        guard let overviewMode = overviewMode(for: collectionView) else {
            return
        }
        
        self.tabManager.moveTab(
            from: sourceIndexPath.item,
            to: destinationIndexPath.item,
            mode: overviewMode == .privateTabs ? .private : .regular
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard (collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
               collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection),
              let tabCell = cell as? TabOverviewCard,
              let overviewMode = overviewMode(for: collectionView),
              overviewTabs(for: overviewMode).indices.contains(indexPath.item) else {
            return
        }
        
        tabCell.setNeedsLayout()
        tabCell.layoutIfNeeded()
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
            collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection {
            return self.tabOverviewPresentation.itemSize(for: collectionView)
        }
        
        if collectionView === self.browserUI.tabBar.collectionView {
            let metrics = self.browserUI.tabBar.layoutMetrics(
                for: indexPath.item,
                fallbackWidth: self.view.bounds.width,
                tabCount: (self.tabManager.selectedTabMode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs).count,
                usesExpandedWidth: { index in
                    self.usesExpandedTabBarWidthForLayoutIndex(index)
                }
            )
            return CGSize(width: metrics.width, height: collectionView.bounds.height)
        }
        
        guard let overviewMode = overviewMode(for: collectionView),
              overviewTabs(for: overviewMode).indices.contains(indexPath.item) else {
            return CGSize(width: 120, height: 30)
        }
        
        let title = overviewTabs(for: overviewMode)[indexPath.item].title
        let width = max(120, min(240, (title as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]).width + 52))
        return CGSize(width: width, height: 30)
    }
    
    private func cancelPendingReorderStart() {
        pendingReorderStartWorkItem?.cancel()
        pendingReorderStartWorkItem = nil
    }
    
    private func tabForCurrentTabBarLayout(at index: Int) -> Tab? {
        let activeTabs = self.tabManager.selectedTabMode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs
        guard activeTabs.indices.contains(index) else {
            return nil
        }
        
        guard let sourceIndex = activeTabBarReorderSourceIndex,
              let targetIndex = activeTabBarReorderTargetIndex,
              activeTabs.indices.contains(sourceIndex),
              activeTabs.indices.contains(targetIndex),
              sourceIndex != targetIndex else {
            return activeTabs[index]
        }
        
        var tabs = activeTabs
        let movedTab = tabs.remove(at: sourceIndex)
        tabs.insert(movedTab, at: targetIndex)
        return tabs[index]
    }
    
    private func usesExpandedTabBarWidthForLayoutIndex(_ index: Int) -> Bool {
        guard let tab = tabForCurrentTabBarLayout(at: index) else {
            return false
        }
        return self.usesExpandedTabBarWidth(for: tab)
    }
    
    private func updateTabBarReorderTarget(at location: CGPoint, in collectionView: UICollectionView) {
        guard collectionView === self.browserUI.tabBar.collectionView,
              let targetIndex = collectionView.indexPathForItem(at: location)?.item,
              (self.tabManager.selectedTabMode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs).indices.contains(targetIndex),
              activeTabBarReorderTargetIndex != targetIndex else {
            return
        }
        
        activeTabBarReorderTargetIndex = targetIndex
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func clearTabBarReorderState() {
        activeTabBarReorderSourceIndex = nil
        activeTabBarReorderTargetIndex = nil
    }
    
    private func beginTabBarDragSnapshot(for cell: UICollectionViewCell, in collectionView: UICollectionView, at location: CGPoint) {
        guard let snapshot = cell.snapshotView(afterScreenUpdates: false) else {
            return
        }
        
        let frameInRoot = cell.convert(cell.bounds, to: self.view)
        snapshot.frame = frameInRoot
        snapshot.isUserInteractionEnabled = false
        snapshot.layer.masksToBounds = false
        snapshot.layer.shadowColor = UIColor.reynardChromeShadow.cgColor
        snapshot.layer.shadowOpacity = 0.18
        snapshot.layer.shadowRadius = 10
        snapshot.layer.shadowOffset = CGSize(width: 0, height: 6)
        self.view.addSubview(snapshot)
        self.view.bringSubviewToFront(snapshot)
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            snapshot.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }
        
        cell.isHidden = true
        activeDragSnapshotView = snapshot
        
        let locationInRoot = collectionView.convert(location, to: self.view)
        activeDragOffset = CGPoint(
            x: locationInRoot.x - snapshot.center.x,
            y: locationInRoot.y - snapshot.center.y
        )
    }
    
    private func updateTabBarDragSnapshotPosition(_ location: CGPoint, in collectionView: UICollectionView) {
        guard let snapshot = activeDragSnapshotView else {
            return
        }
        
        let locationInRoot = collectionView.convert(location, to: self.view)
        snapshot.center = CGPoint(
            x: locationInRoot.x - activeDragOffset.x,
            y: locationInRoot.y - activeDragOffset.y
        )
    }
    
    private func endTabBarDragSnapshot() {
        activeDragSnapshotView?.removeFromSuperview()
        activeDragSnapshotView = nil
        activeReorderingCell?.isHidden = false
        activeDragOffset = .zero
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let longPress = gestureRecognizer as? UILongPressGestureRecognizer,
              let collectionView = longPress.view as? UICollectionView,
              collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
                collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection ||
                collectionView === self.browserUI.tabBar.collectionView else {
            return true
        }
        
        let location = longPress.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let cell = collectionView.cellForItem(at: indexPath) else {
            return false
        }
        
        let pointInCell = collectionView.convert(location, to: cell)
        if let overviewCell = cell as? TabOverviewCard {
            return !overviewCell.containsCloseButton(point: pointInCell)
        }
        if let tabBarCell = cell as? TabBarCell {
            return !tabBarCell.containsCloseButton(point: pointInCell)
        }
        return false
    }
    
    @objc func handleOverviewReorderLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let collectionView = gestureRecognizer.view as? UICollectionView,
              collectionView === self.browserUI.tabOverviewCollection.tabsCollection ||
                collectionView === self.browserUI.tabOverviewCollection.privateTabsCollection ||
                collectionView === self.browserUI.tabBar.collectionView else {
            return
        }
        
        let location = gestureRecognizer.location(in: collectionView)
        
        switch gestureRecognizer.state {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: location),
                  let cell = collectionView.cellForItem(at: indexPath) else {
                return
            }
            
            let pointInCell = collectionView.convert(location, to: cell)
            if let overviewCell = cell as? TabOverviewCard,
               overviewCell.containsCloseButton(point: pointInCell) {
                return
            }
            if let tabBarCell = cell as? TabBarCell,
               tabBarCell.containsCloseButton(point: pointInCell) {
                return
            }
            
            activeReorderingCell = cell
            cancelPendingReorderStart()
            if collectionView === self.browserUI.tabBar.collectionView {
                activeTabBarReorderSourceIndex = indexPath.item
                activeTabBarReorderTargetIndex = indexPath.item
                beginTabBarDragSnapshot(for: cell, in: collectionView, at: location)
            }
            if let overviewCell = cell as? TabOverviewCard {
                overviewCell.setReorderLifted(true, animated: true)
            }
            
            let workItem = DispatchWorkItem { [weak self, weak collectionView, weak cell] in
                guard let self,
                      let collectionView,
                      let cell,
                      self.activeReorderingCell === cell,
                      !self.isInteractiveReorderActive else {
                    return
                }
                
                guard collectionView.beginInteractiveMovementForItem(at: indexPath) else {
                    if let overviewCell = cell as? TabOverviewCard {
                        overviewCell.setReorderLifted(false, animated: true)
                    }
                    if collectionView === self.browserUI.tabBar.collectionView {
                        self.endTabBarDragSnapshot()
                        self.clearTabBarReorderState()
                    }
                    self.activeReorderingCell = nil
                    return
                }
                
                self.isInteractiveReorderActive = true
            }
            pendingReorderStartWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: workItem)
            
        case .changed:
            if isInteractiveReorderActive {
                updateTabBarReorderTarget(at: location, in: collectionView)
                collectionView.updateInteractiveMovementTargetPosition(location)
                if collectionView === self.browserUI.tabBar.collectionView {
                    updateTabBarDragSnapshotPosition(location, in: collectionView)
                }
            }
            
        case .ended:
            cancelPendingReorderStart()
            if isInteractiveReorderActive {
                collectionView.endInteractiveMovement()
                isInteractiveReorderActive = false
                if let activeReorderingCell = activeReorderingCell as? TabOverviewCard {
                    activeReorderingCell.setReorderLifted(false, animated: true)
                }
                if collectionView === self.browserUI.tabBar.collectionView {
                    clearTabBarReorderState()
                    collectionView.collectionViewLayout.invalidateLayout()
                    collectionView.layoutIfNeeded()
                    endTabBarDragSnapshot()
                }
                self.activeReorderingCell = nil
            } else if let activeReorderingCell = activeReorderingCell as? TabOverviewCard {
                activeReorderingCell.setReorderLifted(false, animated: true)
                if collectionView === self.browserUI.tabBar.collectionView {
                    endTabBarDragSnapshot()
                    clearTabBarReorderState()
                }
                self.activeReorderingCell = nil
            }
            
        default:
            cancelPendingReorderStart()
            if isInteractiveReorderActive {
                collectionView.cancelInteractiveMovement()
                isInteractiveReorderActive = false
            }
            if let activeReorderingCell = activeReorderingCell as? TabOverviewCard {
                activeReorderingCell.setReorderLifted(false, animated: true)
            }
            if collectionView === self.browserUI.tabBar.collectionView {
                endTabBarDragSnapshot()
                clearTabBarReorderState()
            }
            self.activeReorderingCell = nil
        }
    }
    
}

// Search Suggestions
extension BrowserViewController: SearchViewControllerDelegate {
    var searchController: SearchController {
        if let controller = objc_getAssociatedObject(self, &UIAssociatedKeys.searchController) as? SearchController {
            return controller
        }
        
        let controller = SearchController(controller: self)
        objc_setAssociatedObject(self, &UIAssociatedKeys.searchController, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return controller
    }
    
    var searchViewController: SearchViewController {
        if let controller = objc_getAssociatedObject(self, &UIAssociatedKeys.searchViewController) as? SearchViewController {
            return controller
        }
        
        let controller = SearchViewController()
        controller.delegate = self
        controller.overlayContentHeightDidChange = { [weak self] contentHeight in
            self?.suggestionsContentHeight = contentHeight
            self?.updateDetachedSuggestionsHeight()
        }
        objc_setAssociatedObject(self, &UIAssociatedKeys.searchViewController, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return controller
    }
    
    var isSuggestionScrollDismissal: Bool {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.searchScrollDismissal) as? NSNumber)?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.searchScrollDismissal, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var preserveSuggestionsOnFocus: Bool {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.preserveSuggestions) as? NSNumber)?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.preserveSuggestions, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsTop: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsTop) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsTop, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsBottom: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsBottom) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsBottom, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsLeading: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsLeading) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsLeading, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsTrailing: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsTrailing) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsTrailing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsCenterX: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsCenterX) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsCenterX, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsWidth: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsWidth) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsWidth, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsHeight: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsHeight) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsHeight, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var suggestionsContentHeight: CGFloat {
        get {
            CGFloat((objc_getAssociatedObject(self, &UIAssociatedKeys.suggestionsContentHeight) as? NSNumber)?.doubleValue ?? 0)
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.suggestionsContentHeight, NSNumber(value: Double(newValue)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isSearchScrollMode: Bool {
        get {
            (objc_getAssociatedObject(self, &UIAssociatedKeys.searchScrollMode) as? NSNumber)?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &UIAssociatedKeys.searchScrollMode, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addressBarDidSubmit(_ searchTerm: String) {
        browse(to: searchTerm)
        view.endEditing(true)
    }
    
    func addressBarDidBeginEditing(_ addressBar: AddressBar) {
        refreshAddressBar()
        browserUI.addressBar.setForceComposingAppearanceWhenUnfocused(false)
        browserUI.addressBar.setPreservesAutocompleteWhenUnfocused(false)
        isSearchScrollMode = false
        updateSuggestionsLayoutIfNeeded()
        if preserveSuggestionsOnFocus {
            preserveSuggestionsOnFocus = false
            showSuggestionsIfNeeded()
        } else {
            searchController.clearSuggestions()
        }
        setSearchFocused(true, animated: true)
    }
    
    func addressBar(_ addressBar: AddressBar, didChangeText text: String, previousText: String, isDelete: Bool) {
        autocompleteDeleteText = isDelete && previousText.count > text.count ? text : nil
        guard !text.isEmpty else {
            hideSuggestionsIfNeeded {
                self.searchController.clearSuggestions()
            }
            return
        }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            hideSuggestionsIfNeeded()
            searchController.fetchSuggestions(for: text)
            return
        }
        
        showSuggestionsIfNeeded()
        searchController.fetchSuggestions(for: text)
    }
    
    func addressBarDidEndEditing(_ addressBar: AddressBar) {
        if isSuggestionScrollDismissal {
            isSuggestionScrollDismissal = false
            preserveSuggestionsOnFocus = true
            isSearchScrollMode = true
            browserUI.addressBar.setForceComposingAppearanceWhenUnfocused(true)
            browserUI.addressBar.setPreservesAutocompleteWhenUnfocused(true)
            updateSuggestionsLayoutIfNeeded()
            browserUI.applyChromeLayout(animated: false)
            return
        }
        
        browserUI.addressBar.setForceComposingAppearanceWhenUnfocused(false)
        browserUI.addressBar.setPreservesAutocompleteWhenUnfocused(false)
        refreshAddressBar()
        hideSuggestionsIfNeeded {
            self.searchController.clearSuggestions()
        }
        if !browserUI.addressBar.isEditingText {
            setSearchFocused(false, animated: true)
        }
    }
    
    func searchViewControllerDidStartScrolling(_ controller: SearchViewController) {
        guard browserUI.addressBar.isEditingText else {
            return
        }
        
        isSuggestionScrollDismissal = true
        browserUI.addressBar.setPreservesAutocompleteWhenUnfocused(browserUI.addressBar.isShowingAutocomplete)
        _ = browserUI.addressBar.resignFirstResponder()
    }
    
    func searchViewController(_ controller: SearchViewController, didSelectSuggestion suggestion: String, match: SearchAuxiliaryMatch?) {
        if isSearchScrollMode {
            restoreSearchChrome(clearSuggestions: true)
        }
        
        view.endEditing(true)
        if let match,
           match.kind == .tab,
           let tabID = match.tabID {
            switchToSearchTab(id: tabID)
            return
        }
        
        browse(to: suggestion)
    }
    
    func updateAddressBarAutocomplete(for query: String, primaryMatch: SearchAuxiliaryMatch?) {
        guard browserUI.addressBar.isEditingText else {
            browserUI.addressBar.clearAutocomplete()
            return
        }
        
        let currentText = browserUI.addressBar.getText() ?? ""
        guard !query.isEmpty,
              currentText == query,
              autocompleteDeleteText != query,
              let primaryMatch,
              let autocomplete = autocompletePresentation(for: primaryMatch, query: query) else {
            browserUI.addressBar.clearAutocomplete()
            return
        }
        
        browserUI.addressBar.setAutocomplete(
            displayText: autocomplete.displayText,
            committedText: autocomplete.committedText,
            submissionText: autocomplete.submissionText
        )
    }
    
    func restoreSearchChrome(clearSuggestions: Bool) {
        preserveSuggestionsOnFocus = false
        isSearchScrollMode = false
        browserUI.addressBar.setForceComposingAppearanceWhenUnfocused(false)
        browserUI.addressBar.setPreservesAutocompleteWhenUnfocused(false)
        hideSuggestionsIfNeeded {
            if clearSuggestions {
                self.searchController.clearSuggestions()
            }
        }
        if !browserUI.addressBar.isEditingText {
            setSearchFocused(false, animated: true)
        }
        refreshAddressBar()
    }
    
    private func showSuggestionsIfNeeded() {
        let overlayController = searchViewController
        let text = browserUI.addressBar.getText() ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              overlayController.parent == nil else {
            return
        }
        overlayController.setUsesTopAddressBarMode(usesTopPhoneAddressBar)
        overlayController.setUsesPadChromeMode(usesPadChrome)
        overlayController.setUsesDetachedOverlayAppearance(usesDetachedSuggestions)
        
        overlayController.view.translatesAutoresizingMaskIntoConstraints = false
        overlayController.view.alpha = 0
        addChild(overlayController)
        if usesDetachedSuggestions {
            view.addSubview(overlayController.view)
        } else {
            view.insertSubview(overlayController.view, aboveSubview: browserUI.geckoView)
        }
        overlayController.didMove(toParent: self)
        updateSuggestionsLayoutIfNeeded()
        UIView.animate(withDuration: 0.12) {
            overlayController.view.alpha = 1
        }
    }
    
    private func hideSuggestionsIfNeeded(afterHide: (() -> Void)? = nil) {
        let overlayController = searchViewController
        guard overlayController.parent != nil else {
            afterHide?()
            return
        }
        
        overlayController.view.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.12, animations: {
            overlayController.view.alpha = 0
        }) { _ in
            self.removeSuggestions()
            afterHide?()
        }
    }
    
    func hideSuggestionsNow() {
        let overlayController = searchViewController
        guard overlayController.parent != nil else {
            return
        }
        
        overlayController.view.layer.removeAllAnimations()
        removeSuggestions()
    }
    
    func updateSuggestionsLayoutIfNeeded() {
        let overlayController = searchViewController
        guard overlayController.parent != nil else {
            return
        }
        overlayController.setUsesTopAddressBarMode(usesTopPhoneAddressBar)
        overlayController.setUsesPadChromeMode(usesPadChrome)
        overlayController.setUsesDetachedOverlayAppearance(usesDetachedSuggestions)
        
        clearSuggestionLayoutConstraints()
        if usesDetachedSuggestions {
            view.bringSubviewToFront(overlayController.view)
            if #available(iOS 13.0, *) { overlayController.view.layer.cornerCurve = .continuous }
            overlayController.view.clipsToBounds = false
            overlayController.view.backgroundColor = .clear
            let shadowColor: UIColor = .reynardChromeShadow
            overlayController.view.layer.shadowColor = shadowColor.cgColor
            overlayController.view.layer.shadowOpacity = 0.16
            overlayController.view.layer.shadowOffset = CGSize(width: 0, height: 8)
            
            if #available(iOS 26.0, *) {
                overlayController.view.layer.cornerRadius = 36
                overlayController.view.layer.shadowRadius = 36
            } else {
                overlayController.view.layer.cornerRadius = 12
                overlayController.view.layer.shadowRadius = 12
            }
            
            view.layoutIfNeeded()
            let top = overlayController.view.topAnchor.constraint(equalTo: browserUI.addressBar.bottomAnchor, constant: 12)
            let dismissFrame = browserUI.keyboardDismissButton.button.isHidden
            ? browserUI.addressBar.frame
            : browserUI.keyboardDismissButton.button.convert(browserUI.keyboardDismissButton.button.bounds, to: view)
            let barFrame = browserUI.addressBar.frame.union(dismissFrame)
            let centerX = overlayController.view.centerXAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: barFrame.midX
            )
            let maxWidth = max(barFrame.width + 32, view.bounds.width * (3.0 / 5.0))
            let width = overlayController.view.widthAnchor.constraint(equalToConstant: maxWidth)
            let height = overlayController.view.heightAnchor.constraint(equalToConstant: detachedSuggestionsHeight())
            
            suggestionsTop = top
            suggestionsCenterX = centerX
            suggestionsWidth = width
            suggestionsHeight = height
            NSLayoutConstraint.activate([
                top,
                centerX,
                width,
                height,
            ])
        } else {
            overlayController.view.layer.cornerRadius = 0
            overlayController.view.clipsToBounds = false
            overlayController.view.backgroundColor = .clear
            overlayController.view.layer.shadowOpacity = 0
            overlayController.view.layer.shadowRadius = 0
            overlayController.view.layer.shadowOffset = .zero
            overlayController.view.layer.shadowPath = nil
            
            let top = overlayController.view.topAnchor.constraint(equalTo: suggestionsTopAnchor())
            let bottom = overlayController.view.bottomAnchor.constraint(equalTo: suggestionsBottomAnchor())
            let leading = overlayController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailing = overlayController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            
            suggestionsTop = top
            suggestionsBottom = bottom
            suggestionsLeading = leading
            suggestionsTrailing = trailing
            NSLayoutConstraint.activate([
                top,
                leading,
                trailing,
                bottom,
            ])
        }
        view.layoutIfNeeded()
        overlayController.view.layer.shadowPath = usesDetachedSuggestions ? UIBezierPath(roundedRect: overlayController.view.bounds, cornerRadius: 24).cgPath : nil
    }
    
    private func updateDetachedSuggestionsHeight() {
        guard usesDetachedSuggestions,
              searchViewController.parent != nil,
              let height = suggestionsHeight else {
            return
        }
        
        let newHeight = detachedSuggestionsHeight()
        guard abs(height.constant - newHeight) > 0.5 else {
            return
        }
        
        height.constant = newHeight
        view.layoutIfNeeded()
        searchViewController.view.layer.shadowPath = UIBezierPath(
            roundedRect: searchViewController.view.bounds,
            cornerRadius: 24
        ).cgPath
    }
    
    private func clearSuggestionLayoutConstraints() {
        suggestionsTop?.isActive = false
        suggestionsBottom?.isActive = false
        suggestionsLeading?.isActive = false
        suggestionsTrailing?.isActive = false
        suggestionsCenterX?.isActive = false
        suggestionsWidth?.isActive = false
        suggestionsHeight?.isActive = false
    }
    
    private func removeSuggestions() {
        let overlayController = searchViewController
        overlayController.willMove(toParent: nil)
        overlayController.view.removeFromSuperview()
        overlayController.removeFromParent()
        clearSuggestionLayoutConstraints()
        suggestionsTop = nil
        suggestionsBottom = nil
        suggestionsLeading = nil
        suggestionsTrailing = nil
        suggestionsCenterX = nil
        suggestionsWidth = nil
        suggestionsHeight = nil
        browserUI.addressBar.setForceComposingAppearanceWhenUnfocused(false)
        browserUI.addressBar.setPreservesAutocompleteWhenUnfocused(false)
        if isSearchScrollMode {
            isSearchScrollMode = false
            browserUI.applyChromeLayout(animated: false)
        }
    }
    
    private func switchToSearchTab(id: UUID) {
        let activeTabs = tabManager.selectedTabMode == .private ? tabManager.privateTabs : tabManager.regularTabs
        guard let index = activeTabs.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        selectTab(at: index, animated: true)
    }
    
    private func suggestionsTopAnchor() -> NSLayoutYAxisAnchor {
        usesTopPhoneAddressBar || usesCompactPadChrome ? browserUI.topBar.barView.bottomAnchor : view.topAnchor
    }
    
    private func suggestionsBottomAnchor() -> NSLayoutYAxisAnchor {
        if usesTopPhoneAddressBar || usesCompactPadChrome {
            return view.bottomAnchor
        }
        
        return isSearchScrollMode ? browserUI.bottomContainer.containerView.topAnchor : view.bottomAnchor
    }
    
    private func detachedSuggestionsHeight() -> CGFloat {
        let maximumHeight = browserUI.geckoView.bounds.height * (9.0 / 10.0)
        return min(suggestionsContentHeight, maximumHeight)
    }
    
    private func autocompletePresentation(
        for primaryMatch: SearchAuxiliaryMatch,
        query: String
    ) -> (displayText: NSAttributedString, committedText: String, submissionText: String)? {
        let title = primaryMatch.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let strippedURL = strippedURLString(primaryMatch.url.absoluteString, trimsTrailingSlash: true)
        let firstPartAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.reynardLabel]
        let completionAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.reynardLabel,
            .backgroundColor: UIColor.reynardSystemGray4
        ]
        let suffixAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue,
            .backgroundColor: UIColor.reynardSystemGray4
        ]
        
        if title.hasPrefix(query) {
            let attributed = NSMutableAttributedString(
                string: String(title.prefix(query.count)),
                attributes: firstPartAttributes
            )
            let completion = String(title.dropFirst(query.count))
            if !completion.isEmpty {
                attributed.append(NSAttributedString(string: completion, attributes: completionAttributes))
            }
            attributed.append(NSAttributedString(string: " — \(strippedURL)", attributes: suffixAttributes))
            return (attributed, strippedURL, primaryMatch.url.absoluteString)
        }
        
        let strippedQuery = strippedURLMatchString(query)
        let strippedURLMatchValue = strippedURLMatchString(primaryMatch.url.absoluteString)
        guard !strippedQuery.isEmpty else {
            return nil
        }
        
        let completedURL: String
        if strippedURLMatchValue.hasPrefix(strippedQuery) {
            completedURL = autocompleteURLString(for: query, url: primaryMatch.url) ?? strippedURL
        } else if let matchedDomain = domainCompletion(for: strippedQuery, url: primaryMatch.url) {
            completedURL = matchedDomain
        } else {
            return nil
        }
        
        let attributed = NSMutableAttributedString(
            string: String(query.prefix(query.count)),
            attributes: firstPartAttributes
        )
        let completion = String(completedURL.dropFirst(query.count))
        if !completion.isEmpty {
            attributed.append(NSAttributedString(string: completion, attributes: completionAttributes))
        }
        attributed.append(NSAttributedString(string: " — \(title)", attributes: suffixAttributes))
        return (attributed, completedURL, primaryMatch.url.absoluteString)
    }
    
    private func autocompleteURLString(for query: String, url: URL) -> String? {
        let loweredQuery = query.lowercased()
        for value in autocompleteURLVariants(for: url) {
            if value.lowercased().hasPrefix(loweredQuery) {
                return value
            }
        }
        
        return nil
    }
    
    private func autocompleteURLVariants(for url: URL) -> [String] {
        let fullURL = trimmedURLString(url.absoluteString)
        let schemeStrippedURL = strippedURLString(url.absoluteString, trimsWWW: false, trimsTrailingSlash: true)
        let normalizedURL = strippedURLString(url.absoluteString, trimsTrailingSlash: true)
        return [fullURL, schemeStrippedURL, normalizedURL]
    }
    
    private func strippedURLString(
        _ value: String,
        trimsWWW: Bool = true,
        trimsTrailingSlash: Bool = false
    ) -> String {
        let lowered = value.lowercased()
        var strippedValue: String
        if lowered.hasPrefix("https://") {
            strippedValue = String(value.dropFirst("https://".count))
        } else if lowered.hasPrefix("http://") {
            strippedValue = String(value.dropFirst("http://".count))
        } else if lowered.hasPrefix("ftp://") {
            strippedValue = String(value.dropFirst("ftp://".count))
        } else {
            strippedValue = value
        }
        
        if trimsWWW, strippedValue.lowercased().hasPrefix("www.") {
            strippedValue = String(strippedValue.dropFirst("www.".count))
        }
        
        return trimsTrailingSlash ? trimmedURLString(strippedValue) : strippedValue
    }
    
    private func trimmedURLString(_ value: String) -> String {
        if value.count > 1, value.hasSuffix("/") {
            return String(value.dropLast())
        }
        
        return value
    }
    
    private func strippedURLMatchString(_ value: String) -> String {
        let lowered = value.lowercased()
        if lowered.hasPrefix("https://") {
            return String(lowered.dropFirst("https://".count))
        }
        
        if lowered.hasPrefix("http://") {
            return String(lowered.dropFirst("http://".count))
        }
        
        if lowered.hasPrefix("ftp://") {
            return String(lowered.dropFirst("ftp://".count))
        }
        
        return lowered
    }
    
    private func domainCompletion(for query: String, url: URL) -> String? {
        let displayURL = strippedURLString(url.absoluteString, trimsTrailingSlash: true)
        var host = url.host?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if host.lowercased().hasPrefix("www.") {
            host = String(host.dropFirst("www.".count))
        }
        guard !host.isEmpty,
              displayURL.lowercased().hasPrefix(host.lowercased()) else {
            return nil
        }
        
        let hostWithDotPrefix = ".\(host)"
        guard let range = hostWithDotPrefix.range(of: ".\(query)", options: .caseInsensitive),
              let dotRange = hostWithDotPrefix[range.lowerBound...].firstIndex(of: ".") else {
            return nil
        }
        
        let matchedHost = String(hostWithDotPrefix[hostWithDotPrefix.index(after: dotRange)...])
        guard matchedHost.contains(".") else {
            return nil
        }
        
        let path = String(displayURL.dropFirst(host.count))
        return matchedHost + path
    }
}
