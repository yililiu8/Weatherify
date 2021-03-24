//
//  UserProfile.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import Foundation

struct UserProfile: Codable{
    var country: String
    var display_name: String
    let email: String
    let explicit_content: [String: Bool]
    let external_urls: [String : String]
//    let followers: [String: Codable?]
    let id:String
    let product: String
    let images: [UserImage]?
    
}

struct UserImage: Codable {
    let url: String
}
