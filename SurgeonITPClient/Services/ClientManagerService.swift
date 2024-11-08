//
//  ClientManagerService.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/7/24.
//


import Foundation
import MultipeerConnectivity


/// Manages the client-side MultipeerConnectivity session.
class ClientManagerService: NSObject, ObservableObject {
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []

    private let serviceType = "example-service"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession
    private var browser: MCNearbyServiceBrowser
    private var isBrowsing = false

    override init() {
        Logger.shared.log("ClientManager initialized.")
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        super.init()
        session.delegate = self
        browser.delegate = self
    }

    /// Starts browsing for nearby servers.
    func startBrowsing() {
        guard !isBrowsing else { return }
        Logger.shared.log("Client started browsing for peers.")
        browser.startBrowsingForPeers()
        isBrowsing = true
    }

    /// Stops browsing for nearby servers.
    func stopBrowsing() {
        guard isBrowsing else { return }
        Logger.shared.log("Client stopped browsing for peers.")
        browser.stopBrowsingForPeers()
        isBrowsing = false
        disconnect()
    }

    /// Disconnects from all peers.
    func disconnect() {
        Logger.shared.log("Client disconnecting from all peers.")
        session.disconnect()
    }

    /// Sends an invitation to connect to the selected peer.
    func invitePeer(_ peerID: MCPeerID) {
        Logger.shared.log("Client inviting peer \(peerID.displayName).")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
}

extension ClientManagerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Logger.shared.log("Client peer \(peerID.displayName) changed state to \(state.description).")
        DispatchQueue.main.async {
            switch state {
                case .connected:
                    if !self.connectedPeers.contains(peerID) {
                        self.connectedPeers.append(peerID)
                        // Optionally remove from discoveredPeers since it's now connected
                        self.discoveredPeers.removeAll { $0 == peerID }
                    }
                case .notConnected:
                    self.connectedPeers.removeAll { $0 == peerID }
                default:
                    break
            }
        }
    }

    // Required delegate methods
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data if necessary
        Logger.shared.log("Client received data from \(peerID.displayName).")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Logger.shared.log("Client started receiving resource \(resourceName) from \(peerID.displayName).")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Logger.shared.log("Client finished receiving resource \(resourceName) from \(peerID.displayName).")
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        Logger.shared.log("Client received stream \(streamName) from \(peerID.displayName).")
    }
}

extension ClientManagerService: MCNearbyServiceBrowserDelegate {
    /// Handles discovery of nearby servers.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Logger.shared.log("Client found peer \(peerID.displayName).")
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) && !self.connectedPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
        // No automatic invitation; user will select peer to connect.
    }

    /// Handles loss of peers.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Logger.shared.log("Client lost peer \(peerID.displayName).")
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Logger.shared.log("Client failed to start browsing: \(error.localizedDescription)")
    }
}

extension MCSessionState {
    var description: String {
        switch self {
            case .notConnected:
                return "Not Connected"
            case .connecting:
                return "Connecting"
            case .connected:
                return "Connected"
            @unknown default:
                return "Unknown State"
        }
    }
}
