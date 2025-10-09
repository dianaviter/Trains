//
//  SchedualBetweenStationsService.swift
//  Trains
//
//  Created by Diana Viter on 10.07.2025.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

typealias SchedualBetweenStations = Components.Schemas.Segments

protocol SchedualBetweenStationsProtocol {
    func getSchedualBetweenStations(
        from: String,
        to: String,
        transfers: Bool?,
        date: String?,
        transportTypes: String?
    ) async throws -> SchedualBetweenStations
}

actor SchedualBetweenStationsService: SchedualBetweenStationsProtocol {

    private let client: Client
    private let apikey: String

    init(client: Client, apikey: String) {
        self.client = client
        self.apikey = apikey
    }

    func getSchedualBetweenStations(
        from: String,
        to: String,
        transfers: Bool? = nil,
        date: String? = nil,
        transportTypes: String? = nil
    ) async throws -> SchedualBetweenStations {
        let response = try await client.getSchedualBetweenStations(
            query: .init(
                apikey: apikey,
                from: from,
                to: to,
                date: date,
                transport_types: transportTypes,
                transfers: transfers
            )
        )
        return try response.ok.body.json
    }
}
