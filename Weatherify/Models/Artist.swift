//
//  Artist.swift
//  Weatherify
//
//  Created by Yili Liu on 3/23/21.
//

import Foundation

struct Artist: Codable {
    let id: String
    let name: String
    let type: String
    let external_urls: [String: String]
}
