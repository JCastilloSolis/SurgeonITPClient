//
//  PeerManagerService.swift
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
    @Published var receivedMessages: [String] = []
    @Published var messageCounter = 0
    @Published var sessionState: MCSessionState = .notConnected

    // MARK: - Publishers
    let startZoomCallPublisher = PassthroughSubject<MCPeerID, Never>()
    let endZoomCallPublisher = PassthroughSubject<MCPeerID, Never>()


    // MARK: Private vars
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

    func sendHeartbeat() {
        guard
            connectedDevices.count > 0
        else {
            //Logger.shared.log("Cannot send heartbeat: No connected devices")
            return
        }


        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        let message = "Heartbeat \(messageCounter): \(timeString)"
        DispatchQueue.main.async {
            self.messageCounter += 1
        }
        //send(message, type: .heartbeat)
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


//MARK: MPC Communication protocol
extension PeerManager {
    /// Encodes an MPCMessage into Data for transmission.
    func encodeMPCMessage(_ message: MPCMessage) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(message)
    }

    /// Decodes Data into an MPCMessage after reception.
    func decodeMPCMessage(_ data: Data) throws -> MPCMessage {
        let decoder = JSONDecoder()
        return try decoder.decode(MPCMessage.self, from: data)
    }

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

    func handleMessage(_ message: MPCMessage, fromPeer peerID: MCPeerID) {
        switch message.payload {
            case .command(let commandType, let data):
                handleCommand(commandType, data, fromPeer: peerID)
            case .response(let commandType, let status, let data):
                handleResponse(commandType, status, data, fromPeer: peerID)
        }
    }

    func handleResponse(_ commandType: MPCCommandType, _ status: MPCResponseStatus, _ data: MPCResponseData?, fromPeer peerID: MCPeerID) {
        switch commandType {
            case .startZoomCall:
                if status == .success, let responseData = data as? MPCStartZoomCallResponse {
                    // Handle successful start of Zoom call
                    let sessionName = responseData.sessionName
                    Logger.shared.log("Zoom call started with session name: \(sessionName)")
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
