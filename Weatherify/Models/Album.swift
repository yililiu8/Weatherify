//
//  Albums.swift
//  Weatherify
//
//  Created by Yili Liu on 3/23/21.
//

import Foundation

struct APIImage: Codable {
    let height: Int?
    let url: String
    let width: Int?
}

struct Album: Codable {
    let album_type: String?
    let available_markets: [String]?
    let id: String
    let images: [APIImage]?
    let name: String
    let release_date: String?
    let total_tracks: Int?
    let artists: [Artist]
}


