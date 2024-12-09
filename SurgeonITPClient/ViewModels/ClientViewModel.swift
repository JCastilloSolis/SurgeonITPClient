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
    @Published var showProgressView: Bool = false
    //@Published var proximity: CLProximity = .unknown
    @Published var sessionViewModel: SessionViewModel
    @Published var selectedTab = 0
    @Published var mpcSessionState: MCSessionState = .notConnected
    @Published var sortedBeacons: [CLBeacon] = []
    @Published var nearestBeacon: CLBeacon?
    @Published var currentNearestBeaconDisplayName: String?
    @Published var receivedServerState: ServerState?

    // MARK: - Private Properties
    //private var previousProximity: CLProximity = .unknown
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Managers
    let peerManager: PeerManager
    let beaconManager: BeaconManagerService
    
    
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
        peerManager.$receivedServerState
            .assign(to: \.receivedServerState, on: self)
            .store(in: &cancellables)

/// automatically join session if it exists
//        peerManager.$receivedServerState
//            .receive(on: RunLoop.main)
//            .sink { [weak self] serverState in
//                guard
//                    let self,
//                    let sessionName = serverState?.zoomSessionID,
//                    serverState?.serverStatus == .inZoomCall,
//                    !self.sessionViewModel.sessionIsActive
//                else { return }
//
//                //IDR is in a zoom call, automatically rejoin
//                rejoinZoomCall(sessionName: sessionName)
//            }
//            .store(in: &cancellables)

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
                        self.stopMPCBrowsing()
                        return ("Connected to \(self.peerManager.connectedDevices.joined(separator: ", "))", .green)
                    case .connecting:
                        self.showProgressView = true
                        return ("Connecting", .blue)
                    case .notConnected:
                        guard let currentNearestBeaconDisplayName = currentNearestBeaconDisplayName else { return ("Not Connected", .red) }
                        // Check if user is within the range before attempt a reconnection
                    if (self.nearestBeacon != nil) {
                            self.startMPCBrowsing()
                            self.peerManager.attemptReconnection(serverName: currentNearestBeaconDisplayName)
                        }
                        return ("Not Connected, looking for \(currentNearestBeaconDisplayName)", .red)
                    @unknown default:
                        guard let currentNearestBeaconDisplayName = currentNearestBeaconDisplayName else { return ("Not Connected", .red) }
                        return ("Not Connected, looking for \(currentNearestBeaconDisplayName)", .red)
                }
            }
            .sink { [weak self] status, color in
                self?.connectionStatus = status
                self?.connectionColor = color
            }
            .store(in: &cancellables)

        peerManager.$sessionState
            .assign(to: \.mpcSessionState, on: self)
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

                if let currentNearestBeaconDisplayName = self.currentNearestBeaconDisplayName {
                    self.peerManager.attemptReconnection(serverName: currentNearestBeaconDisplayName)
                }
            }
            .store(in: &cancellables)

        // Bindings from BeaconManagerService
        beaconManager.$sortedBeacons
            .assign(to: \.sortedBeacons, on: self)
            .store(in: &cancellables)

        beaconManager.$currentNearestBeacon
            .assign(to: \.nearestBeacon, on: self)
            .store(in: &cancellables)
        
        beaconManager.$currentNearestBeacon
            .assign(to: \.nearestBeacon, on: self)
            .store(in: &cancellables)
        
        // Handle beacon-based peer connection
        beaconManager.$currentNearestBeacon
            .sink { [weak self] beacon in
                guard let self else { return }
                
                guard let beacon else {
                    
                    if self.peerManager.sessionState == .connected {
                        self.cleanup()
                    }
                    return
                }

                self.handleNearestBeacon(beacon)
            }
            .store(in: &cancellables)

        // Zoom bindings
        sessionViewModel.$sessionIsActive
            .receive(on: RunLoop.main)
            .sink { [weak self] sessionIsActive in
                guard let self else { return }
                showProgressView.toggle()
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods
    func startZoomCall() {
        if !showProgressView {
            showProgressView = true
            peerManager.sendStartZoomCallCommand()
            Logger.shared.log("Start zoom call command sent")
        }
    }

    func stopZoomCall() {
        if !showProgressView {
            showProgressView = true
            peerManager.sendEndZoomCallCommand()
            Logger.shared.log("End zoom call command sent")
        }
    }

    func rejoinZoomCall(sessionName: String) {
        if !showProgressView {
            showProgressView = true
            sessionViewModel.joinSession(sessionName: sessionName)
        }
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
            if peerManager.sessionState == .connected {
                cleanup()
            }
            return
        }
        
        cleanup()
        startMPCBrowsing()
        
        guard let peerDisplayName = getDisplayNameForBeacon(beacon) else {
            Logger.shared.log("No name was found for \(beacon)")
            return
        }
        
        self.currentNearestBeaconDisplayName = peerDisplayName
        Logger.shared.log("Beacon detected: \(beacon). Associated peer: \(peerDisplayName)")

    }
    
    func getDisplayNameForBeacon(_ beacon: CLBeacon) -> String?{
        // Create a BeaconIdentifier from the detected beacon
        let beaconData = BeaconData(major: beacon.major.uint16Value, minor: beacon.minor.uint16Value)
        
        // Lookup the display name associated with this beacon
        guard let peerDisplayName = Constants.beaconToPeerDisplayNameMap[beaconData] else {
            Logger.shared.log("No peer mapping found for beacon: \(beaconData).")
            return nil
        }
        
        return peerDisplayName
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
        peerManager.stopBrowsing()
    }
    
    /// Leaves the MPC session.
    private func leaveMPCSession() {
        Logger.shared.log("Beacon was lost, terminating MPC session")
        peerManager.leaveSession()
    }

    
    private func cleanup() {
        Logger.shared.log("Cleaning up. Leave MPC and Zoom sessions")
        currentNearestBeaconDisplayName = nil
        if peerManager.sessionState == .connected {
            leaveMPCSession()
        }
        
        if sessionViewModel.sessionIsActive {
            sessionViewModel.leaveSession()
        }
        
        
    }
    
}
