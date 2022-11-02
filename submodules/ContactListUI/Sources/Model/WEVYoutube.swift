//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import HandyJSON
import UIKit


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
    let viewCount:Int64?
}
