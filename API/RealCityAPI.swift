//
//  RealCityAPI.swift
//  Trains
//
//  Created by Diana Viter on 18.08.2025.
//

import Foundation
import OpenAPIRuntime

actor RealCityAPI: CityAPI {
    
    private let service: AllStationsProtocol
    private var cachedCities: [City]? = nil
    
    init(service: AllStationsProtocol) {
        self.service = service
    }
    
    func fetchCities(matching query: String) async throws -> [City] {
        if cachedCities == nil {
            let payload = try await service.getAllStations()
            cachedCities = Self.extractCities(from: payload)
        }
        
        let all = cachedCities ?? []
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        
        return all.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    
    private static func extractCities(from allStations: AllStations) -> [City] {
        var names = Set<String>()
        
        let countries: [Components.Schemas.Country] =
        (allStations.countries) ?? []
        
        let russianCountries = countries.filter { country in
            let title = (country.title ?? "").lowercased()
            return title.contains("росси") || title.contains("russia")
        }
        
        for country in russianCountries {
            let regions: [Components.Schemas.Region] =
            (country.regions) ?? []
            
            for region in regions {
                let settlements: [Components.Schemas.Settlement] =
                (region.settlements) ?? []
                
                for settlement in settlements {
                    if let title = settlement.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !title.isEmpty {
                        names.insert(title)
                    }
                }
            }
        }
        
        return names
            .map { City(name: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}


