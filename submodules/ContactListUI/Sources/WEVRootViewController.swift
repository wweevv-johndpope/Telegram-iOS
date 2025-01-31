import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess
import AccountContext
import AlertUI
import PresentationDataUtils
import TelegramPermissions
import TelegramNotices
import ContactsPeerItem
import SearchUI
import TelegramPermissionsUI
import AppBundle
import StickerResources
import ContextUI
import QrCodeUI


private final class HeaderContextReferenceContentSource: ContextReferenceContentSource {
    private let controller: ViewController
    private let sourceNode: ContextReferenceContentNode

    init(controller: ViewController, sourceNode: ContextReferenceContentNode) {
        self.controller = controller
        self.sourceNode = sourceNode
    }

    func transitionInfo() -> ContextControllerReferenceViewInfo? {
        return ContextControllerReferenceViewInfo(referenceView: self.sourceNode.view, contentAreaInScreenSpace: UIScreen.main.bounds)
    }
}

private final class SortHeaderButton: HighlightableButtonNode {
    let referenceNode: ContextReferenceContentNode
    let containerNode: ContextControllerSourceNode
    private let textNode: ImmediateTextNode
    
    var contextAction: ((ASDisplayNode, ContextGesture?) -> Void)?

    init(presentationData: PresentationData) {
        self.referenceNode = ContextReferenceContentNode()
        self.containerNode = ContextControllerSourceNode()
        self.containerNode.animateScale = false
        self.textNode = ImmediateTextNode()
        self.textNode.displaysAsynchronously = false

        super.init()

        self.containerNode.addSubnode(self.referenceNode)
        self.referenceNode.addSubnode(self.textNode)
        self.addSubnode(self.containerNode)

        self.containerNode.shouldBegin = { [weak self] location in
            guard let strongSelf = self, let _ = strongSelf.contextAction else {
                return false
            }
            return true
        }
        self.containerNode.activated = { [weak self] gesture, _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.contextAction?(strongSelf.containerNode, gesture)
        }

        self.update(theme: presentationData.theme, strings: presentationData.strings)
    }

    override func didLoad() {
        super.didLoad()
        self.view.isOpaque = false
    }

    func update(theme: PresentationTheme, strings: PresentationStrings) {
        self.textNode.attributedText = NSAttributedString(string: strings.Contacts_Sort, font: Font.regular(17.0), textColor: theme.rootController.navigationBar.accentTextColor)
        let size = self.textNode.updateLayout(CGSize(width: 100.0, height: 44.0))
        self.textNode.frame = CGRect(origin: CGPoint(x: 0.0, y: floorToScreenPixels((44.0 - size.height) / 2.0)), size: size)
        
        self.containerNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: size.width, height: 44.0))
        self.referenceNode.frame = self.containerNode.bounds
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let size = self.textNode.updateLayout(CGSize(width: 100.0, height: 44.0))
        
        return CGSize(width: size.width, height: 44.0)
    }

    func onLayout() {
    }
}

private func fixListNodeScrolling(_ listNode: ListView, searchNode: NavigationBarSearchContentNode) -> Bool {
    if listNode.scroller.isDragging {
        return false
    }
    if searchNode.expansionProgress > 0.0 && searchNode.expansionProgress < 1.0 {
        let offset: CGFloat
        if searchNode.expansionProgress < 0.6 {
            offset = navigationBarSearchContentHeight
        } else {
            offset = 0.0
        }
        let _ = listNode.scrollToOffsetFromTop(offset)
        return true
    } else if searchNode.expansionProgress == 1.0 {
        var sortItemNode: ListViewItemNode?
        var nextItemNode: ListViewItemNode?
        
        listNode.forEachItemNode({ itemNode in
            if sortItemNode == nil, let itemNode = itemNode as? ContactListActionItemNode {
                sortItemNode = itemNode
            } else if sortItemNode != nil && nextItemNode == nil {
                nextItemNode = itemNode as? ListViewItemNode
            }
        })
        
        if false, let sortItemNode = sortItemNode {
            let itemFrame = sortItemNode.apparentFrame
            if itemFrame.contains(CGPoint(x: 0.0, y: listNode.insets.top)) {
                var scrollToItem: ListViewScrollToItem?
                if itemFrame.minY + itemFrame.height * 0.6 < listNode.insets.top {
                    scrollToItem = ListViewScrollToItem(index: 0, position: .top(-76.0), animated: true, curve: .Default(duration: 0.3), directionHint: .Up)
                } else {
                    scrollToItem = ListViewScrollToItem(index: 0, position: .top(0), animated: true, curve: .Default(duration: 0.3), directionHint: .Up)
                }
                listNode.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: ListViewDeleteAndInsertOptions(), scrollToItem: scrollToItem, updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
                return true
            }
        }
    }
    return false
}

public class WEVRootViewController: ViewController {
    private let context: AccountContext
    
    private var contactsNode: WEVRootNode {
        return self.displayNode as! WEVRootNode
    }
    private var validLayout: ContainerViewLayout?
    
    private let index: PresentationPersonNameOrder = .lastFirst
    
    private var _ready = Promise<Bool>()
    override public var ready: Promise<Bool> {
        return self._ready
    }
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var authorizationDisposable: Disposable?
    private let sortOrderPromise = Promise<ContactsSortOrder>()
    private let isInVoiceOver = ValuePromise<Bool>(false)
    
    private var searchContentNode: NavigationBarSearchContentNode?
    
    public var switchToChatsController: (() -> Void)?
    
    public override func updateNavigationCustomData(_ data: Any?, progress: CGFloat, transition: ContainedViewLayoutTransition) {
        if self.isNodeLoaded {
            self.contactsNode.contactListNode.updateSelectedChatLocation(data as? ChatLocation, progress: progress, transition: transition)
        }
    }
    
    private let sortButton: SortHeaderButton
    
    public init(context: AccountContext) {
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        self.sortButton = SortHeaderButton(presentationData: self.presentationData)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.tabBarItemContextActionType = .always
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title =  "Stream"//self.presentationData.strings.Contacts_Title
        self.tabBarItem.title = self.presentationData.strings.Contacts_Title
        
        let icon: UIImage?
        if useSpecialTabBarIcons() {
            icon = UIImage(bundleImageName: "Chat List/Tabs/Holiday/IconContacts")
        } else {
            icon = UIImage(bundleImageName: "Chat List/Tabs/IconContacts")
        }
        
        self.tabBarItem.image = icon
        self.tabBarItem.selectedImage = icon
        if !self.presentationData.reduceMotion {
            self.tabBarItem.animationName = "TabContacts"
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customDisplayNode: self.sortButton)
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationAddIcon(self.presentationData.theme), style: .plain, target: self, action: #selector(self.addPressed))
        self.navigationItem.rightBarButtonItem?.accessibilityLabel = self.presentationData.strings.Contacts_VoiceOver_AddContact
        
        self.scrollToTop = { [weak self] in
            if let strongSelf = self {
                if let searchContentNode = strongSelf.searchContentNode {
                    searchContentNode.updateExpansionProgress(1.0, animated: true)
                }
                strongSelf.contactsNode.scrollToTop()
            }
        }
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
        
        if #available(iOSApplicationExtension 10.0, iOS 10.0, *) {
            self.authorizationDisposable = (combineLatest(DeviceAccess.authorizationStatus(subject: .contacts), combineLatest(context.sharedContext.accountManager.noticeEntry(key: ApplicationSpecificNotice.permissionWarningKey(permission: .contacts)!), context.account.postbox.preferencesView(keys: [PreferencesKeys.contactsSettings]), context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.contactSynchronizationSettings]))
            |> map { noticeView, preferences, sharedData -> (Bool, ContactsSortOrder) in
                let settings: ContactsSettings = preferences.values[PreferencesKeys.contactsSettings]?.get(ContactsSettings.self) ?? ContactsSettings.defaultSettings
                let synchronizeDeviceContacts: Bool = settings.synchronizeContacts
                
                let contactsSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.contactSynchronizationSettings]?.get(ContactSynchronizationSettings.self)
                
                let sortOrder: ContactsSortOrder = contactsSettings?.sortOrder ?? .presence
                if !synchronizeDeviceContacts {
                    return (true, sortOrder)
                }
                let timestamp = noticeView.value.flatMap({ ApplicationSpecificNotice.getTimestampValue($0) })
                if let timestamp = timestamp, timestamp > 0 {
                    return (true, sortOrder)
                } else {
                    return (false, sortOrder)
                }
            })
            |> deliverOnMainQueue).start(next: { [weak self] status, suppressedAndSortOrder in
                if let strongSelf = self {
                    let (suppressed, sortOrder) = suppressedAndSortOrder
                    strongSelf.tabBarItem.badgeValue = status != .allowed && !suppressed ? "!" : nil
                    strongSelf.sortOrderPromise.set(.single(sortOrder))
                }
            })
        } else {
            self.sortOrderPromise.set(context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.contactSynchronizationSettings])
            |> map { sharedData -> ContactsSortOrder in
                let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.contactSynchronizationSettings]?.get(ContactSynchronizationSettings.self)
                return settings?.sortOrder ?? .presence
            })
        }
        
//        self.searchContentNode = NavigationBarSearchContentNode(theme: self.presentationData.theme, placeholder: self.presentationData.strings.Common_Search, activate: { [weak self] in
//            self?.activateSearch()
//        })
//        self.navigationBar?.setContentNode(self.searchContentNode, animated: false)
        
//        self.sortButton.addTarget(self, action: #selector(self.sortPressed), forControlEvents: .touchUpInside)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.authorizationDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        self.sortButton.update(theme: self.presentationData.theme, strings: self.presentationData.strings)
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        self.searchContentNode?.updateThemeAndPlaceholder(theme: self.presentationData.theme, placeholder: self.presentationData.strings.Common_Search)
        self.title = self.presentationData.strings.Contacts_Title
        self.tabBarItem.title = self.presentationData.strings.Contacts_Title
        if !self.presentationData.reduceMotion {
            self.tabBarItem.animationName = "TabContacts"
        } else {
            self.tabBarItem.animationName = nil
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        if self.navigationItem.rightBarButtonItem != nil {
//            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationAddIcon(self.presentationData.theme), style: .plain, target: self, action: #selector(self.addPressed))
            self.navigationItem.rightBarButtonItem?.accessibilityLabel = self.presentationData.strings.Contacts_VoiceOver_AddContact
        }
    }
    
    override public func loadDisplayNode() {
        self.displayNode = WEVRootNode(context: self.context, sortOrder: sortOrderPromise.get() |> distinctUntilChanged, present: { [weak self] c, a in
            self?.present(c, in: .window(.root), with: a)
        }, controller: self)
        
        self._ready.set(self.contactsNode.contactListNode.ready)

        self.contactsNode.navigationBar = self.navigationBar

        self.contactsNode.contactListNode.contentOffsetChanged = { [weak self] offset in
            if let strongSelf = self, let searchContentNode = strongSelf.searchContentNode {
                var progress: CGFloat = 0.0
                switch offset {
                    case let .known(offset):
                        progress = max(0.0, (searchContentNode.nominalHeight - max(0.0, offset - 50.0))) / searchContentNode.nominalHeight
                    case .none:
                        progress = 1.0
                    default:
                        break
                }
                searchContentNode.updateExpansionProgress(progress)
            }
        }

        self.contactsNode.contactListNode.contentScrollingEnded = { [weak self] listView in
            if let strongSelf = self, let searchContentNode = strongSelf.searchContentNode {
                return fixListNodeScrolling(listView, searchNode: searchContentNode)
            } else {
                return false
            }
        }
//        self.contactsNode.frame = CGRect(x: 0, y: 0, width: 500, height: 600)
        self.displayNodeDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.contactsNode.contactListNode.enableUpdates = true
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.contactsNode.contactListNode.enableUpdates = false
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.isInVoiceOver.set(layout.inVoiceOver)
        
        self.validLayout = layout
        
        self.contactsNode.containerLayoutUpdated(layout, navigationBarHeight: self.cleanNavigationHeight, actualNavigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
    
    @objc private func sortPressed() {
        self.sortButton.contextAction?(self.sortButton.containerNode, nil)
    }
    
    private func activateSearch() {
//        if self.displayNavigationBar {
//            if let searchContentNode = self.searchContentNode {
//                self.contactsNode.activateSearch(placeholderNode: searchContentNode.placeholderNode)
//            }
//            self.setDisplayNavigationBar(false, transition: .animated(duration: 0.5, curve: .spring))
//        }
    }
    
    private func deactivateSearch(animated: Bool) {
//        if !self.displayNavigationBar {
//            self.setDisplayNavigationBar(true, transition: animated ? .animated(duration: 0.5, curve: .spring) : .immediate)
//            if let searchContentNode = self.searchContentNode {
//                self.contactsNode.deactivateSearch(placeholderNode: searchContentNode.placeholderNode, animated: animated)
//            }
//        }
    }
    
    private func presentSortMenu(sourceNode: ASDisplayNode, gesture: ContextGesture?) {
        let updateSortOrder: (ContactsSortOrder) -> Void = { [weak self] sortOrder in
            if let strongSelf = self {
                strongSelf.sortOrderPromise.set(.single(sortOrder))
                let _ = updateContactSettingsInteractively(accountManager: strongSelf.context.sharedContext.accountManager, { current -> ContactSynchronizationSettings in
                    var updated = current
                    updated.sortOrder = sortOrder
                    return updated
                }).start()
            }
        }
        
        let presentationData = self.presentationData
        let items: Signal<[ContextMenuItem], NoError> = self.context.sharedContext.accountManager.transaction { transaction in
            return transaction.getSharedData(ApplicationSpecificSharedDataKeys.contactSynchronizationSettings)
        }
        |> map { entry -> [ContextMenuItem] in
            let currentSettings: ContactSynchronizationSettings
            if let entry = entry?.get(ContactSynchronizationSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            
            var items: [ContextMenuItem] = []
            items.append(.action(ContextMenuActionItem(text: presentationData.strings.Contacts_Sort_ByLastSeen, icon: { theme in return currentSettings.sortOrder == .presence ? generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Check"), color: theme.contextMenu.primaryColor) : nil }, action: { _, f in
                f(.default)
                updateSortOrder(.presence)
            })))
            items.append(.action(ContextMenuActionItem(text: presentationData.strings.Contacts_Sort_ByName, icon: { theme in return currentSettings.sortOrder == .natural ? generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Check"), color: theme.contextMenu.primaryColor) : nil }, action: { _, f in
                f(.default)
                updateSortOrder(.natural)
            })))
            return items
        }
        let contextController = ContextController(account: self.context.account, presentationData: self.presentationData, source: .reference(HeaderContextReferenceContentSource(controller: self, sourceNode: self.sortButton.referenceNode)), items: items |> map { ContextController.Items(content: .list($0)) }, gesture: gesture)
        self.presentInGlobalOverlay(contextController)
    }
    
//    @objc func addPressed() {
//        let _ = (DeviceAccess.authorizationStatus(subject: .contacts)
//        |> take(1)
//        |> deliverOnMainQueue).start(next: { [weak self] status in
//            guard let strongSelf = self else {
//                return
//            }
//
//            switch status {
//                case .allowed:
//                    let contactData = DeviceContactExtendedData(basicData: DeviceContactBasicData(firstName: "", lastName: "", phoneNumbers: [DeviceContactPhoneNumberData(label: "_$!<Mobile>!$_", value: "+")]), middleName: "", prefix: "", suffix: "", organization: "", jobTitle: "", department: "", emailAddresses: [], urls: [], addresses: [], birthdayDate: nil, socialProfiles: [], instantMessagingProfiles: [], note: "")
//                    if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController {
//                        navigationController.pushViewController(strongSelf.context.sharedContext.makeDeviceContactInfoController(context: strongSelf.context, subject: .create(peer: nil, contactData: contactData, isSharing: false, shareViaException: false, completion: { peer, stableId, contactData in
//                            guard let strongSelf = self else {
//                                return
//                            }
//                            if let peer = peer {
//                                DispatchQueue.main.async {
//                                    if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
//                                        if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController {
//                                            navigationController.pushViewController(infoController)
//                                        }
//                                    }
//                                }
//                            } else {
//                                if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController {
//                                    navigationController.pushViewController(strongSelf.context.sharedContext.makeDeviceContactInfoController(context: strongSelf.context, subject: .vcard(nil, stableId, contactData), completed: nil, cancelled: nil))
//                                }
//                            }
//                        }), completed: nil, cancelled: nil))
//                    }
//                case .notDetermined:
//                    DeviceAccess.authorizeAccess(to: .contacts)
//                default:
//                    let presentationData = strongSelf.presentationData
//                    if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController, let topController = navigationController.topViewController as? ViewController {
//                        topController.present(textAlertController(context: strongSelf.context, title: presentationData.strings.AccessDenied_Title, text: presentationData.strings.Contacts_AccessDeniedError, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_NotNow, action: {}), TextAlertAction(type: .genericAction, title: presentationData.strings.AccessDenied_Settings, action: {
//                            self?.context.sharedContext.applicationBindings.openSettings()
//                        })]), in: .window(.root))
//                    }
//            }
//        })
//    }
//
    override public func tabBarItemContextAction(sourceNode: ContextExtractedContentContainingNode, gesture: ContextGesture) {
        var items: [ContextMenuItem] = []
//        items.append(.action(ContextMenuActionItem(text: self.presentationData.strings.Contacts_AddContact, icon: { theme in
//            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/AddUser"), color: theme.contextMenu.primaryColor)
//        }, action: { [weak self] c, f in
//            c.dismiss(completion: { [weak self] in
//                guard let strongSelf = self else {
//                    return
//                }
//                strongSelf.addPressed()
//            })
//        })))
        
        
        
        items.append(.action(ContextMenuActionItem(text: self.presentationData.strings.Contacts_AddPeopleNearby, icon: { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Contact List/Context Menu/PeopleNearby"), color: theme.contextMenu.primaryColor)
        }, action: { [weak self] c, f in
            c.dismiss(completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.contactsNode.openPeopleNearby?()
            })
        })))
        
        let controller = ContextController(account: self.context.account, presentationData: self.presentationData, source: .extracted(ContactsTabBarContextExtractedContentSource(controller: self, sourceNode: sourceNode)), items: .single(ContextController.Items(content: .list(items))), recognizer: nil, gesture: gesture)
        self.context.sharedContext.mainWindow?.presentInGlobalOverlay(controller)
    }
}

private final class ContactsTabBarContextExtractedContentSource: ContextExtractedContentSource {
    let keepInPlace: Bool = true
    let ignoreContentTouches: Bool = true
    let blurBackground: Bool = true
    let centerActionsHorizontally: Bool = true
    
    private let controller: ViewController
    private let sourceNode: ContextExtractedContentContainingNode
    
    init(controller: ViewController, sourceNode: ContextExtractedContentContainingNode) {
        self.controller = controller
        self.sourceNode = sourceNode
    }
    
    func takeView() -> ContextControllerTakeViewInfo? {
        return ContextControllerTakeViewInfo(containingItem: .node(self.sourceNode), contentAreaInScreenSpace: UIScreen.main.bounds)
    }
    
    func putBack() -> ContextControllerPutBackViewInfo? {
        return ContextControllerPutBackViewInfo(contentAreaInScreenSpace: UIScreen.main.bounds)
    }
}

class WEVRootNode: ASDisplayNode,UITableViewDelegate,UITableViewDataSource {
    let contactListNode: ContactListNode
    var controller:WEVRootViewController!
    private let context: AccountContext
    private(set) var searchDisplayController: SearchDisplayController?
    private var offersTableViewNode:ASDisplayNode?
    private var containerLayout: (ContainerViewLayout, CGFloat)?
//    var interactor:WCInteractor?
    var navigationBar: NavigationBar?
    var listNode:ListView!
    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((ContactListPeer) -> Void)?
    var requestAddContact: ((String) -> Void)?
    var openPeopleNearby: (() -> Void)?
    var openInvite: (() -> Void)?


    var tableView:UITableView?
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var mServicesTableView:ASDisplayNode?


    init(context: AccountContext, sortOrder: Signal<ContactsSortOrder, NoError>, present: @escaping (ViewController, Any?) -> Void, controller: WEVRootViewController) {
        self.context = context
       
        self.controller = controller
        //BlockchainTest().decode()
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

       
        let options = [ContactListAdditionalOption(title: presentationData.strings.Contacts_AddPeopleNearby, icon: .generic(UIImage(bundleImageName: "Contact List/PeopleNearbyIcon")!), action: {
         //   addNearbyImpl?()
        }), ContactListAdditionalOption(title: presentationData.strings.Contacts_InviteFriends, icon: .generic(UIImage(bundleImageName: "Contact List/AddMemberIcon")!), action: {
//            inviteImpl?()
        })]
        
        let presentation = sortOrder
        |> map { sortOrder -> ContactListPresentation in
            switch sortOrder {
                case .presence:
                    return .orderedByPresence(options: options)
                case .natural:
                    return .natural(options: options, includeChatList: false)
            }
        }

        
        self.contactListNode = ContactListNode.init(context: context, presentation: presentation)

        super.init()

        self.setViewBlock({
            return UITracingLayerView()
        })

        self.backgroundColor = presentationData.theme.contextMenu.backgroundColor

    }

   
    deinit {
        self.presentationDataDisposable?.dispose()
    }

    private func updateThemeAndStrings() {
        self.tableView?.reloadData()
        self.tableView?.backgroundColor = presentationData.theme.contextMenu.backgroundColor
        self.tableView?.separatorColor = presentationData.theme.contextMenu.itemSeparatorColor
        
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
        self.searchDisplayController?.updatePresentationData(self.presentationData)
        
    }

    func scrollToTop() {
        if let contentNode = self.searchDisplayController?.contentNode as? ContactsSearchContainerNode {
            contentNode.scrollToTop()
        } else {
            self.contactListNode.scrollToTop()
        }
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, actualNavigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        print("containerLayoutUpdated \(layout)")
        self.containerLayout = (layout, navigationBarHeight)

        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight

        var headerInsets = layout.insets(options: [.input])
        headerInsets.top += actualNavigationBarHeight

        if let searchDisplayController = self.searchDisplayController {
            searchDisplayController.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
        }

        self.contactListNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, deviceMetrics: layout.deviceMetrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, additionalInsets: layout.additionalInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging, inVoiceOver: layout.inVoiceOver), headerInsets: headerInsets, transition: transition)

        if(mServicesTableView?.supernode == nil) { // load only once
            mServicesTableView = ASDisplayNode { () -> UIView in
                let services = self.getCollectionView(frame: CGRect(origin: CGPoint(x: 0, y: 100), size: CGSize(width: layout.size.width, height: layout.size.height)))
                return services
            }

            self.addSubnode(mServicesTableView!)
        }


    }

    private func getCollectionView(frame:CGRect) -> UITableView {
        self.tableView = UITableView(frame: frame)
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.backgroundColor = presentationData.theme.contextMenu.backgroundColor
        self.tableView?.separatorColor = presentationData.theme.contextMenu.itemSeparatorColor
        
        return  self.tableView!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "servicesCell")
        cell?.selectionStyle = .none
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "servicesCell")
        }
        
        if indexPath.row == 0 {
//            cell?.imageView?.image = UIImage(named: "terms")
            cell?.textLabel?.text = "My Offers"
        } else {
//            cell?.imageView?.image = UIImage(named: "expiration")
            cell?.textLabel?.text = "My Schedules"
        }
        cell?.textLabel?.textColor = presentationData.theme.contextMenu.primaryColor
//        cell?.backgroundView?.backgroundColor =presentationData.theme.contextMenu.backgroundColor
        cell?.backgroundColor = presentationData.theme.contextMenu.backgroundColor
        cell?.selectionStyle = .none
              
        return cell!
    }
//
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelect row \(indexPath.row)")
//        let v = Bundle.main.loadNibNamed("DetailsHeaderCell", owner: self, options: nil)
//        print("DetailsHeaderCell xib \(v)")
        
        if indexPath.row == 1 {


            let schedules = UIViewController()
            schedules.view.backgroundColor = .red
            let navigation = UINavigationController(rootViewController: schedules)
//            navigation.modalPresentationStyle = .fullScreen
            controller.present(navigation, animated: true)
            
        } else if indexPath.row == 0 {

            let offers = UIViewController()
            offers.title = "offers"
            offers.view.backgroundColor = .blue
            let navigation = UINavigationController(rootViewController: offers)
//            navigation.modalPresentationStyle = .fullScreen
            controller.present(navigation, animated: true)

        }
    }
}

//
