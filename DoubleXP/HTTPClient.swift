//
//  HTTPClient.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/1/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//


import Foundation

struct HTTPResponse {
    let data: Data?
    let error: Error?
}

class HTTPClient {

    static let shared = HTTPClient()
    private init() {}

    func get(url: String, completion: @escaping (HTTPResponse) -> Void) {
        guard let url = URL(string: url) else {
            completion(HTTPResponse(data: nil, error: URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(HTTPResponse(data: nil, error: error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(HTTPResponse(data: nil, error: URLError(.badServerResponse)))
                return
            }

            completion(HTTPResponse(data: data, error: nil))
        }.resume()
    }
}
