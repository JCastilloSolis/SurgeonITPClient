//
//  ServerViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 12/3/24.
//


import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity


//TODO: Investigate why UI is not responding accordingly after the ServerViewModel creation
class ServerViewModel: ObservableObject {
    @Published var sessionViewModel: SessionViewModel
    @Published var serverState: ServerState
    @Published var connectedPeers: [String] = []
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var messageCounter: Int = 0
    @Published var connectionStatus: String = "Not Connected"
    @Published var connectionColor: Color = .red
    @Published var previouslyPaired: Bool = false
    @Published var previouslyPairedServer: String = "server to connect"
    @Published var showProgressView: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var currentCommandPeerID: MCPeerID?
    var peerManager: PeerManager

    init() {
        self.peerManager = PeerManager()
        self.sessionViewModel = SessionViewModel()
        self.serverState = ServerState(
            isInZoomCall: false,
            zoomSessionID: nil,
            participantCount: 0,
            serverStatus: .idle
        )

        setupBindings()
    }

    private func setupBindings() {
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
                Logger.shared.log("Received startZoomCall command from \(peerID.displayName)")
                self?.currentCommandPeerID = peerID
                let sessionName = UserDefaults.standard.string(forKey: "sessionName") ?? ""
                self?.sessionViewModel.startSession(sessionName: sessionName)
            }
            .store(in: &cancellables)

        peerManager.endZoomCallPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] peerID in
                Logger.shared.log("Received endZoomCall command from \(peerID.displayName)")
                self?.currentCommandPeerID = peerID
                self?.sessionViewModel.leaveSession()
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

        // Observe SessionViewModel's sessionEndedPublisher
        sessionViewModel.sessionEndedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.sessionDidEnd()
                self.serverState.isInZoomCall = false
                self.serverState.serverStatus = .idle
            }
            .store(in: &cancellables)

        // Observe SessionViewModel's sessionStartedPublisher
        sessionViewModel.sessionStartedPublisher
            .sink { [weak self] sessionName in
                guard let self = self else { return }
                self.sessionDidStart(sessionName: sessionName)
                self.serverState.isInZoomCall = true
                self.serverState.serverStatus = .inZoomCall
            }
            .store(in: &cancellables)
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

    // Method to send ServerState via MPC
    func sendServerState() {
//        Task {
//            do {
//                let data = try JSONEncoder().encode(serverState)
//                try await peerManager.sendData(data)
//            } catch {
//                Logger.shared.log("Failed to encode/send ServerState: \(error.localizedDescription)")
//            }
//        }
    }

    // Method to handle received ServerState
    func updateServerState(_ receivedState: ServerState) {
        DispatchQueue.main.async {
            self.serverState = receivedState
        }
    }

    // Additional Methods as Needed
}
