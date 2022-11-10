//
//  LJConfig.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation

struct LJConfig {
        
    static var isDebug: Bool {
        environment == .debug
    }
    
    static var baseURL: String {
        switch environment {
        case .debug:
            //return "http://192.168.50.100:10031/"
            return "https://api.wweevv.app/"
        case .release:
            return "https://api.wweevv.app/"
        }
    }
    
    static var videoUrl: String {
        switch environment {
        case .debug:
            //return "http://192.168.50.100/wweevv_web/#/video"
            return "https://admin.wweevv.app/#/video"
        case .release:
            return "https://admin.wweevv.app/#/video"
        }
    }

    static let AppID = "1561108032"
    
    /// Twitch授权
    struct Twitch {
        static let clientId = "l18dmbt90mg62552sedbel934401gb"
        static let state = "wweevv2021luanqibazao"
        static let uri = "https://wweevv.app/"
    }
    
    /// YouTube授权
    struct YouTube {
        static let clientID = "795614219186-k5ms8k92brdsu1lk9b8jt3q26cgurh6l.apps.googleusercontent.com"
        static let redirectURL = "https://wweevv.app/"
    }
    
    /// 运行环境
    enum Environment {
        /// 开发
        case debug
        /// 生产
        case release
    }

    /// 运行环境
    static var environment: Environment {
        #if DEBUG
            return .debug
        #endif
        #if NDEBUG
            return .release
        #endif
    }
    
    struct SupabaseKeys {
        //Live
        static let supabaseUrl = "https://pqxcxltwoifmxcmhghzf.supabase.co"
        static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxeGN4bHR3b2lmbXhjbWhnaHpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjAxODczNDQsImV4cCI6MTk3NTc2MzM0NH0.NiufAQmZ3Oy7eP7wNWF-tvH-e2D-UIz-vPLpLAyDMow"
        
        //Development
        static let supabaseUrlDev = "https://rlzbzdrueihvlzcqskgd.supabase.co"
        static let supabaseKeyDev = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJsemJ6ZHJ1ZWlodmx6Y3Fza2dkIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQ2MDE3MTYsImV4cCI6MTk4MDE3NzcxNn0.vlmVDDf50rb5SJ68F5u6IyckeTrW9c6Oa3_YhFyhD7c"
        
    }
    
    struct API {
        static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ7XCJ1c2VySWRcIjpcInVzX2M1TTN6MER4OHZcIixcImVtYWlsXCI6XCJ3d2VldnYxQGdtYWlsLmNvbVwifSIsImlhdCI6MTY2MzI0MTQ2N30.GEYCOKk5xbsMX0lk0q0EE6nRl4KiHRaFzYS2i2M3PSuATx82i_giIu-UE3wJq3owPTxCQD47q67V92SL1Q3q5A"
    }
    
    struct SupabaseColumns {
        static let clips = "id,user_id,user_name,profile_image_url,clip_id,clip_embed_url,clip_title,clip_view_count,clip_thumbnail_url"
        static let youtube = "id,blob,channelId,channelTitle"
        static let rumble = "id,title,thumbnail_url,embed_url,m3u8,viewer_count"
    }
    
    struct SupabaseTablesName {
        static let youtube = "slim_video"
        static let clips = "clips"
        static let rumble = "rumble"
        static let watchLater = "watch_later"
        static let subscribeVideo = "subscribed_channel"
    }
    
    struct SupabaseViews {
        static let watchLater = "watch_later_view"
        static let subscribeView = "subscribed_channels_view"
    }
}

func printLog<T>(_ message: T,
                 file: String = #file,
                 method: String = #function,
                 line: Int = #line) {
    switch LJConfig.environment {
    case .debug:
        let log = "\(Date()), \((file as NSString).lastPathComponent)[\(line)], \(method):\n \(message)"
        print(log)
        LJDebugTool.share.appendLog(log)
    case .release:
        break
    }
}
