//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

struct VideoWathcList: Codable {
    let id: String
    let title: String
    let description: String
    let startTime: Double
    let thumbnailURL: String
    let videoURL: String
    let type: String
    let videoViews: Int64
}

let KeyForUserDefaults = "watchList"

func saveWatchList(_ videowatchList: [VideoWathcList]) {
    let data = videowatchList.map { try? JSONEncoder().encode($0) }
    UserDefaults.standard.set(data, forKey: KeyForUserDefaults)
}

func fetchWatchList() -> [VideoWathcList] {
    guard let encodedData = UserDefaults.standard.array(forKey: KeyForUserDefaults) as? [Data] else {
        return []
    }

    return encodedData.map { try! JSONDecoder().decode(VideoWathcList.self, from: $0) }
}
