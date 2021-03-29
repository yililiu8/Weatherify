//
//  AuthManager.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import Foundation

final class AuthManager {
    
    static let shared = AuthManager()
    
    struct ids {
        static let clientID = Keys.spotifyClientID
        static let clientSecret = Keys.spotifyClientSecret
    }
    static let tokenAPIURL = "https://accounts.spotify.com/api/token"
    static let redirectURI = "https://github.com/yililiu8"
    
    private var refreshingToken = false
    
    private init() {}
    public var signInURL: URL? {
        let scopes = "user-read-private%20user-read-email%20playlist-modify-private%20playlist-read-private%20playlist-modify-public%20user-follow-read%20user-library-modify%20user-library-read"
        let base = "https://accounts.spotify.com/authorize"
        var str = "\(base)?response_type=code&client_id=\(ids.clientID)"
        str += "&scope=\(scopes)&redirect_uri=\(AuthManager.redirectURI)"
        str += "&show_dialog=true"
        return URL(string: str)
    }
    
    var isSignedIn: Bool {
        return accessToken != nil
    }
    
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    private var shouldRefreshToken: Bool {
        guard let exp = tokenExpirationDate else {
            return false
        }
        let curr = Date()
        return curr.addingTimeInterval(TimeInterval(300)) >= exp
    }
    
    public func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)) , forKey: "expirationDate")
    }
    
    private var onRefreshBlocks = [((String) -> Void)]()
    
    public func withValidToken(completion: @escaping ((String) -> Void)) {
        guard !refreshingToken else {
            onRefreshBlocks.append(completion)
            return
        }
        if shouldRefreshToken {
            refreshAccessToken { [weak self] (success) in
                if success {
                    if let token = self?.accessToken {
                        completion(token)
                    }
                } else {
                    print("no success in refreshing access token")
                }
            }
        } else if let token = accessToken{
            completion(token)
        }
        
    }
    
    public func refreshAccessToken(completion: @escaping ((Bool) -> Void)) {
        guard !refreshingToken else {
            print("no need to refresh token")
            return
        }
        guard shouldRefreshToken else {
            completion(true)
            return
        }
        guard let refreshToken = self.refreshToken else {
            print("no refresh token")
            return
        }
        //MARK: refresh token
        guard let url = URL(string: AuthManager.tokenAPIURL) else {
            print("invalid url for refresh token")
            return
        }
        refreshingToken = true
        
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token"), URLQueryItem(name: "refresh_token", value: refreshToken)]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded ", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        let basicToken = ids.clientID + ":" + ids.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64Str = data?.base64EncodedString() else {
            print("error with conversion to base 64 string")
            completion(false)
            return
        }
        request.setValue("Basic \(base64Str)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("unable to refresh access token / get data")
                completion(false)
                return
            }
            do {
                let res = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.onRefreshBlocks.forEach { $0(res.access_token) }
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: res)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print("successfully refreshed cached token: \(json)")
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
            
        }
        task.resume()
    }
    
    public func convertCodeToToken(code: String, completion: @escaping ((Bool) -> Void)) {
        guard let url = URL(string: AuthManager.tokenAPIURL) else {
            return
        }
        
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "grant_type", value: "authorization_code"), URLQueryItem(name: "code", value: code), URLQueryItem(name: "redirect_uri", value: AuthManager.redirectURI)]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded ", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        let basicToken = ids.clientID + ":" + ids.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64Str = data?.base64EncodedString() else {
            print("error with conversion to base 64 string")
            completion(false)
            return
        }
        request.setValue("Basic \(base64Str)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            do {
                let res = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.cacheToken(result: res)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print("success: \(json)")
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
            
        }
        task.resume()
    }
    
    public func signOut(completion: (Bool) -> Void) {
        UserDefaults.standard.setValue(nil, forKey: "access_token")
        UserDefaults.standard.setValue(nil, forKey: "refresh_token")
        UserDefaults.standard.setValue(nil, forKey: "expirationDate")
        completion(true)
    }
}
