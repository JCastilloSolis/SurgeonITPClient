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



class PeerViewModel: ObservableObject {
    @Published var connectedPeers: [String] = []
    @Published var receivedMessages: [String] = []
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var messageCounter: Int = 0
    @Published var connectionStatus: String = "Not Connected"
    @Published var connectionColor: Color = .red
    @Published var previouslyPaired: Bool = false
    @Published var previouslyPairedServer: String = "server to connect"
    @Published var showProgressView: Bool = false

    var peerManager: PeerManager
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.peerManager = PeerManager()

        peerManager.$connectedDevices
            .assign(to: \.connectedPeers, on: self)
            .store(in: &cancellables)

        peerManager.$discoveredPeers
            .assign(to: \.discoveredPeers, on: self)
            .store(in: &cancellables)

        peerManager.$receivedMessages
            .assign(to: \.receivedMessages, on: self)
            .store(in: &cancellables)

        peerManager.$messageCounter
            .assign(to: \.messageCounter, on: self)
            .store(in: &cancellables)

        peerManager.$sessionState
            .receive(on: RunLoop.main)
            .map { state -> (String, Color) in
                switch state {
                    case .connected:
                        self.showProgressView = false
                        self.previouslyPaired = true
                        return ("Connected to \(self.peerManager.connectedDevices.joined(separator: ", "))", .green)
                    case .connecting:
                        #if os(iOS)
                        self.showProgressView = self.previouslyPaired
                        #else
                        self.showProgressView = true
                        #endif
                        return ("Connecting", .blue)
                    case .notConnected:
                        self.showProgressView = self.previouslyPaired
                        #if os(iOS)
                        self.attemptReconnection()
                        return ("Not Connected, looking for \(self.previouslyPairedServer)", .red)
                        #else
                        return ("Not Connected", .red)
                        #endif
                    @unknown default:
                        #if os(iOS)
                        return ("Not Connected, looking for \(self.previouslyPairedServer)", .red)
                        #else
                        return ("Not Connected", .red)
                        #endif
                }
            }
            .sink { [weak self] status, color in
                self?.connectionStatus = status
                self?.connectionColor = color
            }
            .store(in: &cancellables)

#if os(iOS)
        if let savedServerName = UserDefaults.standard.string(forKey: "savedServerName") {
            previouslyPaired = true
            previouslyPairedServer = savedServerName
        }



        peerManager.$discoveredPeers
            .receive(on: RunLoop.main)
            .map {$0}
            .sink { peer  in
                self.log("New peer discovered \(peer)")
                //TODO: Move this to a timer so that the device tries every certain time
                self.attemptReconnection()
            }
            .store(in: &cancellables)
#endif

#if os(macOS)
        if let savedClientName = UserDefaults.standard.string(forKey: "savedClientName") {
            previouslyPaired = true
            previouslyPairedServer = savedClientName
        }
#endif


    }

    func sendCommand(_ command: String) {
        peerManager.send(command, type: .command)
        log("Command sent: \(command)")
    }

    func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] \(message)")
    }

    private func attemptReconnection() {
        log("Will start Attempt for Reconnection")
        if let savedServerName = UserDefaults.standard.string(forKey: "savedServerName"),
           let serverPeer = peerManager.discoveredPeers.first(where: { $0.displayName == savedServerName }) {
            log("Will try to connect to \(savedServerName)")
            previouslyPaired = true
            peerManager.selectPeerForConnection(peerID: serverPeer)
        } else {
            log("There was not available server to attempt to connect to.")
        }
    }

    func clearSavedServer() {
        log("Clear Saved Server info")
        UserDefaults.standard.removeObject(forKey: "savedServerName")
        connectionStatus = "Not Connected"
        previouslyPaired = false
        showProgressView = false
        previouslyPairedServer = "server to connect"
        peerManager.leaveSession() // Ensure to stop the heartbeat if it was running
        // Attempt to reconnect or handle further logic post clearing
    }

    func clearSavedClient() {
        log("Clear Saved Client info")
        UserDefaults.standard.removeObject(forKey: "savedClientName")
        connectionStatus = "Not Connected"
        previouslyPaired = false
        previouslyPairedServer = "client to connect"
        showProgressView = false
        peerManager.forgetClient() // Clear the saved client in peer manager
        // Attempt to reconnect or handle further logic post clearing
    }

    func selectServer(peerID: MCPeerID) {
        peerManager.selectPeerForConnection(peerID: peerID)
        previouslyPaired = true
    }
}
