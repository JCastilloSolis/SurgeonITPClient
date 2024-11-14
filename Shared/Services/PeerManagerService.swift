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


    private let serviceType = "example-service"
    private var peerID: MCPeerID
    private var mcSession: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var isSendingHeartbeat = false
    private var heartbeatTimer: Timer?
    private var selectedServerPeerID: MCPeerID?
    private var savedClientPeerID: MCPeerID?

    //TODO: Refactor this to take in a server or client role
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


        //TODO: Create load data method based on the target
        // iOS should save/load the latest saved server
        // macOS should save/load the latest saved client

        // Load saved client peerID from UserDefaults
        if let savedClientName = UserDefaults.standard.string(forKey: "savedClientName") {
            Logger.shared.log("Found saved client peerID: \(savedClientName)")
            self.savedClientPeerID = MCPeerID(displayName: savedClientName)
        }

        // Determine the role based on the current platform
        setupRoleBasedServices()

        Logger.shared.log("PeerManager initialized with PeerID: \(peerID.displayName)")
    }

    private func setupRoleBasedServices() {
#if os(iOS)
        Logger.shared.log("Setting up as Browser (Client)")
        setupBrowser()
#elseif os(macOS)
        Logger.shared.log("Setting up as Advertiser (Server)")
        setupAdvertiser()
#endif
    }

    private func setupAdvertiser() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        startAdvertising()
    }

    private func setupBrowser() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
    }

    func startAdvertising() {
        guard let advertiser = advertiser else {
            Logger.shared.log("Cannot start advertising: Advertiser is nil")
            return
        }
        advertiser.startAdvertisingPeer()
        Logger.shared.log("Started advertising...")
    }

    func stopAdvertising() {
        guard let advertiser = advertiser else {
            Logger.shared.log("Cannot stop advertising: Advertiser is nil")
            return
        }
        advertiser.stopAdvertisingPeer()
        Logger.shared.log("Stopped advertising...")
    }

    func startBrowsing() {
        guard let browser = browser else {
            Logger.shared.log("Cannot start browsing: Browser is nil")
            return
        }
        browser.startBrowsingForPeers()
        Logger.shared.log("Started browsing for peers...")
    }

    func stopBrowsing() {
        guard let browser = browser else {
            Logger.shared.log("Cannot stop browsing: Browser is nil")
            return
        }
        browser.stopBrowsingForPeers()
        Logger.shared.log("Stopped browsing for peers...")
    }

    func selectPeerForConnection(peerID: MCPeerID) {
        selectedServerPeerID = peerID
        UserDefaults.standard.set(peerID.displayName, forKey: "savedServerName")
        connectToPeer(peerID: peerID)
    }

    private func connectToPeer(peerID: MCPeerID) {
        guard let browser = browser else {
            Logger.shared.log("Cannot connect to peer: Browser is nil")
            return
        }
        Logger.shared.log("Inviting \(peerID.displayName) to join the session")
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
    }

    func send(_ message: String, type: MessageType) {
        let fullMessage = "\(type.prefix)\(message)"
        //log("Attempting to send message: \(fullMessage)")
        guard let data = fullMessage.data(using: .utf8) else {
            Logger.shared.log("Failed to encode message to data")
            return
        }
        do {
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
            Logger.shared.log("Sent \(type.rawValue): \(message)")
        } catch {
            Logger.shared.log("Error sending \(type.rawValue): \(error.localizedDescription)")
        }
    }

    func sendHeartbeat() {
        guard isSendingHeartbeat else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        let message = "Heartbeat \(messageCounter): \(timeString)"
        DispatchQueue.main.async {
            self.messageCounter += 1
        }
        send(message, type: .heartbeat)
    }

    func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
        RunLoop.main.add(heartbeatTimer!, forMode: .common)
    }

    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    func leaveSession() {
        Logger.shared.log("Leaving session")
        //stopHeartbeat()
        mcSession.disconnect()
#if os(macOS)
        startAdvertising()  // Resume advertising if the session is left
#endif
    }

    func forgetClient() {
        Logger.shared.log("Forgetting client")
        UserDefaults.standard.removeObject(forKey: "savedClientName")
        savedClientPeerID = nil
    }


    private func processCommand(_ command: String) {
        Logger.shared.log("Processing command: \(command)")
        DispatchQueue.main.async {
            switch command {
                case "start":
                    self.isSendingHeartbeat = true
                    self.startHeartbeat()
                case "stop":
                    self.isSendingHeartbeat = false
                    self.stopHeartbeat()
                case "status":
                    let status = self.isSendingHeartbeat ? "Sending heartbeats" : "Idle"
                    self.send("Server status: \(status)", type: .response)
                default:
                    self.send("Unrecognized command: \(command)", type: .response)
            }
        }
    }


    // MARK: - MCSessionDelegate Methods
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.sessionState = state
            switch state {
                case .connected:
                    self.handleConnectedState(peerID: peerID)
                case .notConnected:
                    self.handleNotConnectedState(peerID: peerID)
                case .connecting:
                    Logger.shared.log("Connecting to \(peerID.displayName)")
                @unknown default:
                    Logger.shared.log("Unknown state for peer \(peerID.displayName)")
            }
        }
    }

    private func handleConnectedState(peerID: MCPeerID) {
        Logger.shared.log("Connected to \(peerID.displayName)")
        if !connectedDevices.contains(peerID.displayName) {
            connectedDevices.append(peerID.displayName)
        }

        // Stop browsing once connected
        stopBrowsing()

#if os(macOS)
        if savedClientPeerID == nil {
            savedClientPeerID = peerID
            UserDefaults.standard.set(peerID.displayName, forKey: "savedClientName")
            Logger.shared.log("Saved client: \(peerID.displayName)")
        }
        stopAdvertising()  // Stop advertising when connected
#endif
    }

    private func handleNotConnectedState(peerID: MCPeerID) {
        Logger.shared.log("Disconnected from \(peerID.displayName)")
        //stopHeartbeat()
        connectedDevices.removeAll { $0 == peerID.displayName }
        mcSession.disconnect()
#if os(macOS)
        startAdvertising()  // Resume advertising when disconnected
#endif
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else {
            Logger.shared.log("Failed to decode message from \(peerID.displayName)")
            return
        }
        guard let messageType = MessageType.determineType(from: message) else {
            Logger.shared.log("Unrecognized message type from \(peerID.displayName): \(message)")
            return
        }
        let cleanMessage = String(message.dropFirst(messageType.prefix.count))
        Logger.shared.log("Received \(messageType.rawValue) from \(peerID.displayName): \(cleanMessage)")
        DispatchQueue.main.async {
            switch messageType {
                case .command:
                    self.receivedMessages.append(cleanMessage)
                    self.processCommand(cleanMessage)
                case .response, .heartbeat:
                    self.receivedMessages.append(cleanMessage)
                default:
                    Logger.shared.log("Received unknown message type")
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        Logger.shared.log("Received stream: \(streamName) from \(peerID.displayName)")
        // Handle received stream
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Logger.shared.log("Started receiving resource: \(resourceName) from \(peerID.displayName)")
        // Handle resource reception
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Logger.shared.log("Finished receiving resource: \(resourceName) from \(peerID.displayName), error: \(String(describing: error))")
        // Handle completed reception
    }

    // MARK: - MCNearbyServiceBrowserDelegate Methods
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                Logger.shared.log("Found peer: \(peerID.displayName)")
                self.discoveredPeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Logger.shared.log("Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
            Logger.shared.log("Removed peer: \(peerID.displayName)")
        }
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate Methods

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        Logger.shared.log("Received invitation from \(peerID.displayName). ConnectedPeers = \(mcSession.connectedPeers.count)")
        // Automatically accept the invitation only if not already connected
        guard mcSession.connectedPeers.isEmpty else {
            Logger.shared.log("Rejected invitation from \(peerID.displayName) because already connected to another peer")
            invitationHandler(false, nil)
            return
        }

        if let savedClientPeerID = savedClientPeerID {
            if peerID.displayName == savedClientPeerID.displayName {
                invitationHandler(true, mcSession)
                Logger.shared.log("Accepted invitation from \(peerID.displayName)")
            } else {
                Logger.shared.log("Rejected invitation from \(peerID.displayName) because it's not the saved client")
                invitationHandler(false, nil)
            }
        } else {
            invitationHandler(true, mcSession)
            Logger.shared.log("Accepted invitation from \(peerID.displayName)")
        }
    }
}
