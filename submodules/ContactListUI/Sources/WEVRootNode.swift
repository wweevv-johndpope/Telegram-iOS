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



public struct SlimVideo: Codable {
    var id: String // youtube id
    var blob:String  // youtube payload
    //        var created_at:String
    
}

public struct Thumbnail: Codable {
    var url: String? // youtube id
    var width:Int  // youtube payload
    var height:Int
}

public struct YoutubeVideo: Codable {
    var id: String // youtube id
    var title:String  // youtube payload
    var thumbnails:[Thumbnail?]
    var description:String?
    var duration:String?
    var isLive:Bool?
    var viewCount:Int?
}


public class WEVRootNode: ASDisplayNode{
    let contactListNode: ContactListNode
    var controller:WEVRootViewController!
    private var showDataArray: [WEVVideoModel] = []
    private var slimVideos: [SlimVideo] = []
     var ytVideos: [YoutubeVideo] = []

    
    
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
    
    /// 搜索状态
    enum SearchStatus {
        /// 正在搜索
        case searching
        /// 搜索完成
        case searchCompleted
        /// 非搜索
        case normal
    }
    
    /// bannerView数据列表
    private var bannerDataArray: [WEVVideoModel] = []
    private var selectedChannelArray: [WEVChannel] = WEVChannel.allCases
    private var searchStatus: SearchStatus = .normal
    private var searchWord: String? = nil
    private var searchDataArray: [WEVVideoModel] = []

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
    
    func test(){
        
        
        /*self.controller.database?.from("slim_video").select(columns:"id,blob").execute() { result in
         switch result {
         case let .success(response):
         do {
         print(response)
         let videos = try response.decoded(to: [SlimVideo].self)
         self.slimVideos = videos
         let decoder = JSONDecoder()
         for  vid in videos{
         do {
         if let data = vid.blob.data(using: .utf8){
         let video:YoutubeVideo = try decoder.decode(YoutubeVideo.self, from:data )
         //  print("video:",video)
         self.ytVideos.append(video)
         }
         
         }catch (let ex){
         print(ex)
         }
         }
         } catch (let exception){
         print(exception)
         }
         case let .failure(error):
         print(error.localizedDescription)
         }
         DispatchQueue.main.async {
         self.collectionView?.reloadData()
         }
         }*/
        
        let url = "https://gist.githubusercontent.com/wweevv-johndpope/62f58c50ef7b2a45516cfcade369c22e/raw/9b1767cad8dcaf74220296c48f2c97b52fb767bc/response.json"
        
        let request = AF.request(url)
        request.responseDecodable(of: WEVResponse.self) { (response) in
            guard let videos = response.value else {
                print("🔥 FAILED WTF???")
                print("🔥 error:",response)
                return }
            print(videos.data?.liveVideoPojoList as Any)
            if let arr = videos.data?.liveVideoPojoList {
                self.showDataArray = arr
                self.bannerDataArray = arr
            }
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
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
//                self.scrollViewLoadData(isHeadRefesh: true)
                self.collectionView!.reloadData()
            }
//            self.present(vc, animated: true, completion: nil)
        }
        
        view.cancelAction = {[weak self] in
            guard let self = self else {return}
            self.searchStatus = .normal
            self.searchWord = nil
            self.searchBar.text = ""
            self.searchDataArray.removeAll()
            self.collectionView!.reloadData()
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
        
    private func searchLiveName(word: String) {
//        LJNetManager.Video.searchName(liveName: word) {[weak self] (result) in
//            guard let self = self else {return}
//            if result.isSuccess,
//               let data = result.successArrayData,
//               let array = [WEVVideoModel.Anchor].deserialize(from: data) as? [WEVVideoModel.Anchor] {
//                self.searchView.searchNameArray = array.compactMap{$0.liveName}
//            }else {
//                MBProgressHUD.lj.showHint(result.message)
//            }
//        }
    }
    
    private func search(word: String) {
        searchWord = word
        searchStatus = .searchCompleted
//        scrollViewLoadData(isHeadRefesh: true)
        WEVSearchRecordManager.add(record: word)
        searchView.recordArray = WEVSearchRecordManager.recordArray
    }
    
    
    /// 刷新空白提示页面
    func refreshEmptyView() {
        if showDataArray.isEmpty  {
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
         collectionView!.reloadData()
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
                make.top.equalToSuperview().offset(LJScreen.navigationBarHeight + 13)
                make.bottom.equalToSuperview().offset(-LJScreen.tabBarHeight)
            }
            
            
            let searchBarNode =  ASDisplayNode { () -> UIView in
                return self.searchBar
            }
            self.addSubnode(searchBarNode)
            searchBar.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(LJScreen.statusBarHeight)
                make.height.equalTo(44)
            }
            
       
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
    
    func getCollectionView(frame:CGRect) -> UICollectionView{
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
    
   public  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if isShowBannerView {
            return CGSize.init(width: LJScreen.width, height: 210 * LJScreen.width / 375)
        }else {
            return CGSize.zero
        }
        
    }
    
}

extension WEVRootNode: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        showDataArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverCollectionViewCell", for: indexPath) as! WEVDiscoverCollectionViewCell
        let model = showDataArray[indexPath.row]
        cell.model = model
        cell.fixConstraints()
        return cell
    }
    
        public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let bannerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "WEVDiscoverBannerView", for: indexPath) as! WEVDiscoverBannerView
            bannerView.dataArray = bannerDataArray
            bannerView.didSelected = {[weak self] (video) in
                guard let self = self else {return}
    //            let vc = WEVVideoDetailViewController.init(video: video)
//                WEVVideoCheckManger.checkAndEnterVideo(video, from: self, completion: nil)
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
        let video = ytVideos[indexPath.row]
        print("video:",video)
     
     
        let size = CGSize(width:1280,height:720)
        let url =  "https://www.youtube.com/watch?v=" + video.id

        let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: "video", websiteName: "YouTube", title:video.title, text: video.description, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))
        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: 0, id: 1), content: updatedContent)
        
        //        let messageAttribute = MessageAttribute
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


class WEVDiscoverSearchView: UITableView {
    
    /// 选中某个关键字
    public var didSelected: ((String)->())? = nil
    
    /// 选中某个关键字
    public var deleteRecord: ((String)->())? = nil
    
    /// 是否显示记录列表，否则显示搜索列表
    public var isShowRecordList = true {
        didSet {
            if oldValue != isShowRecordList {
                reloadData()
            }
        }
    }
    
    /// 调用接口匹配的关键字列表
    public var searchNameArray: [String] = [] {
        didSet {
            reloadData()
        }
    }
    
    /// 搜索记录列表
    public var recordArray: [String] = [] {
        didSet {
            reloadData()
        }
    }
    
    /// 该显示的数据
    private var dataArray: [String] {
        get {
            isShowRecordList ? recordArray : searchNameArray
        }
    }
    
    required init() {
        super.init(frame: .zero, style: .plain)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    private func initView() {
        delegate = self
        dataSource = self
        separatorStyle = .none
        backgroundColor = .clear
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = UITableView.automaticDimension
        estimatedSectionHeaderHeight = 0
        estimatedSectionFooterHeight = 0
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
    }


}

extension WEVDiscoverSearchView: UITableViewDelegate {
    
}


extension WEVDiscoverSearchView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        let title = dataArray[indexPath.row]
        cell.title = title
        cell.style = isShowRecordList ? .record : .keyword
        cell.deleteAction = {[weak self] record in
            guard let self = self else {return}
            self.deleteRecord?(record)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let title = dataArray[indexPath.row]
        didSelected?(title)
    }
    
    
}



class LJBaseTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        selectionStyle = .none
        backgroundColor = .clear
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}


extension WEVDiscoverSearchView {
    class TableViewCell: LJBaseTableViewCell {
        
        /// 样式
        enum Style {
            /// 记录
            case record
            /// 关联词
            case keyword
        }
        
        /// 样式
        public var style: Style = .record {
            didSet {
                udpateStyleImageView()
            }
        }
        
        /// 内容
        public var title: String? = nil {
            didSet {
                titleLabel.text = title
            }
        }
        
        /// 删除按键
        public var deleteAction: ((String) -> ())?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initView()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initView()
        }
        
        //MARK: UI
        
        /// 图片
        private let imgView: UIImageView = {
            let view = UIImageView()
            return view
        }()
        
        /// 标题
        private let titleLabel: UILabel = {
            let label = UILabel.lj.configure(font: LJFont.regular(14), textColor: LJColor.black)
            return label
        }()
        
        /// 删除按键
        private lazy var deleteButton: UIButton = {
            let view = UIButton.init(type: .custom)
            view.setImage(UIImage.init(named: "discover_search_record_delete"), for: .normal)
            view.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
            return view
        }()

        private func initView() {
            contentView.addSubview(imgView)
            imgView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(29)
                make.centerY.equalToSuperview()
            }
                        
            contentView.addSubview(deleteButton)
            deleteButton.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(-20)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize.init(width: 30, height: 30))
            }
            
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(61)
                make.right.equalTo(deleteButton.snp.left).offset(-10)
                make.top.bottom.equalToSuperview()
                make.height.equalTo(48)
            }
            
            udpateStyleImageView()
        }
        
        private func udpateStyleImageView() {
            imgView.image = UIImage.init(named: style == .keyword ? "discover_search" : "discover_search_record")
            deleteButton.isHidden = style == .keyword
        }

        @objc private func deleteButtonAction() {
            guard let title = title else { return }
            deleteAction?(title)
        }
    }
}

class WEVDiscoverBannerView: UICollectionReusableView {
    
    /// 选中某个
    public var didSelected: ((WEVVideoModel)->())? = nil
    
    /// 数据源
    public var dataArray: [WEVVideoModel] = [] {
        didSet {
            collectionView.reloadData()
            pageView.pageNumber = dataArray.count
            pageView.refreshCurrentPage()
        }
    }
    
    /// 当前页数
    private var currentIndex = 0 {
        didSet {
            pageView.currentPage = currentIndex
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
        
    //MARK: UI

    /// collectionView
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
       
        let collectionView = UICollectionView.init(frame: bounds, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        return collectionView
    }()
    
    /// 页码
    private let pageView: PageView = {
        let view = PageView()
        return view
    }()
    
    /// 初始视图
    private func initView() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        addSubview(pageView)
        pageView.snp.makeConstraints { (make) in
            make.right.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(2)
        }
    }
                
}

//MARK: UICollectionViewDataSource

extension WEVDiscoverBannerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let model = dataArray[indexPath.row]
        cell.model = model
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.frame.size
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        currentIndex = Int(targetContentOffset.pointee.x / frame.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataArray[indexPath.row]
        didSelected?(model)
    }

    
}

//MARK: CollectionViewCell
extension WEVDiscoverBannerView {
    class CollectionViewCell: WEVDiscoverCollectionViewCell {

        //MARK: UI
        
        /// 初始视图
        override func initView() {
            super.initView()
            
            imageView.layer.cornerRadius = 0
            imageView.snp.updateConstraints { (make) in
                make.left.right.top.bottom.equalToSuperview()
            }
            channelImageView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(16)
            }
            
            channelNameLabel.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(16)
            }
            
            liveLabel.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-15)
                make.top.equalToSuperview().offset(15)
            }
            
            amountLabel.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(15)
                make.bottom.equalToSuperview().offset(-27)
            }
        }
        
    }
}

//MARK: 页码视图
extension WEVDiscoverBannerView {
    class PageView: UIView {
        
        /// 总页数
        public var pageNumber: Int = 0 {
            didSet {
                if oldValue != pageNumber {
                    resetView()
                }
            }
        }
        
        /// 当前页码
        public var currentPage: Int = 0 {
            didSet {
                refreshCurrentPage()
            }
        }
        
        /// 线条数组
        private var lineArray: [UIView] = []
        
        /// 总页数发生改变，重置界面
        private func resetView() {
            subviews.forEach{$0.removeFromSuperview()}
            lineArray.removeAll()
            
            let lineWidth: CGFloat = 25
            let lineInterval: CGFloat = 8
            let totalWidth = lineWidth * CGFloat(pageNumber) + CGFloat(pageNumber - 1) * lineInterval
            for i in 0..<pageNumber {
                let line = UIView()
                line.backgroundColor = UIColor.init(white: 1, alpha: 0.5)
                lineArray.append(line)
                addSubview(line)
                line.snp.makeConstraints { (make) in
                    make.centerX.equalToSuperview().offset(-totalWidth / 2 + CGFloat(i) * (lineWidth + lineInterval) + lineWidth / 2.0)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(CGSize(width: lineWidth, height: 2))
                }
            }
        }
        
        /// 当前页码发生改变，刷新界面
        public func refreshCurrentPage() {
            for (i, line) in lineArray.enumerated() {
                line.backgroundColor = UIColor.init(white: 1, alpha: i == currentPage ? 1 : 0.3)
            }
        }
    }
}

class WEVDiscoverSearchBar: UIView {
    /// 样式
    enum Style {
        /// 正在搜索
        case searching
        /// 搜索完成
        case searchCompleted
        /// 非搜索
        case normal
    }
    
    /// 样式
    var style: Style = .normal {
        didSet {
            updateStyleView()
        }
    }
    
    /// 筛选按键
    public var filterAction: (()->())? = nil
  
    /// 取消搜索按键
    public var cancelAction: (()->())? = nil

    /// 输入内容改变
    public var textDidChange: ((String)->())? = nil
    
    /// 开始编辑
    public var didBeginEditing: (()->())? = nil
    
    /// 结束编辑
    public var didEndEditing: (()->())? = nil
    
    /// 点击了搜索
    public var searchAction: ((String)->())? = nil
    
    /// 输入框的文本
    public var text: String {
        get {
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
            lastSendText = newValue
        }
    }
    
    /// 上一次发出去的字符， 用来对比最新的字符串，有变化才触发textDidChange
    private var lastSendText: String?
    
    /// 结合lastSendText使用，有变化才触发textDidChange
    private var lastSendTextDate: Date?
    
    /// 输入文本发送延迟时间
    private let sendTextTimeinterval: TimeInterval = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI

    public lazy var textField: UITextField = {
        let textField = UITextField()
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 40))
        let leftImageView = UIImageView(image: UIImage.init(named: "discover_search"))
        leftImageView.frame = CGRect(x: 14, y: 11, width: 17, height: 17)
        leftView.addSubview(leftImageView)
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.backgroundColor = LJColor.hex(0xF3F3F5)
        textField.attributedPlaceholder = NSAttributedString.init(string: "Search...", attributes: [NSAttributedString.Key.font : LJFont.regular(14), .foregroundColor: LJColor.gray])
        textField.font = LJFont.regular(14)
        textField.textColor = LJColor.black
        textField.addTarget(self, action: #selector(textFieldDidChanged(textField:)), for: .editingChanged)
        textField.delegate = self
        textField.returnKeyType = .search
//        let clearButton = UIButton.init(type: .custom)
//        clearButton.setImage(UIImage.init(named: "discover_search_text_clear"), for: .normal)
//        clearButton.addTarget(self, action: #selector(clearButtonAction), for: .touchUpInside)
//        clearButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        textField.rightView = clearButton
//        textField.rightViewMode = .whileEditing
        return textField
    }()

    /// 筛选按键
    private lazy var filterButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setImage(UIImage.init(named: "discover_search_filter"), for: .normal)
        button.addTarget(self, action: #selector(filterButtonAction), for: .touchUpInside)
        return button
    }()
    
    /// 取消搜索按键
    private lazy var cancelSearchButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = LJFont.regular(14)
        button.setTitleColor(LJColor.black, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        return button
    }()

    private func initView() {
        addSubview(filterButton)
        filterButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.centerY.equalToSuperview()
        }
        
        addSubview(cancelSearchButton)
        cancelSearchButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 60, height: 40))
            make.centerY.equalToSuperview()
        }
        
        addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-54)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }
    }
    
    private func updateStyleView() {
        switch style {
        case .normal:
            cancelSearchButton.isHidden = true
            filterButton.isHidden = false
            textField.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-54)
            }
        case .searching, .searchCompleted:
            cancelSearchButton.isHidden = false
            filterButton.isHidden = true
            textField.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-75)
            }
        }
    }
    
    //MARK: Action
    
    /// 筛选按键
    @objc private func filterButtonAction() {
        filterAction?()
    }
    
    /// 取消搜索按键
    @objc private func cancelButtonAction() {
        textField.resignFirstResponder()
        cancelAction?()
    }
    
    /// 输入文本变化
    @objc private func textFieldDidChanged(textField: UITextField) {
        var text = textField.text ?? ""
        if text.count > 50 {
            text = String(text.prefix(50))
            textField.text = text
        }
        
        chekText()

    }
    
    /// 检查是否该发出文本，根据上一次发出时间与内容判断
    private func chekText() {
        let text = textField.text ?? ""
        
        guard let lastSendTextDate = lastSendTextDate,
              let lastSendText = lastSendText else {
            self.lastSendTextDate = Date()
            self.lastSendText = text
            textDidChange?(text)
            return
        }
        
        if text != lastSendText {
            let time = lastSendTextDate.timeIntervalSinceNow
            if time < -sendTextTimeinterval {
                self.lastSendTextDate = Date()
                self.lastSendText = text
                textDidChange?(text)
            }else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + sendTextTimeinterval + time) {
                    self.chekText()
                }
            }
        }

    }

}


//MARK: UITextFieldDelegate
extension WEVDiscoverSearchBar: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        didEndEditing?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchAction?(textField.text!)
        return false
    }
}


class LJBaseViewController: UIViewController {
    
    /// 是否第一个控制器，用于控制返回手势
    public var isNavRootVC = false

    /// 左边导航按键
    public var leftButton: UIButton? = nil

    /// 右边导航按键
    public var rightButton: UIButton? = nil
    
    public var leftBlock: (() -> ())? = nil

    public var rightBlock: (() -> ())? = nil
    


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isNavRootVC {
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        // Do any additional setup after loading the view.
    }
    
    //MARK: UI
    private func initView() {
        view.backgroundColor = .white
        setBackItem(isHidden: false)
        if #available(iOS 11.0, *) {
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        leftBlock = {[weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    /// 返回按键
    public func setBackItem(isHidden: Bool) {
        if isHidden {
            leftButton?.isHidden = true
        }else {
            setNavBarButtonItem(isLeft: true, image: UIImage.init(named: "nav_item_back"), title: nil)
        }
    }
    
    /// 左右导航按键
    public func setNavBarButtonItem(isLeft: Bool, image: UIImage? = nil, title: String? = nil) {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 44)
        button.setImage(image, for: UIControl.State.normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(LJColor.black, for: .normal)
        button.titleLabel?.font = LJFont.regular(16)
        if let title = title {
            let width = (title as NSString).boundingRect(with: CGSize(width: 1000, height: 30), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : LJFont.regular(16)], context: nil).width
            button.frame.size.width = width + 30
        }
        let buttonItem = UIBarButtonItem.init(customView: button)
        if isLeft {
            button.addTarget(self, action: #selector(leftButtonAction), for: .touchUpInside)
            navigationItem.leftBarButtonItem = buttonItem
            leftButton = button
        }else {
            button.addTarget(self, action: #selector(rightButtonAction), for: .touchUpInside)
            navigationItem.rightBarButtonItem = buttonItem
            rightButton = button
        }
    }

    
    /// 左边按键事件
    @objc private func leftButtonAction() {
        if let leftBlock = leftBlock {
            leftBlock()
        }else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    /// 右边边按键事件
    @objc private func rightButtonAction() {
        rightBlock?()
    }

    
    
}


//MARK: 返回手势
extension LJBaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            if (self.navigationController?.viewControllers.count == 1){
                return false
            }else{
                return true
            }
        }
        return true
    }
}



class WEVDiscoverFilterCollectionViewCell: UICollectionViewCell {
    struct Data {
        var style: Style
        var isSelected: Bool
        /// 样式
        enum Style {
            /// 所有频道
            case all
            /// 某个频道
            case channel(WEVChannel)
        }
    }

    var data: Data? {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    /// 全部
    private let allLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(12), textColor: LJColor.gray, text: "ALL")
        return label
    }()
    
    /// 频道
    private let channelLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(12))
        label.textAlignment = .center
        return label
    }()
    
    /// 频道图片
    private let channelImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private func initView() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderColor = LJColor.main.cgColor

        contentView.addSubview(allLabel)
        allLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        contentView.addSubview(channelLabel)
        channelLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.centerY).offset(12)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        
        contentView.addSubview(channelImageView)
        channelImageView.snp.makeConstraints { (make) in
            make.bottom.equalTo(channelLabel.snp.top).offset(-6)
            make.size.equalTo(CGSize(width: 33, height: 33))
            make.centerX.equalToSuperview()
        }
    }
    
    private func updateView() {
        guard let data = data else { return }
        
        switch data.style {
        case .all:
            allLabel.isHidden = false
            channelLabel.isHidden = true
            channelImageView.isHidden = true
        case .channel(let channel):
            allLabel.isHidden = true
            channelLabel.isHidden = false
            channelImageView.isHidden = false
           
            channelLabel.text = channel.title
            channelImageView.image = data.isSelected ? channel.image : channel.unselectedImage
        }
        
        if data.isSelected {
            contentView.backgroundColor = .white
            contentView.layer.borderWidth = 1.5
            allLabel.textColor = LJColor.black
            channelLabel.textColor = LJColor.black
        }else {
            contentView.backgroundColor = LJColor.hex(0xEFF0F2)
            contentView.layer.borderWidth = 0
            allLabel.textColor = LJColor.gray
            channelLabel.textColor = LJColor.gray
        }
    }
}



class WEVDiscoverFilterViewController: LJBaseViewController {
    var didSelected: (([WEVChannel])->())? = nil
    
    /// 频道列表
    private let channelArray: [WEVChannel]
    
    /// 选中的频道数组
    public var selectedArray: [WEVChannel] = []
    
    required init(allChannel: [WEVChannel], selectedArray: [WEVChannel]) {
        self.channelArray = allChannel
        self.selectedArray = selectedArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.channelArray = []
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    /// collectionView
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let width = (LJScreen.width - 30 * 2 - 15) / 2
        layout.itemSize = CGSize(width: width, height: 79 * width / 150)
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
        view.register(WEVDiscoverFilterCollectionViewCell.self, forCellWithReuseIdentifier: "WEVDiscoverFilterCollectionViewCell")
        return view
    }()
    
    /// 确认按键
    private lazy var confirmButton: UIButton = {
        let confirmButton = UIButton.lj.configure(title: "Confirm")
        confirmButton.addTarget(self, action: #selector(confirmButtonAction), for: .touchUpInside)
        return confirmButton
    }()
    
    private func initView() {
        
        /// 关闭按键
        let closeButton = UIButton.init(type: .custom)
        closeButton.setImage(UIImage.init(named: "discover_channel_filter_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 25, height: 25))
        }
        
        /// 标题
        let titleLabel = UILabel.lj.configure(font: LJFont.medium(20), textColor: LJColor.main, text: "Watch from")
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.top.equalToSuperview().offset(126)
        }
        
        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-10 - LJScreen.safeAreaBottomHeight)
        }
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        
    }
    
    //MARK: Action

    @objc private func closeButtonAction() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func confirmButtonAction() {
        guard !selectedArray.isEmpty else {return}
        didSelected?(selectedArray)
        dismiss(animated: true, completion: nil)
    }
    


}

//MARK: UICollectionViewDelegateFlowLayout
extension WEVDiscoverFilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 0, left: 30, bottom: 0, right: 30)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        15
    }
}

extension WEVDiscoverFilterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverFilterCollectionViewCell", for: indexPath) as! WEVDiscoverFilterCollectionViewCell
        if indexPath.row == 0 {
            cell.data = .init(style: .all, isSelected: selectedArray.count == channelArray.count)
        }else {
            let channel = channelArray[indexPath.row - 1]
            cell.data = .init(style: .channel(channel), isSelected: selectedArray.contains(channel))
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if selectedArray.count != channelArray.count {
                selectedArray = channelArray
            }else {
                selectedArray = []
            }
        }else {
            let channel = channelArray[indexPath.row - 1]
            if let index = selectedArray.firstIndex(where: {$0 == channel}) {
                selectedArray.remove(at: index)
            }else {
                selectedArray.append(channel)
            }
        }
        collectionView.reloadData()
        confirmButton.alpha = selectedArray.isEmpty ? 0.5 : 1
    }
    
}




class WEVEmptyHintView: UIView {
    
    struct Model {
        var title: String
        var image: String
        var desc: String?
        var descAttributedString: NSAttributedString?
    }
    
    public var model: Model? = nil {
        didSet {
            updateView()
        }
    }
    
    init(model: Model) {
        self.model = model
        super.init(frame: .zero)
        initView()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    private func initView() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview().offset(20)
        }
        
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.bottom.equalTo(titleLabel.snp.top).offset(-30)
            make.centerX.equalToSuperview()
        }
        
        addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        updateView()
    }
    
    private func updateView() {
        guard let model = model else { return }
        titleLabel.text = model.title
        imageView.image = UIImage.init(named: model.image)
        if let descAttributedString = model.descAttributedString {
            descLabel.attributedText = descAttributedString
        }else {
            descLabel.text = model.desc
        }
    }
    

    /// 图片
    public let imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    /// 标题
    public let titleLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.medium(20))
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    /// 描述
    public let descLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.regular(16), textColor: LJColor.gray)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

}

