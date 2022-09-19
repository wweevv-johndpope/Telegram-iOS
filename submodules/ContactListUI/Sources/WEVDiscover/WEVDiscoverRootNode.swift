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
//import SnapKit
import HandyJSON
import Alamofire
import GalleryUI
import Postbox
import TelegramCore
import InstantPageUI
import MBProgressHUD
import HandyJSON
import CoreLocation

public class WEVDiscoverRootNode: ASDisplayNode {
    
    let contactListNode: ContactListNode
    var controller:WEVRootViewController!
    
    /// 根据状态返回该显示的视频
    private var showDataArray: [WEVVideoModel] {
        get {
            switch searchStatus {
            case .searchCompleted:
                return searchDataArray
            case .normal:
                return dataArray
            case .searching:
                return []
            }
        }
        set {
            switch searchStatus {
            case .searchCompleted:
                searchDataArray = newValue
            case .normal:
                dataArray = newValue
            case .searching:
                break
            }
        }
    }
    //var ytVideos: [YoutubeVideo] = []
    
    
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
    
    
    /// bannerView数据列表
    private var bannerDataArray: [WEVVideoModel] = []
    //filter
    private var selectedChannelArray: [WEVChannel] = WEVChannel.allCases
    /// 关键字搜索情况下的请求才需要传，由上个请求得到，第一页传nil
    private var searchOffset: Int?
    //seatch VC
    private var searchStatus: SearchStatus = .normal
    private var searchWord: String? = nil
    
    private var searchDataArray: [WEVVideoModel] = []
    /// 下一页数据
    ///  /// 数据列表
    private var dataArray: [WEVVideoModel] = []
    private var nextPageToken: String?

    /// 当前位置
    private var currentLocation: CLLocation?
    
    private lazy var emptyView: WEVEmptyHintView = {
        let view = WEVEmptyHintView()
        return view
    }()
    
    /// 是否需要刷新banner
    private var isShouldLoadBannerData: Bool {
        get {
            // 非搜索非筛选
            (selectedChannelArray.isEmpty || selectedChannelArray.count == WEVChannel.allCases.count)
            && searchStatus == .normal
        }
    }
    
    /// 是否应该显示banner
    private var isShowBannerView: Bool {
        get {
            isShouldLoadBannerData && !bannerDataArray.isEmpty
        }
    }
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var mServicesTableView:ASDisplayNode?
    
    private lazy var searchView: WEVDiscoverSearchView = {
        let view = WEVDiscoverSearchView()
        view.recordArray = WEVSearchRecordManager.recordArray
        view.didSelected = {[weak self] word in
            guard let self = self else {return}
            self.search(word: word)
            self.refreshSearchStatusView()
            self.searchBar.text = word
        }
        view.deleteRecord = {[weak self] record in
            guard let self = self else {return}
            WEVSearchRecordManager.remove(record: record)
            self.searchView.recordArray.removeAll(where: {$0 == record})
        }
        return view
    }()
    
    
    
    private lazy var searchBar: WEVDiscoverSearchBar = {
        let view = WEVDiscoverSearchBar()
        view.filterAction = {[weak self] in
            guard let self = self else {return}
            let vc = WEVDiscoverFilterViewController(allChannel: WEVChannel.allCases, selectedArray: self.selectedChannelArray)
            vc.selectedArray = self.selectedChannelArray
            vc.didSelected = {[weak self] channelArray in
                guard let self = self else {return}
                self.selectedChannelArray = channelArray
                self.scrollViewLoadData(isHeadRefesh: true)
                DispatchQueue.main.async {
                    self.collectionView!.reloadData()
                }
            }
            self.controller.present(vc, animated: true, completion: nil)
        }
        
        view.cancelAction = {[weak self] in
            guard let self = self else {return}
            self.searchStatus = .normal
            self.searchWord = nil
            self.searchBar.text = ""
            self.searchDataArray.removeAll()
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
            self.refreshSearchStatusView()
            self.refreshEmptyView()
        }
        
        view.didBeginEditing = {[weak self] in
            guard let self = self else {return}
            self.searchView.isShowRecordList = self.searchBar.text.isEmpty
            self.searchStatus = .searching
            self.refreshSearchStatusView()
        }
        
        view.searchAction = {[weak self] word in
            guard let self = self else {return}
            self.search(word: word)
            self.refreshSearchStatusView()
        }
        
        view.textDidChange = {[weak self] word in
            guard let self = self else {return}
            self.searchLiveName(word: word)
            self.searchView.isShowRecordList = word.isEmpty
        }
        
        return view
    }()
    
    
    private func search(word: String) {
        searchBar.textField.resignFirstResponder()
        searchWord = word
        searchStatus = .searchCompleted
        scrollViewLoadData(isHeadRefesh: true)
        WEVSearchRecordManager.add(record: word)
        searchView.recordArray = WEVSearchRecordManager.recordArray
    }
    
    
    /// 刷新空白提示页面
    func refreshEmptyView() {
        if showDataArray.isEmpty && !isShowBannerView {
            switch searchStatus {
            case .normal:
                let model = WEVEmptyHintView.Model.init(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                emptyView.model = model
            case .searchCompleted:
                let model = WEVEmptyHintView.Model.init(title: "Oops!... no results found", image: "empty_discover_search", desc: "There are no results matching your search. Check your spelling or try another keyword.")
                emptyView.model = model
            default:
                break
            }
            emptyView.removeFromSuperview()
            collectionView!.addSubview(emptyView)
            emptyView.snp.makeConstraints { (make) in
                make.top.left.equalToSuperview()
                make.size.equalToSuperview()
            }
        }else {
            emptyView.removeFromSuperview()
        }
    }
    
    /// 刷新搜索状态相关视图
    private func refreshSearchStatusView() {
        
        /// 是否显示搜索界面
        func updateListView(_ isShowSearchView: Bool) {
            collectionView!.isHidden = isShowSearchView
            searchView.isHidden = !isShowSearchView
        }
        
        switch searchStatus {
        case .searching:
            updateListView(true)
            searchBar.style = .searching
        case .normal:
            updateListView(false)
            searchBar.style = .normal
        case .searchCompleted:
            updateListView(false)
            searchBar.style = .searchCompleted
        }
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
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
        
        self.scrollViewLoadData(isHeadRefesh: true)

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
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
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
           // 1. convert to ASDisplayNode
            mServicesTableView = ASDisplayNode { () -> UIView in
                return self.getCollectionView(frame: .zero)
            }
            // 2. add node to view hierachy > then snapkit
            self.addSubnode(mServicesTableView!)
            collectionView?.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(navigationBarHeight)
                make.bottom.equalToSuperview().offset(-LJScreen.tabBarHeight)
            }
            
            //Filter view to select channel
            let searchBarNode =  ASDisplayNode { () -> UIView in
                return self.searchBar
            }
            self.addSubnode(searchBarNode)
            searchBar.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(LJScreen.statusBarHeight)
                make.height.equalTo(44)
            }
            
            //seachbar result view
            let searchNode =  ASDisplayNode { () -> UIView in
                return self.searchView
            }
            self.addSubnode(searchNode)
            searchView.snp.makeConstraints { (make) in
                make.edges.equalTo(collectionView!)
            }
        }
        
        refreshSearchStatusView()
        
    }
    
    func getCollectionView(frame:CGRect) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        let width = (LJScreen.width - 1 * 2 - 1) / 2
        layout.itemSize = CGSize(width: width, height: 97 * width / 186)
        let view = UICollectionView.init(frame: frame, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
        view.register(WEVDiscoverCollectionViewCell.self, forCellWithReuseIdentifier: "WEVDiscoverCollectionViewCell")
        view.register(WEVDiscoverBannerView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WEVDiscoverBannerView")
        view.contentInsetAdjustmentBehavior = .never
        view.lj.addMJReshreHeader(delegate: self)
        view.lj.addMJReshreFooter(delegate: self)
        self.collectionView = view
        return view
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension WEVDiscoverRootNode: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 1, left: 1, bottom: 1, right: 1)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    public  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if isShowBannerView {
            return CGSize.init(width: LJScreen.width, height: 210 * LJScreen.width / 375)
        }else {
            return CGSize.zero
        }
    }
}

extension WEVDiscoverRootNode: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showDataArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverCollectionViewCell", for: indexPath) as! WEVDiscoverCollectionViewCell
        cell.model = showDataArray[indexPath.row]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let bannerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "WEVDiscoverBannerView", for: indexPath) as? WEVDiscoverBannerView else {
            return UICollectionReusableView()
        }
        bannerView.dataArray = bannerDataArray
        bannerView.didSelected = {[weak self] (video) in
            guard let self = self else {return}
            self.playVideo(video: video)
            print("self:",self)
        }
        
        return bannerView
    }
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
        self.playVideo(video: video)
    }
    
    func playVideo(video: WEVVideoModel) {
        if let url = video.videlLiveUrl {
            let size = CGSize(width:1280,height:720)
            
            let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: "video", websiteName: "YouTube", title:video.videoTitle, text: video.videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))
            let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: 0, id: 1), content: updatedContent)
            
            //let messageAttribute = MessageAttribute
            //JP HACK
            // attributes = ishdidden / type = Url / reactions
            let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: Namespaces.Message.Local, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: "", attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:])
            
            
            // Source is message?
            let source = GalleryControllerItemSource.standaloneMessage(message)
            let context = self.controller.accountContext()
            let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: 0, playbackRate: 1, synchronousLoad: false, replaceRootController: { _, ready in
                print("👹  we're in replaceRootController....")
                self.controller?.navigationController?.popToRootViewController(animated: true)
            }, baseNavigationController: navigationController, actionInteraction: nil)
            //galleryVC.isChannel = true
            galleryVC.temporaryDoNotWaitForReady = false
            
            //let nv = NavigationController(/
            //self.controller.push(galleryVC)
            
            self.controller.present(galleryVC, in: .window(.root))
        }
    }
}
extension WEVDiscoverRootNode {
    /// 搜索状态
    enum SearchStatus {
        /// 正在搜索
        case searching
        /// 搜索完成
        case searchCompleted
        /// 非搜索
        case normal
    }
}
//MARK: - Data
extension WEVDiscoverRootNode: LJScrollViewRefreshDelegate {
    func scrollViewLoadData(isHeadRefesh: Bool) {
        let channelArray = searchStatus == .normal ? selectedChannelArray : []
        let keyWord = searchStatus == .normal ? nil : searchWord
        let nextPageToken = isHeadRefesh ? nil : self.nextPageToken
        let searchOffset = (!isHeadRefesh && keyWord != nil) ? self.searchOffset : nil
        DispatchQueue.main.async {
            MBProgressHUD.showAdded(to: self.controller.view, animated: true)
        }
        LJNetManager.Video.discoverList(channelArray: channelArray,
                                        keyWord: keyWord,
                                        nextPageToken: nextPageToken,
                                        offset: searchOffset,
                                        latitude: currentLocation?.coordinate.latitude,
                                        longitude: currentLocation?.coordinate.longitude)
        {[weak self] (result) in
            guard let self = self else {return}
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.controller.view, animated: true)
                self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
            }
            if result.isSuccess,
               let data = result.successDicData,
               let list = data["liveVideoPojoList"] as? [Any],
               var array = [WEVVideoModel].deserialize(from: list) as? [WEVVideoModel],
               let nextPageToken = data["nextPageToken"] as? String {
                if isHeadRefesh {
                    self.showDataArray.removeAll()
                }
                array = array.filter { (item) -> Bool in
                    !self.showDataArray.contains(where: {$0.videoId == item.videoId})
                }
                self.nextPageToken = nextPageToken
                self.searchOffset = data["offset"] as? Int
                self.showDataArray.append(contentsOf: array)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                self.refreshEmptyView()
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
            }
        }
        
        // 下拉刷新且非搜索非筛选情况下才重新加载数据
        if isHeadRefesh && isShouldLoadBannerData {
            loadBannerData()
        }
        
    }
    
    /// 加载Banner数据
    private func loadBannerData() {
        LJNetManager.Video.discoverBannerList {[weak self] (result) in
            guard let self = self else {return}
            if result.isSuccess,
               let data = result.successArrayData,
               let array = [WEVVideoModel].deserialize(from: data) as? [WEVVideoModel] {
                self.bannerDataArray = array
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
            }
        }
    }
    
    /// 根据输入内容匹配直播名字
    private func searchLiveName(word: String) {
        LJNetManager.Video.searchName(liveName: word) {[weak self] (result) in
            guard let self = self else {return}
            if result.isSuccess,
               let data = result.successArrayData,
               let array = [WEVVideoModel.Anchor].deserialize(from: data) as? [WEVVideoModel.Anchor] {
                self.searchView.searchNameArray = array.compactMap{$0.liveName}
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
            }
        }
    }
    
}
