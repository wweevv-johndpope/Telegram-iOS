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
import HandyJSON
import Alamofire
import GalleryUI
import Postbox
import TelegramCore
import InstantPageUI
import MBProgressHUD
import HandyJSON
import CoreLocation
import MXSegmentedControl
//import Kingfisher
import Realtime
import LegacyComponents
import SwiftSignalKit

public class WEVDiscoverRootNode: ASDisplayNode {
    
    let contactListNode: ContactListNode
    var controller:WEVRootViewController!
    
    private let context: AccountContext
    private(set) var searchDisplayController: SearchDisplayController?
    private var offersTableViewNode:ASDisplayNode?
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    //var interactor:WCInteractor?
    var navigationBar: NavigationBar?
    var listNode:ListView!
    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((ContactListPeer) -> Void)?
    var requestAddContact: ((String) -> Void)?
    var openPeopleNearby: (() -> Void)?
    var openInvite: (() -> Void)?

    var ytVideos: [YoutubeVideo] = []
    var twichVideos: [SlimTwitchVideo] = []
    var rumbleVideos: [RumbleVideo] = []
    var isLaunchSync: Bool = false

    
    /// 根据状态返回该显示的视频
    private var showDataArray: [WEVVideoModel] {
        get {
            switch searchStatus {
            case .searchCompleted:
                return searchDataArray
            case .youtube:
                return []
            case .twitch:
                return []
            case .rumble:
                return []
            case .filtered:
                return dataArray
            case .searching:
                return []
            }
        }
        set {
            switch searchStatus {
            case .searchCompleted:
                searchDataArray = newValue
            case .youtube:
                break
            case .twitch:
                break
            case .rumble:
                break
            case .filtered:
                dataArray = newValue
            case .searching:
                break
            }
        }
    }
    
    //var ytVideos: [YoutubeVideo] = []
    
    /// bannerView数据列表
    private var bannerDataArray: [WEVVideoModel] = []
    //filter
    private var selectedChannelArray: [WEVChannel] = WEVChannel.allCases
    /// 关键字搜索情况下的请求才需要传，由上个请求得到，第一页传nil
    private var segementChannelAraay: [WEVChannel] = [WEVChannel.youtube]
    private var searchOffset: Int?
    //seatch VC
    private var searchStatus: SearchStatus = .youtube
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
        view.presentationData = self.presentationData
        return view
    }()
    
    /// 是否需要刷新banner
    private var isShouldLoadBannerData: Bool {
        get {
            // 非搜索非筛选
            (selectedChannelArray.isEmpty || selectedChannelArray.count == WEVChannel.allCases.count)
            && (searchStatus == .youtube || searchStatus == .twitch)
        }
    }
    
    /// 是否应该显示banner
    private var isShowBannerView: Bool {
        get {
            isShouldLoadBannerData && !bannerDataArray.isEmpty
        }
    }
    
    var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var mServicesTableView:ASDisplayNode?
    
    
    //segment control
    private lazy var segmentControl: MXSegmentedControl = {
        let segment = MXSegmentedControl()
        segment.append(title: "Youtube")
            .set(image: #imageLiteral(resourceName: "segment_youtube"))
            .set(image: .left)
            .set(padding: 16)
        segment.append(title: "Twitch")
            .set(image: #imageLiteral(resourceName: "segemnt_twitch"))
            .set(image: .left)
            .set(padding: 16)
        segment.append(title: "Rumble")
            .set(image: #imageLiteral(resourceName: "segment-rumble"))
            .set(image: .left)
            .set(padding: 16)
        segment.indicatorHeight = 3
        segment.indicatorColor = self.presentationData.theme.rootController.tabBar.selectedIconColor
        segment.separatorWidth = 0.5
        segment.backgroundColor = self.presentationData.theme.contextMenu.backgroundColor
        segment.separatorColor = .systemGroupedBackground
        segment.addTarget(self, action: #selector(segementChanged(sender:)), for: UIControl.Event.valueChanged)
        segment.selectedTextColor = self.presentationData.theme.rootController.tabBar.selectedIconColor
        segment.separatorBottom = 5
        return segment
    }()
    
    
    lazy var segmentHeight: CGFloat = 44
    lazy var navigationBarHeight: CGFloat = 50

    
    private lazy var searchView: WEVDiscoverSearchView = {
        let view = WEVDiscoverSearchView()
        view.presentationData = self.presentationData
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
        view.presentationData = self.presentationData
        view.filterAction = {[weak self] in
            guard let self = self else {return}
            let vc = WEVDiscoverFilterViewController(allChannel: WEVChannel.allCases, selectedArray: self.selectedChannelArray)
            vc.selectedArray = self.selectedChannelArray
            vc.didSelected = {[weak self] channelArray in
                guard let self = self else {return}
                if channelArray.count == WEVChannel.allCases.count {
                    self.searchStatus = .youtube
                } else {
                    self.searchStatus = .filtered
                }
                self.showDataArray = []
                DispatchQueue.main.async {
                    self.collectionView!.reloadData()
                    self.updateCollectionViewContraint(isShowing: channelArray.count == WEVChannel.allCases.count ? true : false)
                    if self.searchStatus != .filtered {
                        self.refreshEmptyView()
                    }
                }
                //fetch filter data
                self.selectedChannelArray = channelArray
                self.scrollViewLoadData(isHeadRefesh: true)
            }
            self.controller.present(vc, animated: true, completion: nil)
        }
        
        view.cancelAction = {[weak self] in
            guard let self = self else {return}
            self.searchStatus = self.segmentControl.selectedIndex == 0 ? .youtube : .twitch
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
    
    
    
    func fetchYoutubeVideos(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.youtube).select(columns:LJConfig.SupabaseColumns.youtube).execute() { result in
            switch result {
            case let .success(response):
                do {
                    print(response)
                    let videos = try response.decoded(to: [SlimVideo].self)
                    let decoder = JSONDecoder()
                    for  vid in videos{
                        do {
                            if let data = vid.blob.data(using: .utf8) {
                                let video:YoutubeVideo = try decoder.decode(YoutubeVideo.self, from:data )
                                print("video:",video)
                                self.ytVideos.append(video)
                            }
                        }catch (let ex){
                            print(ex)
                        }
                    }
                } catch (let error){
                    /*DispatchQueue.main.async {
                        MBProgressHUD.lj.showHint(error.localizedDescription)
                    }*/
                    debugPrint(error.localizedDescription)
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
    func fethcTwithVideo(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.clips).select(columns:LJConfig.SupabaseColumns.clips).execute() { result in
            switch result {
            case let .success(response):
                var errMsg = ""
                do {
                    print("🌻 :",response)
                    let videos = try response.decoded(to: [SlimTwitchVideo].self)
                    self.twichVideos.append(contentsOf: videos)
                    
                } catch let DecodingError.dataCorrupted(context) {
                    errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.keyNotFound(key, context) {
                    errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.valueNotFound(value, context) {
                    errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.typeMismatch(type, context)  {
                    errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
                } catch {
                    errMsg = "error: " + error.localizedDescription
                }
                if !errMsg.isEmpty {
                    print("<<<<<<<<",errMsg,">>>>>>")
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
    func fethcRumbleVideo(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.rumble).select(columns:LJConfig.SupabaseColumns.rumble).execute() { result in
            switch result {
            case let .success(response):
                var errMsg = ""
                do {
                    print("🌻 :",response)
                    let videos = try response.decoded(to: [RumbleVideo].self)
                    self.rumbleVideos.append(contentsOf: videos)
                    
                } catch let DecodingError.dataCorrupted(context) {
                    errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
                        
                } catch let DecodingError.keyNotFound(key, context) {
                    errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.valueNotFound(value, context) {
                    errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"

                } catch let DecodingError.typeMismatch(type, context)  {
                    errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
                } catch {
                    errMsg = "error: " + error.localizedDescription
                }
                if !errMsg.isEmpty {
                    print("<<<<<<<<",errMsg,">>>>>>")
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
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
        if !isShowBannerView {
            switch searchStatus {
            case .youtube:
                if ytVideos.isEmpty && isLaunchSync {
                    let model = WEVEmptyHintView.Model.init(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .twitch:
                if twichVideos.isEmpty && isLaunchSync {
                    let model = WEVEmptyHintView.Model.init(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .rumble:
                if rumbleVideos.isEmpty && isLaunchSync {
                    let model = WEVEmptyHintView.Model.init(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .searchCompleted, .filtered:
                if showDataArray.isEmpty {
                    let model = WEVEmptyHintView.Model.init(title: "Oops!... no results found", image: "empty_discover_search", desc: "There are no results matching your search. Check your spelling or try another keyword.")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            default:
                emptyView.removeFromSuperview()
                break
            }
        }else {
            emptyView.removeFromSuperview()
        }
    }
    
    func showEmptyView() {
        emptyView.removeFromSuperview()
        collectionView!.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.size.equalToSuperview()
        }
    }
    
    /// 刷新搜索状态相关视图
    private func refreshSearchStatusView(isInitial: Bool = false) {
        
        /// 是否显示搜索界面
        func updateListView(_ isShowSearchView: Bool) {
            collectionView!.isHidden = isShowSearchView
            searchView.isHidden = !isShowSearchView
        }
        
        switch searchStatus {
        case .searching:
            updateListView(true)
            searchBar.style = .searching
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if !isInitial {
                    self.updateCollectionViewContraint(isShowing: false)
                }
            }
        case .youtube:
            updateListView(false)
            searchBar.style = .normal
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if !isInitial && self.selectedChannelArray.count == WEVChannel.allCases.count {
                    self.updateCollectionViewContraint(isShowing: true)
                }
            }
        case .twitch:
            updateListView(false)
            searchBar.style = .normal
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if !isInitial && self.selectedChannelArray.count == WEVChannel.allCases.count {
                    self.updateCollectionViewContraint(isShowing: true)
                }
            }
        case .searchCompleted:
            updateListView(false)
            searchBar.style = .searchCompleted
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                /*if !isInitial {
                    self.updateCollectionViewContraint(isShowing: false)
                }*/
            }
        default:
            break
        }
    }
    
    @objc func segementChanged(sender: MXSegmentedControl) {
        //remove all selected channel Array
        /*segementChannelAraay.removeAll()
        segementChannelAraay.append(sender.selectedIndex == 0 ? WEVChannel.youtube : WEVChannel.twitch)*/
        //api call to get data
        //self.scrollViewLoadData(isHeadRefesh: true)
        switch sender.selectedIndex {
        case 0:
            searchStatus = .youtube
        case 1:
            searchStatus = .twitch
        case 2:
            searchStatus = .rumble
        default:
            return
        }
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
            self.refreshEmptyView()
        }
    }
    
    func updateCollectionViewContraint(isShowing: Bool) {
        if isShowing {
            self.collectionView?.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(navigationBarHeight + segmentHeight)
            })
        } else {
            self.collectionView?.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(navigationBarHeight)
            })
        }
        UIView.animate(withDuration: 0.25) {
            self.controller.view.layoutIfNeeded()
        }
    }
    
    init(context: AccountContext, sortOrder: Signal<ContactsSortOrder, NoError>, present: @escaping (ViewController, Any?) -> Void, controller: WEVRootViewController) {
        self.context = context
        
        self.controller = controller
        //BlockchainTest().decode()
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        
        let options = [ContactListAdditionalOption(title: presentationData.strings.Contacts_AddPeopleNearby, icon: .generic(UIImage(bundleImageName: "Contact List/PeopleNearbyIcon")!), action: {
            //addNearbyImpl?()
        }), ContactListAdditionalOption(title: presentationData.strings.Contacts_InviteFriends, icon: .generic(UIImage(bundleImageName: "Contact List/AddMemberIcon")!), action: {
            //inviteImpl?()
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

        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
        
    }
    
    func twitchRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(LJConfig.SupabaseKeys.supabaseUrl)/realtime/v1", params: ["apikey": LJConfig.SupabaseKeys.supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.clips, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert:
                if let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .twitch {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                                            self.twichVideos.insert(video, at: 0)
                                            let indertIndexPaths = IndexPath(item: 0, section: 0)
                                            collectionView.insertItems(at: [indertIndexPaths])
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                        self.refreshEmptyView()
                                    }
                                }
                            }
                        } else {
                            let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                            self.twichVideos.insert(video, at: 0)
                        }
                    }catch {
                    }
                }
            case .update:
                if let oldRecord = message.payload["old_record"] as? [String:Any], let id = oldRecord["id"] as? Int64, let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .twitch {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                                                let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                                                self.twichVideos[index] = video
                                                let indertIndexPaths = IndexPath(item: index, section: 0)
                                                collectionView.reloadItems(at: [indertIndexPaths])
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                    }
                                }
                            }
                        } else if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                            let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                            self.twichVideos[index] = video
                        }
                    }catch {
                    }
                }
            case .delete:
                if let record = message.payload["old_record"] as? [String:Any], let id = record["id"] as? Int64 {
                    if let collectionView = self.collectionView, self.searchStatus == .twitch {
                        UIView.performWithoutAnimation {
                            DispatchQueue.main.async {
                                collectionView.performBatchUpdates {
                                    if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                                        self.twichVideos.remove(at: index)
                                        let deleteIndexPaths = IndexPath(item: index, section: 0)
                                        collectionView.deleteItems(at: [deleteIndexPaths])
                                    }
                                } completion: { isFinished in
                                    self.refreshEmptyView()
                                }
                            }
                        }
                    } else if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                        self.twichVideos.remove(at: index)
                    }
                }
                break
            default:
                break
            }
         }
        rt.connect()
    }
    
    func rumbleRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(LJConfig.SupabaseKeys.supabaseUrl)/realtime/v1", params: ["apikey": LJConfig.SupabaseKeys.supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.rumble, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert:
                if let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .rumble {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                                            self.rumbleVideos.insert(video, at: 0)
                                            let indertIndexPaths = IndexPath(item: 0, section: 0)
                                            collectionView.insertItems(at: [indertIndexPaths])
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                        self.refreshEmptyView()
                                    }
                                }
                            }
                        } else {
                            let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                            self.rumbleVideos.insert(video, at: 0)
                        }
                    }catch {
                    }
                }
            case .update:
                if let oldRecord = message.payload["old_record"] as? [String:Any], let id = oldRecord["id"] as? Int64, let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .rumble {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                                                let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                                                self.rumbleVideos[index] = video
                                                let indertIndexPaths = IndexPath(item: index, section: 0)
                                                collectionView.reloadItems(at: [indertIndexPaths])
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                    }
                                }
                            }
                        } else if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                            let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                            self.rumbleVideos[index] = video
                        }
                    }catch {
                    }
                }
            case .delete:
                if let record = message.payload["old_record"] as? [String:Any], let id = record["id"] as? Int64 {
                    if let collectionView = self.collectionView, self.searchStatus == .rumble {
                        UIView.performWithoutAnimation {
                            DispatchQueue.main.async {
                                collectionView.performBatchUpdates {
                                    if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                                        self.rumbleVideos.remove(at: index)
                                        let deleteIndexPaths = IndexPath(item: index, section: 0)
                                        collectionView.deleteItems(at: [deleteIndexPaths])
                                    }
                                } completion: { isFinished in
                                    self.refreshEmptyView()
                                }
                            }
                        }
                    } else if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                        self.rumbleVideos.remove(at: index)
                    }
                }
                break
            default:
                break
            }
         }
        rt.connect()
    }
    
    func youTubeRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(LJConfig.SupabaseKeys.supabaseUrl)/realtime/v1", params: ["apikey": LJConfig.SupabaseKeys.supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.youtube, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert:
                if let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .youtube {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                                            if let data = video.blob.data(using: .utf8) {
                                                let ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                                                self.ytVideos.insert(ytVideo, at: 0)
                                                let indertIndexPaths = IndexPath(item: 0, section: 0)
                                                collectionView.insertItems(at: [indertIndexPaths])
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                        self.refreshEmptyView()
                                    }
                                }
                            }
                        } else {
                            let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                            if let data = video.blob.data(using: .utf8) {
                                let ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data )
                                self.ytVideos.insert(ytVideo, at: 0)
                            }
                        }
                    }catch {
                    }
                }
            case .update:
                if let oldRecord = message.payload["old_record"] as? [String:Any], let id = oldRecord["id"] as? String, let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .youtube {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                                                let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                                                if let data = video.blob.data(using: .utf8) {
                                                    let ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                                                    self.ytVideos[index] = ytVideo
                                                    let indertIndexPaths = IndexPath(item: index, section: 0)
                                                    collectionView.reloadItems(at: [indertIndexPaths])
                                                }
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                    }
                                }
                            }
                        } else if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                            let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                            if let data = video.blob.data(using: .utf8) {
                                let ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                                self.ytVideos[index] = ytVideo
                            }
                        }
                    }catch {
                    }
                }
            case .delete:
                if let record = message.payload["old_record"] as? [String:Any], let id = record["id"] as? String {
                    if let collectionView = self.collectionView, self.searchStatus == .youtube {
                        UIView.performWithoutAnimation {
                            DispatchQueue.main.async {
                                collectionView.performBatchUpdates {
                                    if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                                        self.ytVideos.remove(at: index)
                                        let deleteIndexPaths = IndexPath(item: index, section: 0)
                                        collectionView.deleteItems(at: [deleteIndexPaths])
                                    }
                                } completion: { isFinished in
                                    self.refreshEmptyView()
                                }
                            }
                        }
                    } else if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                        self.ytVideos.remove(at: index)
                    }
                }
                break
            default:
                break
            }
         }
        rt.connect()
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    var collectionView: UICollectionView?
    
    func updateThemeAndStrings() {
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
        self.searchDisplayController?.updatePresentationData(self.presentationData)
        self.segmentControl.indicatorColor = self.presentationData.theme.rootController.tabBar.selectedIconColor
        self.segmentControl.selectedTextColor = self.presentationData.theme.rootController.tabBar.selectedIconColor
        self.segmentControl.backgroundColor = self.presentationData.theme.contextMenu.backgroundColor
        self.emptyView.presentationData = self.presentationData
        self.searchBar.presentationData = self.presentationData
        self.searchView.presentationData = self.presentationData
        if let collectionView = collectionView {
            collectionView.backgroundColor = presentationData.theme.chatList.backgroundColor
        }
        
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
            let segmentControlNode = ASDisplayNode { () -> UIView in
                return self.segmentControl
            }
            
            // 2. add node to view hierachy > then snapkit
            self.addSubnode(segmentControlNode)
            self.navigationBarHeight = navigationBarHeight
            segmentControl.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(navigationBarHeight)
                make.height.equalTo(segmentHeight)
            }
            
           // 1. convert to ASDisplayNode
            mServicesTableView = ASDisplayNode { () -> UIView in
                return self.getCollectionView(frame: .zero)
            }
            // 2. add node to view hierachy > then snapkit
            self.addSubnode(mServicesTableView!)
            collectionView?.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(navigationBarHeight + segmentHeight)
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
            
            if isLaunchSync {
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    self.refreshEmptyView()
                }
            }
        }
        
        refreshSearchStatusView(isInitial: true)
        
    }
    
    func getCollectionView(frame:CGRect) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        let width = (LJScreen.width - 1 * 2 - 1) / 2
        layout.itemSize = CGSize(width: width, height: 97 * width / 186)
        let view = UICollectionView.init(frame: frame, collectionViewLayout: layout)
        view.backgroundColor = presentationData.theme.chatList.backgroundColor
        view.delegate = self
        view.dataSource = self
        view.register(WEVDiscoverCollectionViewCell.self, forCellWithReuseIdentifier: "WEVDiscoverCollectionViewCell")
        view.register(WEVDiscoverBannerView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WEVDiscoverBannerView")
        view.contentInsetAdjustmentBehavior = .never
        //Code for pull to refresh
        //view.lj.addMJReshreHeader(delegate: self)
        //view.lj.addMJReshreFooter(delegate: self)
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
        switch searchStatus {
        case .youtube:
            return ytVideos.count
        case .twitch:
            return twichVideos.count
        case .rumble:
            return rumbleVideos.count
        default:
            return showDataArray.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverCollectionViewCell", for: indexPath) as! WEVDiscoverCollectionViewCell
        switch searchStatus {
        case .youtube:
            cell.ytModel = ytVideos[indexPath.row]
        case .twitch:
            cell.twitchModel = twichVideos[indexPath.row]
        case .rumble:
            cell.rumbleModel = rumbleVideos[indexPath.row]
        default:
            cell.model = showDataArray[indexPath.row]
        }
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
        switch searchStatus {
        case .youtube:
            self.playClips(video: ytVideos[indexPath.row])
        case .twitch:
            self.playClips(clip: twichVideos[indexPath.row])
        case .rumble:
            self.playClips(rumbleVideo: rumbleVideos[indexPath.row])
        default:
            self.playVideo(video: showDataArray[indexPath.row])
        }
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
    
    func playClips(video: YoutubeVideo? = nil, clip: SlimTwitchVideo? = nil, rumbleVideo: RumbleVideo? = nil) {
        
        var videoTitle = ""
        var videoDescription = ""
        let websiteName = "YouTube"
        var url = ""
        if let ytVideo = video {
            videoTitle = ytVideo.title
            videoDescription = ytVideo.description ?? ""
            url = "https://www.youtube.com/watch?v=" + ytVideo.id
        } else if let twitch = clip {
            url = twitch.clipEmbedUrl + "&autoplay=true&parent=streamernews.example.com&parent=embed.example.com"
            videoTitle = twitch.clipTitle
            //let thumbURL = URL(string: twitch.clipThumbnailUrl)
            //KingfisherManager.shared.cache.retrieveImage(forKey: twitch.clipThumbnailUrl) { result in
                //print(result)
            //}
        } else if let rumble = rumbleVideo {
            url = rumble.embedUrl
            videoTitle = rumble.title
        } else {
            return
        }
        
        let thumbnail = UIImage(named: "channel_youtube")
        var previewRepresentations: [TelegramMediaImageRepresentation] = []
        var finalDimensions = CGSize(width:1280,height:720)
        finalDimensions = TGFitSize(finalDimensions,CGSize(width:1280,height:720))
        
        let size = CGSize(width:1280,height:720)
        var updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: videoTitle, text: videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))

        
        if let thumbnail = thumbnail {
            let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
            let thumbnailSize = finalDimensions.aspectFitted(CGSize(width:1280,height:720))
            let thumbnailImage = TGScaleImageToPixelSize(thumbnail, thumbnailSize)!
            if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                //account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil))
            //}
            //let data = thumbnail.pngData()
            let media = TelegramMediaImage(imageId: MediaId(namespace: 0, id: 0), representations: previewRepresentations, immediateThumbnailData: thumbnailData, reference: nil, partialReference: nil, flags: [])
            
            updatedContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: videoTitle, text: videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: media, file: nil, attributes: [], instantPage: nil))
            }

        }
        
       // let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: nil, attributes: fileAttributes)



        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: Namespaces.Media.CloudWebpage, id: 0), content: updatedContent)
        
        
        
        //let messageAttribute = MessageAttribute
        //JP HACK
        // attributes = ishdidden / type = Url / reactions
        let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: 0, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [MessageFlags(rawValue: 64)], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: url, attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:])
        
        
        // Source is message?
        let source = GalleryControllerItemSource.standaloneMessage(message)
        let context = self.controller.accountContext()
        let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: nil, playbackRate: 1, synchronousLoad: false, isShowLike: true, isVideoLiked: false, replaceRootController: { controller, ready in
            print("👹  we're in replaceRootController....")
            if let baseNavigationController = self.navigationController {
                baseNavigationController.replaceTopController(controller, animated: false, ready: ready)
            }
        }, baseNavigationController: navigationController, actionInteraction: nil)
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.useSimpleAnimation = true

        navigationController?.view.endEditing(true)

        (navigationController?.topViewController as? ViewController)?.present(galleryVC, in: .window(.root), with: GalleryControllerPresentationArguments(transitionArguments: { id, media in
            return nil
        }))

        
        galleryVC.onLike = {
            print("user liked video")
        }
        
        galleryVC.onDislike = {
            print("user unliked video")
        }
        
        //self.controller.present(galleryVC, in: .window(.root))
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
        case youtube
        
        case twitch
        
        case rumble
        
        case filtered
    }
    
    /*enum SelectedTab {
        //home screen Tab
        case youtube
        //home screen twitch
        case twitch
    }*/
}
//MARK: - Data
extension WEVDiscoverRootNode: LJScrollViewRefreshDelegate {
    func scrollViewLoadData(isHeadRefesh: Bool) {
        
        switch searchStatus {
        case .youtube, .twitch:
            DispatchQueue.main.async {
                self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
            }
            return
        default:
            break
        }
        
        let channelArray = self.searchStatus == .filtered ? selectedChannelArray : []
        let keyWord = (searchStatus == .youtube || searchStatus == .twitch) ? nil : searchWord
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
                self.refreshEmptyView()
            }
        }
        
        // 下拉刷新且非搜索非筛选情况下才重新加载数据
        /*if isHeadRefesh && isShouldLoadBannerData {
            loadBannerData { success in
            }
        }*/
    }
    
    /// 加载Banner数据
    private func loadBannerData(completion: @escaping (_ success: Bool) -> Void) {
        LJNetManager.Video.discoverBannerList {[weak self] (result) in
            guard let self = self else {return}
            if result.isSuccess,
               let data = result.successArrayData,
               let array = [WEVVideoModel].deserialize(from: data) as? [WEVVideoModel] {
                self.bannerDataArray = array
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                completion(result.isSuccess)
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
                completion(result.isSuccess)
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
