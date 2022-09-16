//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import HandyJSON
import UIKit

enum WEVChannel: String, HandyJSONEnum, CaseIterable {
    
    case youtube = "YouTube"
    
    case twitch = "Twitch"
    
    case facebook = "Facebook"

//    Facebook Twitch YouTube LinkedIn Periscope
    public var title: String {
        get {
            switch self {
            case .youtube:
                return "YouTube"
            case .twitch:
                return "Twitch"
            case .facebook:
                return "Facebook"
            }
        }
    }
    
    public var image: UIImage {
        get {
            var name = ""
            switch self {
            case .youtube:
                name = "channel_youtube"
            case .twitch:
                name = "channel_twitch"
            case .facebook:
                name = "channel_facebook"
            }
            return UIImage.init(named: name) ?? UIImage()
        }
    }
    
    public var smallImage: UIImage {
        get {
            var name = ""
            switch self {
            case .youtube:
                name = "channel_youtube_small"
            case .twitch:
                name = "channel_twitch_small"
            case .facebook:
                name = "channel_facebook_small"
            }
            return UIImage.init(named: name) ?? UIImage()
        }
    }

    public var unselectedImage: UIImage {
        get {
            var name = ""
            switch self {
            case .youtube:
                name = "channel_youtube_unselected"
            case .twitch:
                name = "channel_twitch_unselected"
            case .facebook:
                name = "channel_facebook_unselected"
            }
            return UIImage.init(named: name) ?? UIImage()
        }
    }
}
