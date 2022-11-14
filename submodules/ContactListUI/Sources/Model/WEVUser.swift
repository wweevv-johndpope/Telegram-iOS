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
/**
 * Generate a random referral code
 */
class referalCode {
  static let digits = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9"
  ];
  
  static let letters = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
  ];

    static func generateRefferalCode() -> String {
        var code = ""
        for _ in 0..<4 {
            code += letters.randomElement() ?? ""
        }
        for _ in 0..<1 {
            code += digits.randomElement() ?? ""
        }
        return code
    }

}
