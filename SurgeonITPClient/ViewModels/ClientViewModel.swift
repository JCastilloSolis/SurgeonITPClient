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

    // MARK: - Private Properties
    private var previousProximity: CLProximity = .unknown
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Managers
    let peerManager: PeerManager
    let beaconManager: BeaconManagerService


    // MARK: - Initialization
    init() {
        self.peerManager = PeerManager()
        self.beaconManager = BeaconManagerService()
        setupBindings()
        Logger.shared.log("initialization complete")
    }


    private func setupBindings() {
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
                        //TODO: Check if user is within the range before attempt a reconnection
                        if self.proximity != .unknown {
                            self.peerManager.attemptReconnection()
                        }
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

                Logger.shared.log("New value for discoveredPeers : \(peers)")

                guard !peers.isEmpty else {
                    return
                }

                Logger.shared.log("New peers discovered \(peers)")
                self?.peerManager.attemptReconnection()
            }
            .store(in: &cancellables)

        // Bindings from BeaconManagerService
        beaconManager.$proximity
            .assign(to: \.proximity, on: self)
            .store(in: &cancellables)


        //TODO: Disable beacon ranging once an MPC session is confirmed, only enable it again once the mpc session has been lost and not able to reconnect
        // Handle proximity changes
        beaconManager.$proximity
            .sink { [weak self] proximity in
                self?.handleProximityChange(proximity)
                self?.previousProximity = proximity
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods
    func startZoomCall() {
        peerManager.sendStartZoomCallCommand()
        Logger.shared.log("Start zoom call command sent")
    }

    func stopZoomCall() {
        peerManager.sendEndZoomCallCommand()
        Logger.shared.log("End zoom call command sent")
    }

    func clearSavedServer() {
        Logger.shared.log("Clear Saved Server info")
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
        //log("Proximity changed to \(proximity.rawValue). Previous Value: \(previousProximity.rawValue).")

        if proximity != .unknown && previousProximity == .unknown {
            // Just started detecting the beacon; start MPC browsing
            Logger.shared.log("Beacon found. Start MPC Browsing.")
            startMPCBrowsing()
        } else if proximity == .unknown && previousProximity != .unknown {
            // Beacon was lost; stop MPC browsing
            Logger.shared.log("Beacon lost. Stopping MPC Browsing.")
            stopMPCBrowsing()
        }
        previousProximity = proximity
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
