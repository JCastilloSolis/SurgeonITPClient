//
//  PeerManagerService.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//
// PeerManager.swift

import Foundation
import MultipeerConnectivity



//TODO: Figure out scenarios for when 2 client devices are paired to the same server, how to show on the client side that the server needs to be cleared if they want to connect.
//: Space out the invites to be every 5 seconds, and only try for 30 seconds until the user press the retry button
class PeerManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {

    @Published var connectedDevices = [String]()
    @Published var discoveredPeers = [MCPeerID]()
    @Published var receivedMessages: [String] = []
    @Published var messageCounter = 0
    @Published var sessionState: MCSessionState = .notConnected


    private var peerID: MCPeerID
    private var mcSession: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var isSendingHeartbeat = false
    private var heartbeatTimer: Timer?
    private var selectedServerPeerID: MCPeerID?
    private var savedClientPeerID: MCPeerID?

    func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] \(message)")
    }

    override init() {
        // Define the displayName for peerID based on platform
        let displayName: String = {
#if os(iOS)
            return UIDevice.current.name
#elseif os(macOS)
            return Host.current().localizedName ?? "Mac"
#endif
        }()

        // Set the peerID with the device name
        self.peerID = MCPeerID(displayName: displayName)
        self.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.mcSession.delegate = self

        log("PeerManager initialized with PeerID: \(peerID.displayName)")

        // Load saved client peerID from UserDefaults
        if let savedClientName = UserDefaults.standard.string(forKey: "savedClientName") {
            self.savedClientPeerID = MCPeerID(displayName: savedClientName)
        }

        // Determine the role based on the current platform
#if os(iOS)
        log("Setting up as Browser (Client)")
        setupBrowser()
#elseif os(macOS)
        log("Setting up as Advertiser (Server)")
        setupAdvertiser()
#endif
    }

    private func setupAdvertiser() {
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "example-service")
        self.advertiser?.delegate = self
        startAdvertising()
    }

    private func setupBrowser() {
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "example-service")
        self.browser?.delegate = self
        startBrowsing()
    }

    private func startAdvertising() {
        advertiser?.startAdvertisingPeer()
        log("Started advertising...")
    }

    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        log("Stopped advertising...")
    }

    private func startBrowsing() {
        browser?.startBrowsingForPeers()
        log("Started browsing for peers...")
    }

    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        log("Stopped browsing for peers...")
    }

    func selectPeerForConnection(peerID: MCPeerID) {
        selectedServerPeerID = peerID
        UserDefaults.standard.set(peerID.displayName, forKey: "savedServerName")
        connectToPeer(peerID: peerID)
    }

    private func connectToPeer(peerID: MCPeerID) {
        log("Invited \(peerID.displayName) to join the session")
        browser?.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
    }

    func send(_ message: String, type: MessageType) {
        let fullMessage = "\(type.prefix)\(message)"
        log("Will attempt to send message \(fullMessage)")
        guard let data = fullMessage.data(using: .utf8) else {
            log("Failed to send message")
            return
        }
        do {
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
            log("Sending \(type): \(message)")
        } catch {
            log("Error sending \(type): \(error.localizedDescription)")
        }
    }

    func sendHeartbeat() {
        guard isSendingHeartbeat else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        let message = "Heartbeat \(messageCounter): \(timeString)"
        messageCounter += 1
        send(message, type: .heartbeat)
    }

    func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }

    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    func leaveSession() {
        log("Leave Session")
        stopHeartbeat()
        mcSession.disconnect()
#if os(macOS)
        startAdvertising()  // Resume advertising if the session is left
#endif
    }

    func forgetClient() {
        log("Forget Client")
        UserDefaults.standard.removeObject(forKey: "savedClientName")
        savedClientPeerID = nil
    }


    private func processCommand(_ command: String) {
        switch command {
            case "start":
                isSendingHeartbeat = true
                startHeartbeat()
            case "stop":
                isSendingHeartbeat = false
                stopHeartbeat()
            case "status":
                let status = isSendingHeartbeat ? "Sending heartbeats" : "Idle"
                send("Server status: \(status)", type: .response)
            default:
                send("Unrecognized command: \(command)", type: .response)
        }
    }


    // MARK: - MCSessionDelegate Methods
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.sessionState = state
            if state == .connected {
                self.log("Connected to \(peerID.displayName)")
                if !self.connectedDevices.contains(peerID.displayName) {
                    self.connectedDevices.append(peerID.displayName)
                }

#if os(macOS)
                if self.savedClientPeerID == nil {
                    self.savedClientPeerID = peerID
                    UserDefaults.standard.set(peerID.displayName, forKey: "savedClientName")
                    self.log("Saved client: \(peerID.displayName)")
                }
                self.stopAdvertising()  // Stop advertising when connected
#endif
            } else if state == .notConnected {
                self.log("Disconnected from \(peerID.displayName), stopping heartbeat.")
                self.stopHeartbeat()
                self.connectedDevices.removeAll { $0 == peerID.displayName }
                session.disconnect()
#if os(macOS)
                self.startAdvertising()  // Resume advertising when disconnected
#endif
            } else if state == .connecting {
                self.log("Connecting to \(peerID.displayName)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else { return }
        if let messageType = MessageType.determineType(from: message) {
            let cleanMessage = String(message.dropFirst(messageType.prefix.count))
            log("Clean message \(cleanMessage), prefix \(messageType.rawValue)")
            DispatchQueue.main.async {
                switch messageType {
                    case .command:
                        self.log("A command was received for macOS")
                        self.receivedMessages.append(cleanMessage)
                        self.processCommand(cleanMessage)
                        // Responses and heartbeats not processed as commands
                    case .response:
                        self.log("A response was received for iOS")
                        self.receivedMessages.append(cleanMessage)
                    case .heartbeat:
                        self.log("A heartbeat status was received for iOS")
                        self.receivedMessages.append(cleanMessage)
                }
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log("Received stream: \(streamName) from \(peerID.displayName)")
        // Handle received stream
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log("Started receiving resource: \(resourceName) from \(peerID.displayName)")
        // Handle resource reception
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log("Finished receiving resource: \(resourceName) from \(peerID.displayName), error: \(String(describing: error))")
        // Handle completed reception
    }

    // MARK: - MCNearbyServiceBrowserDelegate Methods
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {

        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.log("Found peer: \(peerID.displayName)")
                self.discoveredPeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log("Lost peer: \(peerID.displayName)")
        // Handle lost peer
        DispatchQueue.main.async {
            if self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.removeAll(where: { peer in
                    peer.displayName == peerID.displayName
                })
                self.log("Remove peer: \(peerID.displayName)")
            }
        }
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate Methods
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        log("Received invitation from \(peerID.displayName). ConnectedPeers = \(mcSession.connectedPeers.count)")
        // Automatically accept the invitation only if not already connected
        if mcSession.connectedPeers.count == 0 {
            if let savedClientPeerID = self.savedClientPeerID {
                if peerID.displayName == savedClientPeerID.displayName {
                    invitationHandler(true, mcSession)
                    log("Accepted invitation from \(peerID.displayName)")
                } else {
                    log("Rejected invitation from \(peerID.displayName) because it's not the saved client")
                    invitationHandler(false, nil)
                }
            } else {
                invitationHandler(true, mcSession)
                log("Accepted invitation from \(peerID.displayName)")
            }
        } else {
            log("Rejected invitation from \(peerID.displayName) because already connected to another peer")
            invitationHandler(false, nil)
        }
    }
}
