//
//  ContentView.swift
//  Trains
//
//  Created by Diana Viter on 07.07.2025.
//

import SwiftUI
import OpenAPIURLSession

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            testFetchStations()
            testFetchCopyright()
            testFetchSchedualBetweenStations()
            testFetchStationSchedule()
            testFetchRouteStations()
            testFetchNearestCity()
            testFetchCarrierInfo()
            testFetchAllStations()
        }
    }
}

#Preview {
    ContentView()
}

func testFetchStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = NearestStationsService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching stations...")
            let stations = try await service.getNearestStations(
                lat: 59.864177,
                lng: 30.319163,
                distance: 50
            )
            
            print("Successfully fetched stations: \(stations)")
        } catch {
            print("Error fetching stations: \(error)")
        }
    }
}

func testFetchCopyright() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = CopyrightService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching copyright info...")
            let copyright = try await
            service.getCopyright()
            
            print("Successfully fetched copyright info: \(copyright)")
        } catch {
            print("Error fetching copyright info: \(error)")
        }
    }
}

func testFetchSchedualBetweenStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = SchedualBetweenStationsService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching SchedualBetweenStations info...")
            let schedualBetweenStations = try await
            service.getSchedualBetweenStations(
                from: "s9601349",
                to: "s9601666"
            )
            
            print("Successfully fetched SchedualBetweenStations info: \(schedualBetweenStations)")
        } catch {
            print("Error fetching schedule info: \(error)")
        }
    }
}


func testFetchStationSchedule() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = StationScheduleService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching StationSchedule info...")
            let stationSchedule = try await
            service.getStationSchedule(
                station: "s9600213")
            
            print("Successfully fetched StationSchedule info: \(stationSchedule)")
        } catch {
            print("Error fetching copyright info: \(error)")
        }
    }
}

func testFetchRouteStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = RouteStationsService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching RouteStations info...")
            let routeStations = try await
            service.getRouteStations(
                uid: "6316_0_9601368_g25_4")
            
            print("Successfully fetched routeStations info: \(routeStations)")
        } catch {
            print("Error fetching copyright info: \(error)")
        }
    }
}

func testFetchNearestCity() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = NearestCityService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching NearestCity info...")
            let nearestCity = try await
            service.getNearestCity(lat: 59.864177, lng: 30.319163)
            
            print("Successfully fetched NearestCity info: \(nearestCity)")
        } catch {
            print("Error fetching copyright info: \(error)")
        }
    }
}

func testFetchCarrierInfo() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = CarrierInfoService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching CarrierInfo info...")
            let carrierInfo = try await
            service.getCarrierInfo(code: "SU", system: "iata")
            
            print("Successfully fetched CarrierInfo info: \(carrierInfo)")
        } catch {
            print("Error fetching CarrierInfo info: \(error)")
        }
    }
}

func testFetchAllStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            
            let service = AllStationsService(
                client: client,
                apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
            )
            
            print("Fetching NearestCity info...")
            let allStations = try await
            service.getAllStations()
            
            print("Successfully fetched AllStations info: \(allStations)")
        } catch {
            print("Error fetching copyright info: \(error)")
        }
    }
}



