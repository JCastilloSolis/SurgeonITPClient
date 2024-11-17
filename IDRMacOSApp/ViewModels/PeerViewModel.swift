//
//  PeerViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//



import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity


/// Manages peer connections, handles received commands, and coordinates with SessionViewModel for Zoom call management.
class PeerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var connectedPeers: [String] = []
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var messageCounter: Int = 0
    @Published var connectionStatus: String = "Not Connected"
    @Published var connectionColor: Color = .red
    @Published var previouslyPaired: Bool = false
    @Published var previouslyPairedServer: String = "server to connect"
    @Published var showProgressView: Bool = false
    @Published var shouldStartZoomCall: Bool = false
    @Published var shouldEndZoomCall: Bool = false

    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    private var currentCommandPeerID: MCPeerID?

    var peerManager: PeerManager

    // MARK: - Initialization

    init() {
        self.peerManager = PeerManager()

        peerManager.$connectedDevices
            .assign(to: \.connectedPeers, on: self)
            .store(in: &cancellables)

        peerManager.$discoveredPeers
            .assign(to: \.discoveredPeers, on: self)
            .store(in: &cancellables)

        peerManager.$messageCounter
            .assign(to: \.messageCounter, on: self)
            .store(in: &cancellables)

        peerManager.startZoomCallPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] peerID in
                Logger.shared.log("PeerViewModel - Received startZoomCall command from \(peerID.displayName)")
                self?.currentCommandPeerID = peerID
                self?.shouldStartZoomCall = true
            }
            .store(in: &cancellables)

        peerManager.endZoomCallPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] peerID in
                Logger.shared.log("PeerViewModel - Received endZoomCall command from \(peerID.displayName)")
                self?.currentCommandPeerID = peerID
                self?.shouldEndZoomCall = true
            }
            .store(in: &cancellables)

        // Observe session state changes to update UI
        peerManager.$sessionState
            .receive(on: RunLoop.main)
            .map { state -> (String, Color) in
                switch state {
                    case .connected:
                        self.showProgressView = false
                        self.previouslyPaired = true
                        return ("Connected to \(self.peerManager.connectedDevices.joined(separator: ", "))", .green)
                    case .connecting:
                        self.showProgressView = true
                        return ("Connecting", .blue)
                    case .notConnected:
                        self.showProgressView = self.previouslyPaired
                        return ("Not Connected", .red)
                    @unknown default:
                        return ("Not Connected", .red)
                }
            }
            .sink { [weak self] status, color in
                self?.connectionStatus = status
                self?.connectionColor = color
            }
            .store(in: &cancellables)

        // Check if previously paired
        if let savedClientName = UserDefaults.standard.string(forKey: "savedClientName") {
            previouslyPaired = true
            previouslyPairedServer = savedClientName
        }
    }

    // MARK: - Methods

    /// Clears the saved client information and resets connection states.
    func clearSavedClient() {
        Logger.shared.log("Clear Saved Client info")
        UserDefaults.standard.removeObject(forKey: "savedClientName")
        connectionStatus = "Not Connected"
        previouslyPaired = false
        previouslyPairedServer = "client to connect"
        showProgressView = false
        peerManager.forgetClient() // Clear the saved client in peer manager
    }

    /// Handles the event when a Zoom session has started successfully.
    /// Sends a response back to the requesting peer with the session name.
    /// - Parameter sessionName: The name of the started Zoom session.
    func sessionDidStart(sessionName: String) {
        if let peerID = self.currentCommandPeerID {
            // Prepare response data
            let responseData = MPCStartZoomCallResponse(sessionName: sessionName)
            // Send response via peerManager
            self.peerManager.sendResponse(commandType: .startZoomCall, status: .success, data: responseData, toPeer: peerID)
            // Clear the stored peerID
            self.currentCommandPeerID = nil
        } else {
            Logger.shared.log("No peerID stored; cannot send session start response.")
        }
    }

    /// Handles the event when a Zoom session has ended successfully.
    /// Sends a response back to the requesting peer indicating success.
    func sessionDidEnd() {
        if let peerID = self.currentCommandPeerID {
            // Prepare response data
            let responseData = MPCEndZoomCallResponse(message: "Zoom call ended successfully.")
            // Send response via peerManager
            self.peerManager.sendResponse(commandType: .endZoomCall, status: .success, data: responseData, toPeer: peerID)
            // Clear the stored peerID
            self.currentCommandPeerID = nil
            Logger.shared.log("Sent success response for endZoomCall to \(peerID.displayName)")
        } else {
            Logger.shared.log("No peerID stored; cannot send session end response.")
        }
    }
}
