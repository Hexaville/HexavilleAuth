//
//  URLSession.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Prorsum
import Foundation

#if os(Linux)
let _urlSessionShared = URLSession(configuration: URLSessionConfiguration(), delegate: nil, delegateQueue: nil)
    extension URLSession {
        static var shared: URLSession {
            return _urlSessionShared
        }
    }
#endif

extension URLSession {
    func resumeSync(with request: URLRequest) throws -> (HTTPURLResponse, Data) {
        let chan = Channel<(Error?, (HTTPURLResponse, Data)?)>.make(capacity: 1)
        
        let task = self.dataTask(with: request) { data, response, error in
            if let error = error {
                try! chan.send((error, nil))
                return
            }
            try! chan.send((nil, (response as! HTTPURLResponse, data!)))
        }
        
        task.resume()
        
        let (err, tupple) = try chan.receive()
        if let error = err {
            throw error
        }
        return (tupple!.0, tupple!.1)
    }
}
