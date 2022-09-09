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
import ContactsUI
import SnapKit
import HandyJSON
import Alamofire





public class WEVRootViewController: ViewController {
    private let context: AccountContext
    public func accountContext()->AccountContext{
        return context
    }

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
    
    
  
    public init(context: AccountContext) {
       
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        

        

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.tabBarItemContextActionType = .always
        

        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title =  "Feed"//self.presentationData.strings.Contacts_Title
        self.tabBarItem.title = "Feed"
        
        let icon: UIImage?
        if useSpecialTabBarIcons() {
            icon = UIImage(systemName:"heart.fill")?.withBaselineOffset(fromBottom: -6.0)
        } else {
            icon = UIImage(systemName:"heart.fill")?.withBaselineOffset(fromBottom: -6.0)
        }
        
        self.tabBarItem.image = icon
        self.tabBarItem.selectedImage = icon
//        if !self.presentationData.reduceMotion {
//            self.tabBarItem.animationName = "TabLove2"
//        }
        
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
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.authorizationDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
//        self.sortButton.update(theme: self.presentationData.theme, strings: self.presentationData.strings)
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        self.searchContentNode?.updateThemeAndPlaceholder(theme: self.presentationData.theme, placeholder: self.presentationData.strings.Common_Search)
        self.title = "Stream" //self.presentationData.strings.Contacts_Title
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

//


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
