//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

// MARK: - Crew
struct WevUser: Codable {
    let userId: Int64
    let firstname: String?
    let lastname: String?
    let username: String?
    let phone: String?
    let referralcode: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstname = "first_name"
        case lastname = "last_name"
        case username = "username"
        case phone = "phone"
        case referralcode = "referral_code"
    }
}
// MARK: - Crew
struct Points: Codable {
    let id: Int64
    let userId: Int64?
    let pointType: Int?
    let points: Int64?
    let friendUserId: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pointType = "point_type"
        case points = "points"
        case friendUserId = "friend_user_id"
    }
}

struct PointsInsert: Codable {
    let userId: Int64?
    let pointType: Int?
    let points: Int64?
    let friendUserId: Int64?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case pointType = "point_type"
        case points = "points"
        case friendUserId = "friend_user_id"
    }
}

struct PointsType: Codable {
    let id: Int64
    let type: Int
    let message: String
    let points: Int64
    let isdeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case message
        case points
        case isdeleted = "is_deleted"
    }
}
struct UserPoints: Codable {
    let points: Int64?

    enum CodingKeys: String, CodingKey {
        case points = "sum"
    }
}
