//
//  PeerManager.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//
// PeerManager.swift

import Foundation
import MultipeerConnectivity
import Combine



//TODO: Figure out scenarios for when 2 client devices are paired to the same server, how to show on the client side that the server needs to be cleared if they want to connect.
//: Space out the invites to be every 5 seconds, and only try for 30 seconds until the user press the retry button
class PeerManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {

    // MARK: Published properties
    @Published var connectedDevices = [String]()
    @Published var discoveredPeers = [MCPeerID]()
    @Published var messageCounter = 0
    @Published var sessionState: MCSessionState = .notConnected

    // MARK: - Publishers
    let startZoomCallPublisher = PassthroughSubject<MCPeerID, Never>()
    let endZoomCallPublisher = PassthroughSubject<MCPeerID, Never>()
    let zoomSessionStartedPublisher = PassthroughSubject<String, Never>() // Emits sessionName


    // MARK: Private vars
    private let serviceType = Constants.mpcServiceType
    private var peerID: MCPeerID
    private var mcSession: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var selectedServerPeerID: MCPeerID?
    private var savedClientPeerID: MCPeerID?

    // Reconnection Logic
    private var reconnectionPeersQueue: [MCPeerID] = []
    private var isReconnecting: Bool = false
    private var currentAttemptPeerID: MCPeerID?


    // Heartbeat logic
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 60 // 1 minute
    private var isSendingHeartbeat = false

    // MARK: - Initialization

    //TODO: Refactor this to take in a server or client role
    override init() {
        // Define the displayName for peerID based on platform
        let displayName: String = {
#if os(iOS)
            return "Dr. Castillo"
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

    // MARK: - Setup Methods

    /// Sets up the role-based services (Advertiser for macOS, Browser for iOS).
    private func setupRoleBasedServices() {
#if os(iOS)
        Logger.shared.log("Setting up as Browser (Client)")
        setupBrowser()
#elseif os(macOS)
        Logger.shared.log("Setting up as Advertiser (Server)")
        setupAdvertiser()
        startHeartbeat()
#endif
    }

    /// Configures and starts advertising peers (macOS server).
    private func setupAdvertiser() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        startAdvertising()
    }

    /// Configures and starts browsing for peers (iOS client).
    private func setupBrowser() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
    }

    /// Start sending heartbeats
    func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }

    /// Stop sending heartbeats
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    // MARK: - Advertising Methods (macOS Server)

    /// Starts advertising the peer to nearby devices.
    func startAdvertising() {
        guard let advertiser = advertiser else {
            Logger.shared.log("Cannot start advertising: Advertiser is nil")
            return
        }
        advertiser.startAdvertisingPeer()
        Logger.shared.log("Started advertising...")
    }

    /// Stops advertising the peer.
    func stopAdvertising() {
        guard let advertiser = advertiser else {
            Logger.shared.log("Cannot stop advertising: Advertiser is nil")
            return
        }
        advertiser.stopAdvertisingPeer()
        Logger.shared.log("Stopped advertising...")
    }

    // MARK: - Browsing Methods (iOS Client)

    /// Starts browsing for nearby peers.
    func startBrowsing() {
        guard let browser = browser else {
            Logger.shared.log("Cannot start browsing: Browser is nil")
            return
        }
        browser.startBrowsingForPeers()
        Logger.shared.log("Started browsing for peers...")
    }

    /// Stops browsing for nearby peers.
    func stopBrowsing() {
        guard let browser = browser else {
            Logger.shared.log("Cannot stop browsing: Browser is nil")
            return
        }
        browser.stopBrowsingForPeers()
        Logger.shared.log("Stopped browsing for peers...")
    }

    // MARK: - Connection Methods

    /// Selects a peer for connection and initiates the invitation. Stores the peerID
    /// - Parameter peerID: The `MCPeerID` of the peer to connect to.
    func selectPeerForConnection(peerID: MCPeerID) {
        selectedServerPeerID = peerID
        UserDefaults.standard.set(peerID.displayName, forKey: "savedServerName")
        connectToPeer(peerID: peerID)
    }

    /// Invites a specific peer to join the session.
    /// - Parameter peerID: The `MCPeerID` of the peer to invite.
    private func connectToPeer(peerID: MCPeerID) {
        guard let browser = browser else {
            Logger.shared.log("Cannot connect to peer: Browser is nil")
            return
        }
        Logger.shared.log("Inviting \(peerID.displayName) to join the session")
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
    }

    // MARK: - Reconnection Logic

    /// Attempts to reconnect to the saved server by trying all discovered peers with the saved display name.
    func attemptReconnection() {
        //TODO: Investigare reconnection issues
        Logger.shared.log("Attempting reconnection")

        guard let savedServerName = UserDefaults.standard.string(forKey: "savedServerName") else {
            Logger.shared.log("No saved server name found for reconnection.")
            return
        }

        // Gather all peers with the saved displayName
        let peersToAttempt = discoveredPeers.filter { $0.displayName == savedServerName }

        if peersToAttempt.isEmpty {
            Logger.shared.log("No peers with displayName \(savedServerName) found for reconnection.")
            return
        }

        // Initialize the reconnection queue
        reconnectionPeersQueue = peersToAttempt
        isReconnecting = true

        Logger.shared.log("Will attempt to reconnect to \(peersToAttempt.count) peers with name \(savedServerName).")

        // Start attempting to connect to the first peer
        attemptNextPeerInQueue()
    }

    /// Attempts to connect to the next peer in the reconnection queue.
    private func attemptNextPeerInQueue() {
        guard isReconnecting, let nextPeer = reconnectionPeersQueue.first else {
            Logger.shared.log("Reconnection attempts completed.")
            isReconnecting = false
            return
        }

        Logger.shared.log("Trying to connect to \(nextPeer.displayName)")
        //previouslyPaired = true
        selectPeerForConnection(peerID: nextPeer)
        currentAttemptPeerID = nextPeer
    }

    //MARK: - Session management
    /// Disconnects device from the current `MCSession` . On macOS it will start advertising
    func leaveSession() {
        Logger.shared.log("Leaving session")
        mcSession.disconnect()
#if os(macOS)
        startAdvertising()  // Resume advertising if the session is left
#elseif os(iOS)
        startBrowsing()
#endif
    }

    /// Deletes the stored value for the client device
    func forgetClient() {
        Logger.shared.log("Forgetting client")
        UserDefaults.standard.removeObject(forKey: "savedClientName")
        savedClientPeerID = nil
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

    /// Handles the connected state for a peer.
    /// - Parameter peerID: The `MCPeerID` of the connected peer.
    private func handleConnectedState(peerID: MCPeerID) {
        Logger.shared.log("Connected to \(peerID.displayName)")
        if !connectedDevices.contains(peerID.displayName) {
            connectedDevices.append(peerID.displayName)
        }

#if os(iOS)
        // Stop browsing once connected
        stopBrowsing()
#elseif os(macOS)
        if savedClientPeerID == nil {
            savedClientPeerID = peerID
            UserDefaults.standard.set(peerID.displayName, forKey: "savedClientName")
            Logger.shared.log("Saved client: \(peerID.displayName)")
        }
        stopAdvertising()  // Stop advertising when connected
#endif

        // If we were attempting reconnection and connected to the current attempt peer
        if isReconnecting && peerID == currentAttemptPeerID {
            Logger.shared.log("Reconnection successful with \(peerID.displayName)")
            // Clear the reconnection queue and flags
            reconnectionPeersQueue.removeAll(where: { $0 == peerID })
            isReconnecting = false
        }
    }

    /// Handles the not connected state for a peer.
    /// - Parameter peerID: The `MCPeerID` of the disconnected peer.
    private func handleNotConnectedState(peerID: MCPeerID) {
        Logger.shared.log("Disconnected from \(peerID.displayName)")
        connectedDevices.removeAll { $0 == peerID.displayName }
        discoveredPeers.removeAll { $0 == peerID }
        mcSession.disconnect()
#if os(macOS)
        startAdvertising()  // Resume advertising when disconnected
#endif

        // If we were attempting reconnection and this was the current peer
        if isReconnecting && peerID == currentAttemptPeerID {
            Logger.shared.log("Failed to connect to \(peerID.displayName). Trying next peer.")
            // Remove the failed peer from the queue
            reconnectionPeersQueue.removeFirst()
            // Clear the current attempt
            currentAttemptPeerID = nil
            // Attempt to connect to the next peer
            attemptNextPeerInQueue()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try decodeMPCMessage(data)
            handleMessage(message, fromPeer: peerID)
        } catch {
            Logger.shared.log("Error decoding message from \(peerID.displayName): \(error.localizedDescription)")
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
        Logger.shared.log("Found peer withDiscoveryInfo : \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                Logger.shared.log("added to discovered peers: \(peerID.displayName)")
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


//MARK: MPC Communication protocol
extension PeerManager {

    /// Encodes an `MPCMessage` into `Data` for transmission.
    /// - Parameter message: The `MPCMessage` to encode.
    /// - Throws: An error if encoding fails.
    /// - Returns: Encoded `Data`.
    func encodeMPCMessage(_ message: MPCMessage) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(message)
    }

    /// Decodes `Data` into an `MPCMessage` after reception.
    /// - Parameter data: The received `Data`.
    /// - Throws: An error if decoding fails.
    /// - Returns: Decoded `MPCMessage`.
    func decodeMPCMessage(_ data: Data) throws -> MPCMessage {
        let decoder = JSONDecoder()
        return try decoder.decode(MPCMessage.self, from: data)
    }

    /// Sends a start Zoom call command to all connected peers.
    func sendStartZoomCallCommand() {
        let commandData = MPCStartZoomCallCommand()
        let payload = MPCPayload.command(.startZoomCall, commandData)
        let message = MPCMessage(messageType: .command, payload: payload)

        do {
            let data = try encodeMPCMessage(message)
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
            Logger.shared.log("Sent Start Zoom Call command")
        } catch {
            Logger.shared.log("Error sending Start Zoom Call command: \(error.localizedDescription)")
        }
    }

    /// Sends an end Zoom call command to all connected peers.
    func sendEndZoomCallCommand() {
        let commandData = MPCEndZoomCallCommand()
        let payload = MPCPayload.command(.endZoomCall, commandData)
        let message = MPCMessage(messageType: .command, payload: payload)

        do {
            let data = try encodeMPCMessage(message)
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
            Logger.shared.log("Sent End Zoom Call command")
        } catch {
            Logger.shared.log("Error sending End Zoom Call command: \(error.localizedDescription)")
        }
    }

    /// Send heartbeat message
    /// Sends a heartbeat message to all connected peers.
    private func sendHeartbeat() {
        let heartbeatCommand = MPCHeartbeatCommand(timestamp: Date())
        let heartbeatPayload = MPCPayload.heartbeat(heartbeatCommand)
        let heartbeatMessage = MPCMessage(messageType: .heartbeat, payload: heartbeatPayload)

        guard !mcSession.connectedPeers.isEmpty else { return }

        do {
            let data = try encodeMPCMessage(heartbeatMessage)
            // Assuming peerManager has a method to send data to all peers
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
            Logger.shared.log("Sent heartbeat at \(heartbeatCommand.timestamp)")
        } catch {
            Logger.shared.log("Failed to encode heartbeat message: \(error.localizedDescription)")
        }
    }

    /// Handles incoming `MPCMessage` from peers.
    /// - Parameters:
    ///   - message: The received `MPCMessage`.
    ///   - peerID: The `MCPeerID` of the peer who sent the message.
    func handleMessage(_ message: MPCMessage, fromPeer peerID: MCPeerID) {
        switch message.payload {
            case .command(let commandType, let data):
                handleCommand(commandType, data, fromPeer: peerID)
            case .response(let commandType, let status, let data):
                handleResponse(commandType, status, data, fromPeer: peerID)
            case .heartbeat:
                if case let .heartbeat(heartbeatCommand) = message.payload {
                    Logger.shared.log("Received heartbeat at \(heartbeatCommand.timestamp)")
                }
        }
    }

    /// Handles responses received from peers.
    /// - Parameters:
    ///   - commandType: The type of the command.
    ///   - status: The status of the response.
    ///   - data: Additional data associated with the response.
    ///   - peerID: The `MCPeerID` of the peer who sent the response.
    func handleResponse(_ commandType: MPCCommandType, _ status: MPCResponseStatus, _ data: MPCResponseData?, fromPeer peerID: MCPeerID) {
        switch commandType {
            case .startZoomCall:
                if status == .success, let responseData = data as? MPCStartZoomCallResponse {
                    // Handle successful start of Zoom call
                    let sessionName = responseData.sessionName
                    Logger.shared.log("Zoom call started with session name: \(sessionName)")
                    zoomSessionStartedPublisher.send(sessionName)
                } else if status == .failure, let errorData = data as? MPCErrorResponse {
                    // Handle error
                    Logger.shared.log("Failed to start Zoom call: \(errorData.errorMessage)")
                }
            case .endZoomCall:
                if status == .success, let responseData = data as? MPCEndZoomCallResponse {
                    // Handle successful end of Zoom call
                    Logger.shared.log(responseData.message ?? "Zoom call ended.")
                } else if status == .failure, let errorData = data as? MPCErrorResponse {
                    // Handle error
                    Logger.shared.log("Failed to end Zoom call: \(errorData.errorMessage)")
                }
        }
    }

    /// Handles incoming commands from peers.
    /// - Parameters:
    ///   - commandType: The type of the command.
    ///   - data: Additional data associated with the command.
    ///   - peerID: The `MCPeerID` of the peer who sent the command.
    func handleCommand(_ commandType: MPCCommandType, _ data: MPCCommandData, fromPeer peerID: MCPeerID) {
        switch commandType {
            case .startZoomCall:
                // Cast data to the specific command data type
                if let _ = data as? MPCStartZoomCallCommand {
                    // Publish startZoomCall event
                    startZoomCallPublisher.send(peerID)
                }
            case .endZoomCall:
                if let _ = data as? MPCEndZoomCallCommand {
                    // Publish endZoomCall event
                    endZoomCallPublisher.send(peerID)
                }
        }
    }

    /// Sends a response back to a specific peer.
    /// - Parameters:
    ///   - commandType: The type of the command being responded to.
    ///   - status: The status of the response (`success` or `failure`).
    ///   - data: Additional data associated with the response.
    ///   - peerID: The `MCPeerID` of the peer to send the response to.
    func sendResponse(commandType: MPCCommandType, status: MPCResponseStatus, data: MPCResponseData?, toPeer peerID: MCPeerID) {
        let payload = MPCPayload.response(commandType, status, data)
        let message = MPCMessage(messageType: .response, payload: payload)

        do {
            let data = try encodeMPCMessage(message)
            try mcSession.send(data, toPeers: [peerID], with: .reliable)
            Logger.shared.log("Sent response for \(commandType.rawValue) with status: \(status.rawValue)")
        } catch {
            Logger.shared.log("Error sending response: \(error.localizedDescription)")
        }
    }
}
