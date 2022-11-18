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
import GalleryUI

final class WEVWatchLaterControllerNode: ViewControllerTracingNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private weak var navigationBar: NavigationBar?
    private var controller: WEVWatchLaterController!
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
    
    private let supabaseUrl = LJConfig.SupabaseKeys.supabaseUrl
    private let supabaseKey = LJConfig.SupabaseKeys.supabaseKey
    var arrWatchLater: [WatchLaterVideo] = []
    private let tableView = UITableView(frame: CGRect.zero, style: .plain)
    private var currentLayout: CGSize = .zero
    private var client: PostgrestClient?
    init(context: AccountContext, presentationData: PresentationData, navigationBar: NavigationBar, controller: WEVWatchLaterController, requestActivateSearch: @escaping () -> Void, requestDeactivateSearch: @escaping () -> Void, updateCanStartEditing: @escaping (Bool?) -> Void, present: @escaping (ViewController, Any?) -> Void, push: @escaping (ViewController) -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.navigationBar = navigationBar
        self.requestActivateSearch = requestActivateSearch
        self.requestDeactivateSearch = requestDeactivateSearch
        self.present = present
        self.push = push
        self.controller = controller
        print(context.account.id.int64)
        print(context.account.peerId.id._internalGetInt64Value())
        print(context.account.peerId)
        super.init()
        
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    private var navigationController: NavigationController? {
        if let navigationController = self.controller.navigationController as? NavigationController {
            return navigationController
        }
        return nil
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
                self.updateConstriant(navigationBarHeight: navigationBarHeight)
            }
        }
        self.currentLayout = layout.size
    }
    
    private func dequeueTransitions(navigationBarHeight: CGFloat) {
        guard let _ = self.containerLayout else {
            return
        }
        
        if !self.didSetReady {
            client = PostgrestClient(
                url: "\(supabaseUrl)/rest/v1",
                headers: ["apikey": supabaseKey],
                schema: "public")
            self.didSetReady = true
            self._ready.set(true)
            self.initView(navigationBarHeight: navigationBarHeight)
        }
    }

    func toggleEditing() {
        self.isEditingValue = !self.isEditingValue
    }
    
    private func updateConstriant(navigationBarHeight: CGFloat) {
        tableView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(navigationBarHeight + 2)
            make.left.bottom.right.equalToSuperview()
        }
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
        tableView.backgroundColor = presentationData.theme.chatList.backgroundColor
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
        
        self.arrWatchLater = fetchWatchList()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
extension WEVWatchLaterControllerNode: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrWatchLater.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WEVWatchLaterTableViewCell", for: indexPath) as? WEVWatchLaterTableViewCell else {
            return UITableViewCell()
        }
        cell.configureCell(watchLater: arrWatchLater[indexPath.row], presentationData: self.presentationData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("PlayVideo")
        self.playVideo(video: arrWatchLater[indexPath.row])
    }
}
extension WEVWatchLaterControllerNode {
    
    /*func watchLaterRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.watchLater, schema: "public"))
            
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
            case .insert, .update, .delete:
                self.doWatchLaterFetch()
            default:
                break
            }
        }
        rt.connect()
    }*/
    
    func doWatchLaterFetch() {
        Task {
            await fetchWatchLater()
        }
    }
    
    
    func fetchWatchLater() async {
        guard let client = self.client else {
            return
        }
        
        var errMsg = ""
        // Get twitch videos
        do {
            let watchLater = try await client
                .from(LJConfig.SupabaseViews.watchLater)
                .select()
                .eq(column: "user_id", value: "\(context.account.peerId.id._internalGetInt64Value())")
                .execute()
                .decoded(to: [WatchLaterVideo].self)
            
            //assign watch later data to array
            self.arrWatchLater = watchLater
            //get watch later object
            for index in 0..<arrWatchLater.count where arrWatchLater[index].videoType == 1 {
                if let blob = arrWatchLater[index].blob, let data = blob.data(using: .utf8) {
                    do {
                        let video:YoutubeVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                        print("video:",video)
                        arrWatchLater[index].youTubeTitle = video.title
                        arrWatchLater[index].youTubeDescription = video.description
                        arrWatchLater[index].youTubeThumbnail = video.thumbnails[0]?.url ?? ""
                        arrWatchLater[index].youTubeViewCounts = video.viewCount
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            saveWatchList(arrWatchLater)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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
    }
    
    func doPerformAddWatchLater(videoObj: NewWatchLaterVideo) {
        Task {
            await performAddWatchLater(videoObj: videoObj)
        }
    }
    
    func performAddWatchLater(videoObj: NewWatchLaterVideo) async {
        guard let client = self.client else {
            return
        }
        do {
            let insertedVideo = try await client.from(LJConfig.SupabaseTablesName.watchLater)
                .insert(
                    values: videoObj,
                    returning: .representation
                )
                .execute()
            print(insertedVideo)
            self.doWatchLaterFetch()
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func doPerformRemoveWatchLater(id: Int64) {
        Task {
            await performRemoveWatchLater(id: id)
        }
    }
    
    func performRemoveWatchLater(id: Int64) async {
        guard let client = self.client else {
            return
        }
        do {
            try await client.from(LJConfig.SupabaseTablesName.watchLater).delete().eq(column: "id", value: "\(id)").execute()
            self.doWatchLaterFetch()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func playVideo(video: WatchLaterVideo) {
        
        var videoTitle = ""
        var videoDescription = ""
        let websiteName = "YouTube"
        var url = ""
        let isLikedVideo = true
        switch video.videoType {
        case 1:
            guard let title = video.youTubeTitle, let ytId = video.youtubeId else  {
                return
            }
            videoTitle = title
            videoDescription = video.youTubeDescription ?? ""
            url = "https://www.youtube.com/watch?v=" + ytId
        case 2:
            guard let clipURL = video.clipEmbedUrl, let title = video.clipTitle else {
                return
            }
            url = clipURL + "&autoplay=true&parent=streamernews.example.com&parent=embed.example.com"
            videoTitle = title
        case 3:
            guard let clipURL = video.rumbleEmbedUrl, let title = video.rumbleTitle else {
                return
            }
            url = clipURL
            videoTitle = title
        default:
            return
        }
        
        /*let thumbnail = UIImage(named: "channel_youtube")
         var previewRepresentations: [TelegramMediaImageRepresentation] = []
         var finalDimensions = CGSize(width:1280,height:720)
         finalDimensions = TGFitSize(finalDimensions,CGSize(width:1280,height:720))*/
        
        let size = CGSize(width:1280,height:720)
        let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: videoTitle, text: videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))
        
        
        /*if let thumbnail = thumbnail {
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
         
         }*/
        
        // let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: nil, attributes: fileAttributes)
        
        
        
        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: Namespaces.Media.CloudWebpage, id: 0), content: updatedContent)
        
        //let messageAttribute = MessageAttribute
        //JP HACK
        // attributes = ishdidden / type = Url / reactions
        let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: 0, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [MessageFlags(rawValue: 64)], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: url, attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:])
        
        
        // Source is message?
        let source = GalleryControllerItemSource.standaloneMessage(message)
        let context = self.context
        let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: nil, playbackRate: 1, synchronousLoad: false, isShowLike: true, isVideoLiked: isLikedVideo, replaceRootController: { controller, ready in
            print("👹  we're in replaceRootController....")
            if let baseNavigationController = self.navigationController {
                baseNavigationController.replaceTopController(controller, animated: false, ready: ready)
            }
        }, baseNavigationController: navigationController, actionInteraction: nil)
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.useSimpleAnimation = true
        
        /*navigationController?.view.endEditing(true)
         
         (navigationController?.topViewController as? ViewController)?.present(galleryVC, in: .window(.root), with: GalleryControllerPresentationArguments(transitionArguments: { id, media in
         return nil
         }))*/
        
        
        galleryVC.onLike = {
            print("user liked video")
            self.doPerformAddWatchLater(videoObj: NewWatchLaterVideo(videoType: video.videoType, userId: self.context.account.peerId.id._internalGetInt64Value(), twitchId: video.twitchId, youtubeId: video.youtubeId, rumbleId: video.rumbleId))
        }
        
        galleryVC.onDislike = {
            print("user unliked video")
            self.doPerformRemoveWatchLater(id: video.id)
        }
        
        self.controller.present(galleryVC, in: .window(.root))
    }
}
