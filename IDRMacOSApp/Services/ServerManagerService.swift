//
//  ServerManagerService.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/7/24.
//


import Foundation
import MultipeerConnectivity

/// Manages the server-side MultipeerConnectivity session.
class ServerManagerService: NSObject, ObservableObject {
    @Published var connectedPeers: [MCPeerID] = []
    private let serviceType = "example-service"
    private let myPeerId = MCPeerID(displayName: Host.current().localizedName ?? "MacServer")
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser

    override init() {
        Logger.shared.log("ServerManager initialized.")
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
    }

    /// Starts advertising to nearby peers.
    func startAdvertising() {
        Logger.shared.log("Server started advertising.")
        advertiser.startAdvertisingPeer()
    }

    /// Stops advertising to nearby peers.
    func stopAdvertising() {
        Logger.shared.log("Server stopped advertising.")
        advertiser.stopAdvertisingPeer()
    }

    /// Disconnects all peers and stops advertising.
    func disconnect() {
        Logger.shared.log("Server disconnecting all peers.")
        session.disconnect()
        stopAdvertising()
    }
}

extension ServerManagerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        var stateValue = "unkown state"

        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
            default:
                break
            }
        }

        Logger.shared.log("Peer \(peerID.displayName) changed state to \(stateValue).")
    }

    // Other required delegate methods
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data if necessary
        Logger.shared.log("Server received data from \(peerID.displayName).")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Logger.shared.log("Server started receiving resource \(resourceName) from \(peerID.displayName).")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Logger.shared.log("Server finished receiving resource \(resourceName) from \(peerID.displayName).")
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        Logger.shared.log("Server received stream \(streamName) from \(peerID.displayName).")
    }
}

extension ServerManagerService: MCNearbyServiceAdvertiserDelegate {
    /// Handles incoming invitations from clients.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, 
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.shared.log("Server received invitation from \(peerID.displayName). Accepting invitation.")
        //TODO:  For now, accept any invitation. Later, we can check against an approved devices list.
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Logger.shared.log("Server failed to start advertising: \(error.localizedDescription)")
    }
}
