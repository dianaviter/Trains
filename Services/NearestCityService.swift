//
//  NearestCityService.swift
//  Trains
//
//  Created by Diana Viter on 12.07.2025.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

typealias NearestCity = Components.Schemas.NearestCityResponse

protocol NearestCityProtocol {
    func getNearestCity(lat: Double, lng: Double) async throws -> NearestCity
}

actor NearestCityService: NearestCityProtocol {
    
    private let client: Client
    private let apikey: String
    
    init(client: Client, apikey: String) {
        self.client = client
        self.apikey = apikey
    }
    
    func getNearestCity(lat: Double, lng: Double) async throws -> NearestCity {
        let response = try await client.getNearestCity(query: .init(
            apikey: apikey,
            lat: lat,
            lng: lng
        ))
        return try response.ok.body.json
    }
}
