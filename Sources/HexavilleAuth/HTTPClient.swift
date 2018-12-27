//
//  HTTPClient.swift
//  CNIOAtomics
//
//  Created by Yuki Takei on 2018/12/12.
//

import Foundation
import Dispatch

struct HTTPClient {
    func send(request: URLRequest) throws -> (HTTPURLResponse, Data) {
        var _error: Error?
        var _data: Data?
        var _response: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error  in
            _error = error
            _data = data
            _response = response as? HTTPURLResponse
            semaphore.signal()
        }
        
        task.resume()
        
        semaphore.wait()
        
        if let error = _error {
            throw error
        }
        
        return (_response!, _data ?? Data())
    }
    
    func send(url: URL) throws -> (HTTPURLResponse, Data) {
        return try self.send(request: URLRequest(url: url))
    }
}


