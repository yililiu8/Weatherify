//
//  SpotifyService.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import Foundation

final class SpotifyService {
    static let shared = SpotifyService()
    private init() {}
    static let baseAPIURL = "https://api.spotify.com/v1"
    
    enum HTTPMethod : String{
        case GET
        case POST
    }
    
    enum APIError: Error {
        case failedToGetData
    }
    
    private func createRequest(with url: URL?, type: HTTPMethod, completion: @escaping (URLRequest) -> Void) {
        AuthManager.shared.withValidToken { (token) in
            guard let apiURL = url else {
                return
            }
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
    }
    
    public func searchSongs(key: String, genre: String?, completion: @escaping (SearchResultResponse?, Error?) -> Void) {
        guard let urlKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        guard genre != nil, var urlGenre = genre!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        if genre != nil {
            urlGenre = "%20genre:%22" + urlGenre + "%22"
        } else {
            urlGenre = ""
        }
        createRequest(with: URL(string: SpotifyService.baseAPIURL + "/search?q=\(urlKey)\(urlGenre)&type=track&limit=20"), type: .GET) { (baseRequest) in
            let task = URLSession.shared.dataTask(with: baseRequest) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(nil, APIError.failedToGetData)
                    return
                }

                do {
                    let res = try JSONDecoder().decode(SearchResultResponse.self, from: data)
//                    let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    print(res)
                    print("successful search for tracks")
                    completion(res, nil)
                } catch {
                    print(error)
                    completion(nil, error)
                }
            }
            task.resume()
        }
    }
    
    
    public func searchPlaylists(key: String, completion: @escaping (SearchResultResponse?, Error?) -> Void) {
        guard let urlKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        createRequest(with: URL(string: SpotifyService.baseAPIURL + "/search?q=\(urlKey)&type=playlist&limit=2"), type: .GET) { (baseRequest) in
            let task = URLSession.shared.dataTask(with: baseRequest) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(nil, APIError.failedToGetData)
                    return
                }

                do {
                    let res = try JSONDecoder().decode(SearchResultResponse.self, from: data)
//                    let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    print(res)
                    print("successful search for tracks")
                    completion(res, nil)
                } catch {
                    print(error)
                    completion(nil, error)
                }
            }
            task.resume()
        }
    }

    /* returns tracks given a certain genre */
    public func getRecommendations(genres: Set<String>, completion: @escaping (RecommendationsReponse?, Error?) -> Void) {
        let seeds = genres.joined(separator: ",")
        print("getting recommendations...")
        createRequest(with: URL(string: SpotifyService.baseAPIURL + "/recommendations?seed_genres=\(seeds)&limit=10"), type: .GET) { (baseRequest) in
            let task = URLSession.shared.dataTask(with: baseRequest) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(nil, APIError.failedToGetData)
                    return
                }

                do {
                    let res = try JSONDecoder().decode(RecommendationsReponse.self, from: data)
//                    let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    print(res)
                    completion(res, nil)
                } catch {
                    print(error)
                    completion(nil, error)
                }
            }
            task.resume()
        }
    }
    
    public func getCurrentUserProfile(completion: @escaping (UserProfile?, Error?) -> Void) {
        createRequest(with: URL(string: SpotifyService.baseAPIURL + "/me"), type: .GET) { (baseRequest) in
            let task = URLSession.shared.dataTask(with: baseRequest) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(nil, APIError.failedToGetData)
                    return
                }
                
                do {
                    let res = try JSONDecoder().decode(UserProfile.self, from: data)
                    print(res)
                    print("successful coversion of user profile data")
                    completion(res, nil)
                } catch {
                    completion(nil, error)
                }
            }
            task.resume()
        }
    }
    
}

