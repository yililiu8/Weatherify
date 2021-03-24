//
//  SearchResult.swift
//  Weatherify
//
//  Created by Yili Liu on 3/23/21.
//

import Foundation

struct SearchResultResponse: Codable {
    let tracks: SearchTracksResponse?
    let playlists: SearchPlaylistsResponse?
}

struct SearchTracksResponse: Codable {
    let items: [AudioTrack]?
}

struct SearchPlaylistsResponse: Codable {
    let items: [Playlist]?
}
