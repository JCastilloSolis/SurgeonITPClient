//
//  ServerViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 12/3/24.
//


import Combine
import Foundation


//TODO: Investigate why UI is not responding accordingly after the ServerViewModel creation
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

        // Observe shouldStartZoomCall and handle Zoom session initiation
        peerViewModel.$shouldStartZoomCall
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.peerViewModel.shouldStartZoomCall = false
                let sessionName = UserDefaults.standard.string(forKey: "sessionName") ?? ""
                self.sessionViewModel.startSession(sessionName: sessionName)
            }
            .store(in: &cancellables)

        // Observe shouldEndZoomCall and handle Zoom session termination
        peerViewModel.$shouldEndZoomCall
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.peerViewModel.shouldEndZoomCall = false
                self.sessionViewModel.leaveSession()
            }
            .store(in: &cancellables)

        // Observe SessionViewModel's sessionEndedPublisher
        sessionViewModel.sessionEndedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.peerViewModel.sessionDidEnd()
                self.serverState.isInZoomCall = false
                self.serverState.serverStatus = .idle
            }
            .store(in: &cancellables)

        // Observe SessionViewModel's sessionStartedPublisher
        sessionViewModel.sessionStartedPublisher
            .sink { [weak self] sessionName in
                guard let self = self else { return }
                self.peerViewModel.sessionDidStart(sessionName: sessionName)
                self.serverState.isInZoomCall = true
                self.serverState.serverStatus = .inZoomCall
            }
            .store(in: &cancellables)
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
