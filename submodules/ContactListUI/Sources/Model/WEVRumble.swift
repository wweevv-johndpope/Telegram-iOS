//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

// MARK: - Crew
struct RumbleVideo: Codable {
    let id: Int64
    let title: String
    let thumbnailUrl: String
    let embedUrl: String
    let m3u8Url: String?
    let viewerCount: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailUrl = "thumbnail_url"
        case embedUrl = "embed_url"
        case m3u8Url = "m3u8"
        case viewerCount = "viewer_count"
    }
}
