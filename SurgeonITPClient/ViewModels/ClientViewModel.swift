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
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var messageCounter: Int = 0
    @Published var connectionStatus: String = "Not Connected"
    @Published var connectionColor: Color = .red
    @Published var previouslyPaired: Bool = false
    @Published var previouslyPairedServer: String = "server to connect"
    @Published var showProgressView: Bool = false
    @Published var proximity: CLProximity = .unknown
    @Published var sessionViewModel: SessionViewModel
    @Published var selectedTab = 0
    @Published var sortedBeacons: [CLBeacon] = []
    @Published var nearestBeacon: CLBeacon?
    @Published var nearestBeaconDisplayName: String?

    // MARK: - Private Properties
    private var previousProximity: CLProximity = .unknown
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Managers
    let peerManager: PeerManager
    let beaconManager: BeaconManagerService

    // MARK: - Harcoded data, should be in a DB
    let beaconToPeerDisplayNameMap: [BeaconData: String] = [
        BeaconData(major: 1, minor: 1): "Jorge’s MacBook Pro",
        BeaconData(major: 1, minor: 2): "Jorge’s MacBook Pro",
        // Add more mappings as needed
    ]



    // MARK: - Initialization
    init() {
        self.peerManager = PeerManager()
        self.beaconManager = BeaconManagerService()
        self.sessionViewModel = SessionViewModel()
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

        peerManager.$messageCounter
            .assign(to: \.messageCounter, on: self)
            .store(in: &cancellables)

        peerManager.zoomSessionStartedPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] sessionName in
                self?.handleZoomSessionStarted(sessionName: sessionName)
            }
            .store(in: &cancellables)

        peerManager.$sessionState
            .receive(on: RunLoop.main)
            .map { [weak self] state -> (String, Color) in
                guard let self = self else { return ("Not Connected", .red) }
                switch state {
                    case .connected:
                        self.showProgressView = false
                        self.previouslyPaired = true
                        self.stopMPCBrowsing()
                        return ("Connected to \(self.peerManager.connectedDevices.joined(separator: ", "))", .green)
                    case .connecting:
                        self.showProgressView = self.previouslyPaired
                        return ("Connecting", .blue)
                    case .notConnected:
                        self.showProgressView = self.previouslyPaired
                        // Check if user is within the range before attempt a reconnection
                        if self.proximity != .unknown {
                            self.startMPCBrowsing()
                            if let nearestBeaconDisplayName = self.nearestBeaconDisplayName {
                                self.peerManager.attemptReconnection(serverName: nearestBeaconDisplayName)
                            }
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

        // Reconnection logic
        peerManager.$discoveredPeers
            .receive(on: RunLoop.main)
            .sink { [weak self] peers in
                guard let self else { return }

                Logger.shared.log("New value for discoveredPeers : \(peers)")

                guard !peers.isEmpty else {
                    return
                }

                Logger.shared.log("New peers discovered \(peers)")

                if let nearestBeaconDisplayName = self.nearestBeaconDisplayName {
                    self.peerManager.attemptReconnection(serverName: nearestBeaconDisplayName)
                }
            }
            .store(in: &cancellables)

        // Bindings from BeaconManagerService
        beaconManager.$proximity
            .assign(to: \.proximity, on: self)
            .store(in: &cancellables)

        beaconManager.$nearestBeacon
            .assign(to: \.nearestBeacon, on: self)
            .store(in: &cancellables)


        //TODO: Disable beacon ranging once an MPC session is confirmed, only enable it again once the mpc session has been lost and not able to reconnect
        // Handle proximity changes
        beaconManager.$proximity
            .sink { [weak self] proximity in
                self?.handleProximityChange(proximity)
                self?.previousProximity = proximity
            }
            .store(in: &cancellables)

        // Handle beacon-based peer connection
        beaconManager.$nearestBeacon
            .sink { [weak self] beacon in
                guard let beacon else {
                    return
                }

                self?.handleNearestBeacon(beacon)
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

    // MARK: - Beacon Handling

    /// Handles the event of detecting a beacon and attempts to retrieve its saved MPC Display name
    /// - Parameter beacon: The nearest `CLBeacon` detected.
    private func handleNearestBeacon(_ beacon: CLBeacon) {
        // Guard against unknown proximity
        guard beacon.proximity != .unknown else {
            Logger.shared.log("Detected beacon with unknown proximity. Ignoring.")
            nearestBeaconDisplayName = nil
            return
        }

        if nearestBeaconDisplayName == nil {
            // Create a BeaconIdentifier from the detected beacon
            let beaconData = BeaconData(major: beacon.major.uint16Value, minor: beacon.minor.uint16Value)

            // Lookup the display name associated with this beacon
            guard let peerDisplayName = beaconToPeerDisplayNameMap[beaconData] else {
                Logger.shared.log("No peer mapping found for beacon: \(beaconData).")
                return
            }
            self.nearestBeaconDisplayName = peerDisplayName
            Logger.shared.log("Beacon detected: \(beaconData). Associated peer: \(peerDisplayName)")
        }
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

    /// Handles the event when a Zoom session has started.
    /// - Parameter sessionName: The name of the started Zoom session.
    private func handleZoomSessionStarted(sessionName: String) {
        Logger.shared.log("Handling Zoom session started with sessionName: \(sessionName)")

        // Instruct SessionViewModel to join the Zoom session
        sessionViewModel.joinSession(sessionName: sessionName)
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
