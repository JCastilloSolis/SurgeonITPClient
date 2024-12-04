//
//  ServerViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 12/3/24.
//


import Combine
import Foundation

class ServerViewModel: ObservableObject {
    @Published var peerViewModel: PeerViewModel
    @Published var sessionViewModel: SessionViewModel
    @Published var serverState: ServerState


    private var cancellables = Set<AnyCancellable>()

    init() {
        self.peerViewModel = PeerViewModel()
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
        // Observe PeerViewModel for connection status changes
//        peerViewModel.$connectionStatus
//            .receive(on: RunLoop.main)
//            .sink { [weak self] status in
//                self?.serverState.serverStatus = status.toServerStatus()
//            }
//            .store(in: &cancellables)
//
//        // Observe SessionViewModel for Zoom session changes
//        sessionViewModel.$serverState
//            .receive(on: RunLoop.main)
//            .sink { [weak self] newState in
//                self?.serverState = newState
//                self?.sendServerState()
//            }
//            .store(in: &cancellables)
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
