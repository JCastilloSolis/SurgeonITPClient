//
//  ClientViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//

import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity
import CoreLocation

@MainActor
class ClientViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var connectedPeers: [String] = []
    @Published var receivedMessages: [String] = []
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var messageCounter: Int = 0
    @Published var connectionStatus: String = "Not Connected"
    @Published var connectionColor: Color = .red
    @Published var previouslyPaired: Bool = false
    @Published var previouslyPairedServer: String = "server to connect"
    @Published var showProgressView: Bool = false
    @Published var proximity: CLProximity = .unknown
    var previousProximity: CLProximity = .unknown

    // MARK: - Managers
    var peerManager: PeerManager
    var beaconManager: BeaconManagerService
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Initialization
    init() {
        self.peerManager = PeerManager()
        self.beaconManager = BeaconManagerService()

        // Bindings from PeerManager
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
            .map { [weak self] state -> (String, Color) in
                guard let self = self else { return ("Not Connected", .red) }
                switch state {
                    case .connected:
                        self.showProgressView = false
                        self.previouslyPaired = true
                        return ("Connected to \(self.peerManager.connectedDevices.joined(separator: ", "))", .green)
                    case .connecting:
                        self.showProgressView = self.previouslyPaired
                        return ("Connecting", .blue)
                    case .notConnected:
                        self.showProgressView = self.previouslyPaired
                        self.attemptReconnection()
                        return ("Not Connected, looking for \(self.previouslyPairedServer)", .red)
                    @unknown default:
                        return ("Not Connected, looking for \(self.previouslyPairedServer)", .red)
                }
            }
            .sink { [weak self] status, color in
                self?.connectionStatus = status
                self?.connectionColor = color
            }
            .store(in: &cancellables)

        // Load previously paired server
        if let savedServerName = UserDefaults.standard.string(forKey: "savedServerName") {
            previouslyPaired = true
            previouslyPairedServer = savedServerName
        }

        // Reconnection logic
        peerManager.$discoveredPeers
            .receive(on: RunLoop.main)
            .sink { [weak self] peers in
                self?.log("New peers discovered \(peers)")
                self?.attemptReconnection()
            }
            .store(in: &cancellables)

        // Bindings from BeaconManagerService
        beaconManager.$proximity
            .assign(to: \.proximity, on: self)
            .store(in: &cancellables)

        // Handle proximity changes
        beaconManager.$proximity
            .sink { [weak self] proximity in
                self?.handleProximityChange(proximity)
                self?.previousProximity = proximity
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func sendCommand(_ command: String) {
        peerManager.send(command, type: .command)
        log("Command sent: \(command)")
    }

    func log(_ message: String) {
        Logger.shared.log(message)
    }

    private func attemptReconnection() {
        log("Will start Attempt for Reconnection")
        if let savedServerName = UserDefaults.standard.string(forKey: "savedServerName"),
           let serverPeer = peerManager.discoveredPeers.first(where: { $0.displayName == savedServerName }) {
            log("Will try to connect to \(savedServerName)")
            previouslyPaired = true
            peerManager.selectPeerForConnection(peerID: serverPeer)
        } else {
            log("There was no available server to attempt to connect to.")
        }
    }

    func clearSavedServer() {
        log("Clear Saved Server info")
        UserDefaults.standard.removeObject(forKey: "savedServerName")
        connectionStatus = "Not Connected"
        previouslyPaired = false
        showProgressView = false
        previouslyPairedServer = "server to connect"
        peerManager.leaveSession()
    }

    func selectServer(peerID: MCPeerID) {
        peerManager.selectPeerForConnection(peerID: peerID)
        previouslyPaired = true
    }

    func startBeaconScanning() {
        beaconManager.startScanning()
    }

    func stopBeaconScanning() {
        beaconManager.stopRangingBeacons()
    }

    private func handleProximityChange(_ proximity: CLProximity) {
        if proximity != .unknown && previousProximity == .unknown {
            // Just started detecting the beacon; start MPC browsing
            //createNotification(title: "Beacon Detected", body: "You are near the beacon.")
            startMPCBrowsing()
            //stopBeaconScanning()
        } else if proximity == .unknown && previousProximity != .unknown {
            // Beacon was lost; stop MPC browsing
            Logger.shared.log("Beacon lost. Stopping MPC browsing.")
            stopMPCBrowsing()
            //startBeaconScanning()
        }
    }

    /// Starts MultipeerConnectivity browsing.
    private func startMPCBrowsing() {
        Logger.shared.log("Starting MPC browsing.")
        peerManager.startBrowsing()
    }

    /// Stops MultipeerConnectivity browsing.
    private func stopMPCBrowsing() {
        Logger.shared.log("Stopping MPC browsing.")
        peerManager.leaveSession()
        peerManager.stopBrowsing()
    }
}
