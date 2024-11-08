//
//  ServerView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/8/24.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var viewModel: PeerViewModel

    var body: some View {
        VStack {
            HStack {
                Text(viewModel.connectionStatus)
                    .foregroundColor(viewModel.connectionColor)
                if viewModel.showProgressView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.receivedMessages, id: \.self) { message in
                        Text("Received: \(message)")
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(5)
                    }
                }
                .padding(.horizontal)
            }

            Text("Message Count: \(viewModel.messageCounter)")
                .padding()

            HStack {
                Button("Clear Log") {
                    viewModel.receivedMessages.removeAll()
                }
                .buttonStyle(.bordered)

                Button("Refresh Status") {
                    viewModel.sendCommand("status")
                }
                .buttonStyle(.bordered)

                if viewModel.previouslyPaired {
                    Button("Forget Client Device") {
                        viewModel.clearSavedClient()
                    }
                    .padding()
                    .foregroundColor(.red)
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ServerView(viewModel: PeerViewModel())
}
