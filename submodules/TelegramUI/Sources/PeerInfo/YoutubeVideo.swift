//
//  YoutubeVideo.swift
//  _idx_TelegramUI_Lib_001C0785_ios_min13.0
//
//  Created by Apple on 01/11/22.
//

import Foundation
public struct SlimVideo: Codable {
    let id: String // youtube id
    let blob:String  // youtube payload
}

public struct Thumbnail: Codable {
    let url: String? // youtube id
    let width:Int  // youtube payload
    let height:Int
}
public struct YoutubeVideo: Codable {
    let id: String // youtube id
    let title:String  // youtube payload
    let thumbnails:[Thumbnail?]
    let description:String?
    let duration:String?
    let isLive:Bool?
    let viewCount:Int?
}
