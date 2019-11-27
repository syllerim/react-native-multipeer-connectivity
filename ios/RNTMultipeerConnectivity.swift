//
//  RNTMultipeerConnectivity.swift
//  MultipeerConnectivityLibrary
//
//  Created by Mirellys Arteta Davila on 26/11/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation
import MultipeerConnectivity

@objc(RNTMultipeerConnectivity)
final class RNTMultipeerConnectivity: RCTEventEmitter {
    
    private let MessageServiceType = "example-multipeer-connectivity-ios"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: MessageServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: MessageServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    @objc func send(message: String) {
        NSLog("%@", "sendMessage: \(message) to \(session.connectedPeers.count) peers")
        
        if !session.connectedPeers.isEmpty {
            do {
                try self.session.send(message.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
    }
    
    // MARK: - RCTEventEmitter -
    
    override public static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc(supportedEvents)
    override public func supportedEvents() -> [String] {
        return [
            "session-did-change-peerid",
            "session-did-receive-data",
            "session-did-receive-stream",
            "did-start-receiving-resource",
            "did-finish-receiving-resource"
        ]
    }
    
    @objc(constantsToExport)
    override public func constantsToExport() -> [AnyHashable: Any] {
        return [:]
    }
}

extension RNTMultipeerConnectivity : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}

extension RNTMultipeerConnectivity : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}

extension RNTMultipeerConnectivity : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        self.sendEvent(withName: "session-did-change-peerid", body: ["connectedDevices": session.connectedPeers.map{$0.displayName}])
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        self.sendEvent(withName: "session-did-receive-data", body: ["message": str, "fromPeerId": peerID])
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
        self.sendEvent(withName: "session-did-receive-stream", body: ["stream": stream,
                                                                      "streamName": streamName,
                                                                      "peerID": peerID])
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
        self.sendEvent(withName: "did-start-receiving-resource", body: ["resourceName": resourceName,
                                                                        "peerID": peerID,
                                                                        "progress": progress])
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
        self.sendEvent(withName: "did-finish-receiving-resource", body: ["resourceName": resourceName,
                                                                         "peerID": peerID,
                                                                         "localURL": localURL ?? "", "error": error ?? ""])
    }
}
