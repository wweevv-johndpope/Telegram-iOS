//
//  WEVSubscribeActivity.swift
//  _idx_ContactListUI_AE77A1D0_ios_min13.0
//
//  Created by Apple on 11/11/22.
//

import Foundation
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let projectRegionCrews = try? newJSONDecoder().decode(ProjectRegionCrews.self, from: jsonData)

import Foundation

// MARK: - ProjectRegionCrews
struct WEVSubscribeActivity: Codable {
    let kind, etag: String
    let items: [Item]
    let nextPageToken: String
    let pageInfo: PageInfo
}

// MARK: - Item
struct Item: Codable {
    let kind, etag, id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
}

// MARK: - ContentDetails
struct ContentDetails: Codable {
    let upload: Upload
}

// MARK: - Upload
struct Upload: Codable {
    let videoID: String

    enum CodingKeys: String, CodingKey {
        case videoID = "videoId"
    }
}

// MARK: - Snippet
struct Snippet: Codable {
    let publishedAt: Date
    let channelID, title, snippetDescription: String
    let thumbnails: Thumbnails
    let type: String

    enum CodingKeys: String, CodingKey {
        case publishedAt
        case channelID = "channelId"
        case title
        case snippetDescription = "description"
        case thumbnails, type
    }
}

// MARK: - Thumbnails
struct Thumbnails: Codable {
    let thumbnailsDefault, medium, high, standard: Default
    let maxres: Default

    enum CodingKeys: String, CodingKey {
        case thumbnailsDefault = "default"
        case medium, high, standard, maxres
    }
}

// MARK: - Default
struct Default: Codable {
    let url: String
    let width, height: Int
}

// MARK: - PageInfo
struct PageInfo: Codable {
    let totalResults, resultsPerPage: Int
}
