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

import XCTest
@testable import Glider
@testable import GliderSwiftLog
import Logging
import GliderTests

final class GliderSwiftLogTests: XCTestCase {
    
    func test_gliderAsSwiftLogBackend() throws {
        // Setup some scope's extra and tags
        GliderSDK.shared.scope.extra = [
            "global_extra": "global"
        ]
        
        GliderSDK.shared.scope.tags = [
            "tags_scope": "val_tag"
        ]
        
        
        // Create glider setup
        let testTransport = TestTransport { event in
            // Validate the filtering.
            XCTAssertNotEqual(event.message, "TRACE message")
            
            // Validate the tags
            if event.level == .debug {
                XCTAssertEqual(event.message, "DEBUG message")
                XCTAssertTrue(event.allExtra?.values["extra_2"] as? String == "v1")
                XCTAssertTrue(event.allExtra?.values["global_extra"] as? String == "global")
            } else {
                XCTAssertEqual(event.message, "ERROR message")
                XCTAssertTrue(event.allExtra?.values["global_extra"] as? String == "local")
            }
            XCTAssertTrue(event.tags?["logger"] as? String == "swiftlog")
        }
        
        let gliderLog = Log {
            $0.level = .debug
            $0.transports = [
                testTransport
            ]
        }
        
        // Setup Glider as backend for swift-log.
        LoggingSystem.bootstrap {
            var handler = GliderSwiftLogHandler(label: $0, logger: gliderLog)
            handler.logLevel = .trace
            return handler
        }
        
        // Create swift-log instance.
        let swiftLog = Logger(label: "com.example.yourapp.swiftlog")
        swiftLog.trace("TRACE message", metadata: ["extra_1" : "v1"])  // Will be ignored.
        swiftLog.debug("DEBUG message", metadata: ["extra_2" : "v1"])  // Will be logged.
        swiftLog.error("ERROR message", metadata: ["global_extra" : "local"])  // Will be logged.
    }
    
}

// MARK: - Private Utilities

fileprivate class TestTransport: Transport {
    typealias OnReceiveEvent = ((Event) -> Void)

    private var onReceiveEvent: OnReceiveEvent?
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    init(onReceiveEvent: @escaping OnReceiveEvent) {
        self.onReceiveEvent = onReceiveEvent
    }
    
    func record(event: Event) -> Bool {
        onReceiveEvent?(event)
        return true
    }
    
    var queue: DispatchQueue? = DispatchQueue(label: "com.test.transport", qos: .background)
    
}