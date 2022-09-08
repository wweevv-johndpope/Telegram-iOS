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
import GalleryUI
import Postbox
import TelegramCore
import InstantPageUI


public class WEVRootNode: ASDisplayNode{
    let contactListNode: ContactListNode
    var controller:WEVRootViewController!
    private var showDataArray: [WEVVideoModel] = []
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


    func test(){
        
        

        let url = "https://gist.githubusercontent.com/wweevv-johndpope/62f58c50ef7b2a45516cfcade369c22e/raw/9b1767cad8dcaf74220296c48f2c97b52fb767bc/response.json"
        
        let request = AF.request(url)
        request.responseDecodable(of: WEVResponse.self) { (response) in
          guard let videos = response.value else {
              print("🔥 FAILED WTF???")
              print("🔥 error:",response)
              return }
            print(videos.data?.liveVideoPojoList as Any)
            if let arr = videos.data?.liveVideoPojoList{
                self.showDataArray = arr
            }
            self.collectionView?.reloadData()
        }
        

    }
    
    
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
        
        let presentation = sortOrder |> map { sortOrder -> ContactListPresentation in
            switch sortOrder {
                case .presence:
                    return .orderedByPresence(options: options)
                case .natural:
                    return .natural(options: options, includeChatList: false)
            }
        }

        
        self.contactListNode = ContactListNode.init(context: context, presentation: presentation)

        super.init()

        self.test()
        self.setViewBlock({
            return UITracingLayerView()
        })

        self.backgroundColor = presentationData.theme.contextMenu.backgroundColor

    }

   
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
   var collectionView: UICollectionView?

    private func updateThemeAndStrings() {
        self.collectionView?.reloadData()
//        self.tableView?.reloadData()
//        self.tableView?.backgroundColor = presentationData.theme.contextMenu.backgroundColor
//        self.tableView?.separatorColor = presentationData.theme.contextMenu.itemSeparatorColor
//
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
                
                // 50 = the navigation bar header height
               return self.getCollectionView(frame: CGRect(origin: CGPoint(x: 0, y: 50), size: CGSize(width: layout.size.width, height: layout.size.height)))
            
            }

            self.addSubnode(mServicesTableView!)
        }


    }
    
    func getCollectionView(frame:CGRect) -> UICollectionView{
        let layout = UICollectionViewFlowLayout()
        let width = (LJScreen.width - 1 * 2 - 1) / 2
        layout.itemSize = CGSize(width: width, height: 97 * width / 186)
        let view = UICollectionView.init(frame: frame, collectionViewLayout: layout)
        view.backgroundColor = .black
        view.delegate = self
        view.dataSource = self
        view.register(WEVDiscoverCollectionViewCell.self, forCellWithReuseIdentifier: "WEVDiscoverCollectionViewCell")
        view.contentInsetAdjustmentBehavior = .never
        self.collectionView = view
        return view
        
    }
    
}


//MARK: - UICollectionViewDelegateFlowLayout
extension WEVRootNode: UICollectionViewDelegateFlowLayout {
    
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 1, left: 1, bottom: 1, right: 1)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
////        if true {
////            return CGSize.init(width: LJScreen.width, height: 210 * LJScreen.width / 375)
////        }else {
//            return CGSize.zero
////        }
//
//    }
    
}

extension WEVRootNode: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        showDataArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverCollectionViewCell", for: indexPath) as! WEVDiscoverCollectionViewCell
        let model = showDataArray[indexPath.row]
        cell.model = model
//        cell.fixConstraints()
        return cell
    }
    
//    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let bannerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "WEVDiscoverBannerView", for: indexPath) as! WEVDiscoverBannerView
//        bannerView.dataArray = bannerDataArray
//        bannerView.didSelected = {[weak self] (video) in
//            guard let self = self else {return}
////            let vc = WEVVideoDetailViewController.init(video: video)
//            WEVVideoCheckManger.checkAndEnterVideo(video, from: self, completion: nil)
//        }
//
//        return bannerView
//    }
    private var navigationController: NavigationController? {
        if let navigationController = self.controller.navigationController as? NavigationController {
            return navigationController
        }
//        else if case let .inline(navigationController) = self.presentationInterfaceState.mode {
//            return navigationController
//        } else if case let .overlay(navigationController) = self.presentationInterfaceState.mode {
//            return navigationController
//        } else {
//            return nil
//        }
        return nil
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = showDataArray[indexPath.row]
        print("video:",video)
        
    
        
//
        let size = CGSize(width:1280,height:720)
        let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: "https://www.youtube.com/watch?v=idvMUlErPlA&ab_channel=PeppaPig-OfficialChannel", displayUrl: "youtube.com/watch?v=idvMUlErPlA", hash: 0, type: "video", websiteName: "YouTube", title: "title", text: "testa", embedUrl: "https://www.youtube.com/embed/idvMUlErPlA", embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))
        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: 0, id: 1), content: updatedContent)

//        let messageAttribute = MessageAttribute
        //JP HACK
        // attributes = ishdidden / type = Url / reactions
        let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: Namespaces.Message.Local, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: "", attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:])
        
        
        // Source is message?
                let source = GalleryControllerItemSource.standaloneMessage(message)
        let context = self.controller.accountContext()
        let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: true, landscape: false, timecode: 0, playbackRate: 1, synchronousLoad: false, replaceRootController: { _, ready in
            print("👹  we're in replaceRootController....")
                    self.controller?.navigationController?.popToRootViewController(animated: true)
        }, baseNavigationController: navigationController, actionInteraction: nil)
//        galleryVC.isChannel = true
        galleryVC.temporaryDoNotWaitForReady = false

//        let nv = NavigationController(/
//        self.controller.push(galleryVC)
        
        self.controller.present(galleryVC, in: .window(.root))
        

        
        
    }
}



//TODO - move this


/// 字体
struct LJFont {
    
    static func regular(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size)
    }

    static func medium(_ size: CGFloat) -> UIFont {
     UIFont.systemFont(ofSize: size)
    }
    
    static func bold(_ size: CGFloat) -> UIFont {
         UIFont.systemFont(ofSize: size)
    }

}

