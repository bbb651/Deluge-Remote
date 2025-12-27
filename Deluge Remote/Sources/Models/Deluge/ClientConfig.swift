//
//  ClientConfig.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/25/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

struct ClientConfig: Codable, Comparable {
   
    let nickname: String
    let hostname: String
    let relativePath: String
    let port: Int
    let password: String
    let isHTTP: Bool
    let url: URL
    let uploadURL: URL
    let customHeaders: [String: String]
    
    static func < (lhs: ClientConfig, rhs: ClientConfig) -> Bool {
        return lhs.nickname == rhs.nickname && lhs.hostname == rhs.hostname && lhs.relativePath == rhs.relativePath
        && lhs.port == rhs.port && lhs.password == rhs.password && lhs.isHTTP == rhs.isHTTP
    }
    
    // Custom decoding to handle backward compatibility when customHeaders is not present
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decode(String.self, forKey: .nickname)
        hostname = try container.decode(String.self, forKey: .hostname)
        relativePath = try container.decode(String.self, forKey: .relativePath)
        port = try container.decode(Int.self, forKey: .port)
        password = try container.decode(String.self, forKey: .password)
        isHTTP = try container.decode(Bool.self, forKey: .isHTTP)
        url = try container.decode(URL.self, forKey: .url)
        uploadURL = try container.decode(URL.self, forKey: .uploadURL)
        // Use empty dictionary if customHeaders is not present (backward compatibility)
        customHeaders = try container.decodeIfPresent([String: String].self, forKey: .customHeaders) ?? [:]
    }
    
    init?(nickname: String, hostname: String, relativePath: String, port: Int, password: String, isHTTP: Bool, customHeaders: [String: String] = [:]) {
        
        self.nickname = nickname
        self.hostname = hostname
        self.relativePath = relativePath
        self.port = port
        self.password = password
        self.isHTTP = isHTTP
        self.customHeaders = customHeaders
        
        let sslConfig: NetworkSecurity = isHTTP ? .http : .https
        
        var urlBuilder = URLComponents()
        urlBuilder.scheme = sslConfig.rawValue
        urlBuilder.host = hostname
        urlBuilder.port = port
        
        guard var baseURL = try? urlBuilder.asURL() else { return nil }
        baseURL.appendPathComponent(relativePath)
        
        self.uploadURL = baseURL.appendingPathComponent("upload")
        self.url = baseURL.appendingPathComponent("json")
        
        print(url.absoluteString)
        
        print( "\(sslConfig.rawValue)\(hostname):\(port)\(relativePath)/json")
    }

}
