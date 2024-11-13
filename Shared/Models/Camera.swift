//
//  Camera.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/12/24.
//


/// Represents a camera device with an identifier and name.
struct Camera: Identifiable, Codable {
    let id: String
    let name: String
}
