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
    @Published var shouldStartZoomCall: Bool = false
    @Published var shouldEndZoomCall: Bool = false

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


        peerManager.startZoomCallPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.shouldStartZoomCall = true
            }
            .store(in: &cancellables)

        peerManager.endZoomCallPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.shouldEndZoomCall = true
            }
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

        if let savedClientName = UserDefaults.standard.string(forKey: "savedClientName") {
            previouslyPaired = true
            previouslyPairedServer = savedClientName
        }
    }

    func clearSavedClient() {
        Logger.shared.log("Clear Saved Client info")
        UserDefaults.standard.removeObject(forKey: "savedClientName")
        connectionStatus = "Not Connected"
        previouslyPaired = false
        previouslyPairedServer = "client to connect"
        showProgressView = false
        peerManager.forgetClient() // Clear the saved client in peer manager
        // Attempt to reconnect or handle further logic post clearing
    }

    func handleStartZoomCallCommand() {
        DispatchQueue.main.async {
            self.shouldStartZoomCall = true
        }
    }
}
