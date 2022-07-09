//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation
import Network

// MARK: - NWBrowser.Result

extension NWBrowser.Result {
    
    internal var name: String? {
        switch endpoint {
        case .service(let name, _, _, _):
            return name
        default:
            return nil
        }
    }
    
}

// MARK: - Helpers (Binary Protocol)

// Expects big endian.

extension Data {
    
    init(_ value: UInt32) {
        var contentSize = value.bigEndian
        self.init(bytes: &contentSize, count: MemoryLayout<UInt32>.size)
    }

    func from(_ from: Data.Index, size: Int) -> Data {
        self[(from + startIndex)..<(from + size + startIndex)]
    }
    
}

extension UInt32 {
    
    init(_ data: Data) {
        self = UInt32(data.parseInt(size: 4))
    }
    
}

private extension Data {
    
    func parseInt(size: Int) -> UInt64 {
        precondition(size > 0 && size <= 8)
        var accumulator: UInt64 = 0
        for i in 0..<size {
            let shift = (size - i - 1) * 8
            accumulator |= UInt64(self[self.startIndex + i]) << UInt64(shift)
        }
        return accumulator
    }
    
}

