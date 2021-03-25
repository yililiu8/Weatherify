//
//  Constants.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import Foundation

//MARK: global variables
class Constants {
    static let shared = Constants()
    
    static var user: UserProfile?
    static var playlists: [Playlist]?
    static var playlistProgress: Float = 0.0
}
