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
