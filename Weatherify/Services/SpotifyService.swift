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

