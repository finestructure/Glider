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

@available(iOS, introduced: 13)
public protocol WebSocketTransportServerDelegate: AnyObject {
    
    // MARK: - Bonjour Advertising Related
    
    /// Called when bonjour advertisting started.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - identifier: identifier of the bonjour service.
    ///   - name: name of the service.
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didStartBonjour identifier: String, name: String)
    
    /// Called when a bonjour advertisting stop or fails to start.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - error: error occurred
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didStopBonjour error: Error?)
    
    
    // MARK: - Transport Related
    
    /// Called when a new peer has connected to the server.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - peer: peer connected.
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didConnectPeer peer: WebSocketPeer)
    
    /// Called when a connected peer disconnect.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - peer: peer
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didDisconnectPeer peer: WebSocketPeer)
    
    // MARK: - Server Related
    
    /// Called when server did disconnect.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - error: if an error occurred this contains the error.
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didDisconnect error: NWError?)
    
    // MARK: - Messages from Peers
    
    /// Called when server receive a command from a connected peer as data..
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - data: data.
    ///   - peer: peer.
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didReceiveData data: Data,
                                  fromPeer peer: WebSocketPeer)
    
    /// Called when server receive a command from a connected peer as string..
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - string: string.
    ///   - peer: peer.
    func webSocketServerTransport(_ transport: WebSocketTransportServer,
                                  didReceiveString string: String,
                                  fromPeer peer: WebSocketPeer)
    
}