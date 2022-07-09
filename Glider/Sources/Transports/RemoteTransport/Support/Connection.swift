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

extension RemoteTransport {
    
    public final class Connection {
        
        // MARK: - Private Properties
        
        /// Internal buffer.
        private var buffer = Data()
        
        /// Connection used.
        private let connection: NWConnection
        
        // MARK: - Public Properties
        
        /// Delegate method
        public weak var delegate: RemoteTransportConnectionDelegate?
        
        // MARK: - Initialization

        public convenience init(endpoint: NWEndpoint) {
            self.init(NWConnection(to: endpoint, using: .tcp))
        }

        public init(_ connection: NWConnection) {
            self.connection = connection
        }
        
        // MARK: - Manage Connection
        
        /// Open connection.
        ///
        /// - Parameter queue: queue of the connection.
        public func start(on queue: DispatchQueue) {
            connection.stateUpdateHandler = { [weak self] in
                guard let self = self else { return }
                
                self.delegate?.connection(self, didChangeState: $0)
            }
            
            receive()
            connection.start(queue: queue)
        }
        
        /// Close connection.
        public func cancel() {
            connection.cancel()
        }
        
        // MARK: - Sending Events
        
        /// Send a JSON Encodable packet.
        ///
        /// - Parameters:
        ///   - code: code.
        ///   - entity: entity to encode.
        ///   - completion: completion callback.
        public func send<T: Encodable>(code: UInt8, entity: T, _ completion: ((NWError?) -> Void)? = nil) {
            do {
                let data = try JSONEncoder().encode(entity)
                send(code: code, data: data, completion)
            } catch {
                delegate?.connection(self, failedToEncodingObject: entity, error: error)
            }
        }
        
        @discardableResult
        public func send(packet: RemoteTransportPacket, _ completion: ((NWError?) -> Void)? = nil) -> Bool {
            true
        }
        
        // MARK: - Private Functions
        
        
        private func send(event: Event) {
            delegate?.connection(self, didReceiveEvent: event)
        }

        private func receive() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { [weak self] data, _, isCompleted, error in
                guard let self = self else { return }
                if let data = data, !data.isEmpty {
                    self.process(data: data)
                }
                if isCompleted {
                    self.send(event: .completed)
                } else if let error = error {
                    self.send(event: .error(error))
                } else {
                    self.receive()
                }
            }
        }
        
        private func process(data freshData: Data) {
            guard !freshData.isEmpty else { return }

            var freshData = freshData
            if buffer.isEmpty {
                while let (packet, size) = decodePacket(from: freshData) {
                    send(event: .packet(packet))
                    if size == freshData.count {
                        return // No no processing needed
                    }
                    freshData.removeFirst(size)
                }
            }

            if !freshData.isEmpty {
                buffer.append(freshData)
                while let (packet, size) = decodePacket(from: buffer) {
                    send(event: .packet(packet))
                    buffer.removeFirst(size)
                }
                if buffer.count == 0 {
                    buffer = Data()
                }
            }
        }
        
        private func decodePacket(from data: Data) -> (Packet, Int)? {
            do {
                return try decodePacketData(data)
            } catch {
                if case .notEnoughData? = error as? PacketParsingError {
                    return nil
                }
                
                delegate?.connection(self, failedToProcessingPacket: data, error: error)
                return nil
            }
        }
        
        public func send(code: UInt8, data: Data, _ completion: ((NWError?) -> Void)? = nil) {
            do {
                let data = try encodePacketData(code: code, body: data)
                connection.send(content: data, completion: .contentProcessed({ error in
                    if let error = error {
                        self.delegate?.connection(self, failedToSendData: data, error: error)
                    }
                }))
            } catch {
                delegate?.connection(self, failedToProcessingPacket: data, error: error)
            }
        }
        
        // MARK: - Encoding/Decoding
        
        private func decodePacketData(_ buffer: Data) throws -> (Packet, Int) {
            let header = try PacketHeader(data: buffer)
            guard buffer.count >= header.totalPacketLength else {
                throw PacketParsingError.notEnoughData
            }
            let body = buffer.from(header.contentOffset, size: Int(header.contentSize))
            let packet = Connection.Packet(code: header.code, body: body)
            return (packet, header.totalPacketLength)
        }
        
        private func encodePacketData(code: UInt8, body: Data) throws -> Data {
            guard body.count < UInt32.max else {
                throw PacketParsingError.unsupportedContentSize
            }

            var data = Data()
            data.append(code)
            data.append(Data(UInt32(body.count)))
            data.append(body)
            return data
        }
        
    }
    
}

extension RemoteTransport.Connection {
    
    public enum Event {
        case packet(Packet)
        case error(Error)
        case completed
    }
    
    public struct Packet {
        public let code: UInt8
        public let body: Data
    }
    
    enum PacketParsingError: Error {
        case notEnoughData
        case unsupportedContentSize
    }
    
    /// |code|contentSize|body?|
    struct PacketHeader {
        let code: UInt8
        let contentSize: UInt32

        var totalPacketLength: Int { Int(PacketHeader.size + contentSize) }
        var contentOffset: Int { Int(PacketHeader.size) }

        static let size: UInt32 = 5

        init(code: UInt8, contentSize: UInt32) {
            self.code = code
            self.contentSize = contentSize
        }

        init(data: Data) throws {
            guard data.count >= PacketHeader.size else {
                throw PacketParsingError.notEnoughData
            }
            self.code = data[data.startIndex]
            self.contentSize = UInt32(data.from(1, size: 4))
        }
    }
    
}


extension RemoteTransport {
    
    public enum ConnectionState: CustomStringConvertible {
        case idle
        case connecting
        case connected
        
        public var description: String {
            switch self {
            case .idle: return "idle"
            case .connecting: return "connecting"
            case .connected: return "connected"
            }
        }
    }
    
}
