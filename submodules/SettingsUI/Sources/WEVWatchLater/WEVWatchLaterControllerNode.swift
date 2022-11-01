import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import MergeLists
import ItemListUI
import PresentationDataUtils
import AccountContext
import ShareController
import SearchBarNode
import SearchUI
import UndoUI
import TelegramUIPreferences
import TranslateUI
import ContactListUI
import PostgREST


final class WEVWatchLaterControllerNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private weak var navigationBar: NavigationBar?
    private let requestActivateSearch: () -> Void
    private let requestDeactivateSearch: () -> Void
    private let present: (ViewController, Any?) -> Void
    private let push: (ViewController) -> Void
    
    private var didSetReady = false
    let _ready = ValuePromise<Bool>()
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    private let presentationDataValue = Promise<PresentationData>()
    private let isEditing = ValuePromise<Bool>(false)
    private var isEditingValue: Bool = false {
        didSet {
            self.isEditing.set(self.isEditingValue)
        }
    }
    
    private let supabaseUrl = LJConfig.SupabaseKeys.supabaseUrlDev
    private let supabaseKey = LJConfig.SupabaseKeys.supabaseKeyDev
    var arrWatchLater: [WatchLaterVideo] = fetchWatchList()
    private let tableView = UITableView()
    private var currentLayout: CGSize = .zero
    
    init(context: AccountContext, presentationData: PresentationData, navigationBar: NavigationBar, requestActivateSearch: @escaping () -> Void, requestDeactivateSearch: @escaping () -> Void, updateCanStartEditing: @escaping (Bool?) -> Void, present: @escaping (ViewController, Any?) -> Void, push: @escaping (ViewController) -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.navigationBar = navigationBar
        self.requestActivateSearch = requestActivateSearch
        self.requestDeactivateSearch = requestDeactivateSearch
        self.present = present
        self.push = push
        print(context.account.id.int64)
        print(context.account.peerId.id._internalGetInt64Value())
        print(context.account.peerId)
        super.init()
        
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    deinit {
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let hadValidLayout = self.containerLayout != nil
        self.containerLayout = (layout, navigationBarHeight)
        
        if !hadValidLayout {
            self.dequeueTransitions(navigationBarHeight: navigationBarHeight)
        } else {
            if self.currentLayout != layout.size {
                self.didSetReady = false
                self.dequeueTransitions(navigationBarHeight: navigationBarHeight)
            }
        }
        self.currentLayout = layout.size
    }
    
    private func dequeueTransitions(navigationBarHeight: CGFloat) {
        guard let _ = self.containerLayout else {
            return
        }
        
        if !self.didSetReady {
            self.didSetReady = true
            self._ready.set(true)
            self.initView(navigationBarHeight: navigationBarHeight)
        }
    }

    func toggleEditing() {
        self.isEditingValue = !self.isEditingValue
    }
    
    private func initView(navigationBarHeight: CGFloat) {
        let tableViewNode =  ASDisplayNode { () -> UIView in
            return self.tableView
        }
        self.addSubnode(tableViewNode)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(navigationBarHeight + 2)
            make.left.bottom.right.equalToSuperview()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.register(WEVWatchLaterTableViewCell.self, forCellReuseIdentifier: "WEVWatchLaterTableViewCell")
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
extension WEVWatchLaterControllerNode: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WEVWatchLaterTableViewCell", for: indexPath) as? WEVWatchLaterTableViewCell else {
            return UITableViewCell()
        }
        cell.imgView.backgroundColor = .green
        cell.titleLabel.text = "Test test ad njnajdnjkadkakdandna"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("PlayVideo")
    }
}
extension WEVWatchLaterControllerNode {
    
    func fetchWatchLaterVideos() async {
        let client = PostgrestClient(
            url: "\(supabaseUrl)/rest/v1",
            headers: ["apikey": supabaseKey],
            schema: "public")
        // Get twitch videos
        do {
             let watchLater = try await client
            .from("watch_later_view")
            .select()
            .eq(column: "user_id", value: 1725238)
            .execute()
            //.decoded(to: [WatchLaterVideo].self)
            .json()
            
            print(watchLater)
            //assign watch later data to array
            /*self.arrWatchLater = watchLater
            //get watch later object
            for index in 0..<arrWatchLater.count where arrWatchLater[index].videoType == 1 {
                if let blob = arrWatchLater[index].blob, let data = blob.data(using: .utf8) {
                    do {
                        let video:YoutubeVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                        print("video:",video)
                        arrWatchLater[index].youtubeData = video
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            saveWatchList(arrWatchLater)*/
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func playVideo() {
        
    }
    
    func saveWatchLater(isSaved: Bool = false) {
        
    }
}
