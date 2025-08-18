//
//  StationSelectionViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation

// MARK: - Сетевой слой (абстракция)
protocol StationAPI {
    func fetchStations(city: String, matching query: String) async throws -> [String]
}

struct MockStationAPI: StationAPI {
    private let data: [String: [String]] = [
        "Москва": ["Киевский вокзал", "Курский вокзал", "Ярославский вокзал", "Белорусский вокзал", "Савеловский вокзал", "Ленинградский вокзал"],
        "Санкт Петербург": ["Ладожский", "Московский"],
        "Казань": ["Казань-Пассажирская", "Казань-2"],
        "Сочи": ["Сочи-Пассажирский"],
        "Горный воздух": ["Центральная"],
        "Краснодар": ["Краснодар-1", "Краснодар-2"],
        "Омск": ["Омск-Пассажирский"]
    ]

    func fetchStations(city: String, matching query: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 150_000_000)
        try Task.checkCancellation()

        let all = data[city] ?? []
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(q) }
    }
}

// MARK: - ViewModel
@MainActor
final class StationSelectionViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var stations: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let city: String
    private let api: StationAPI
    private var searchTask: Task<Void, Never>? = nil

    init(city: String, api: StationAPI = MockStationAPI()) {
        self.city = city
        self.api = api
    }

    deinit { searchTask?.cancel() }

    func onAppear() {
        if stations.isEmpty {
            searchImmediately(query: "")
        }
    }

    func setSearchText(_ text: String) {
        searchText = text
        debounceSearch(query: text)
    }

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
                if Task.isCancelled { return }
                await self.search(query: query)
            } catch { }
        }
    }

    private func searchImmediately(query: String) {
        searchTask?.cancel()
        isLoading = true
        errorMessage = nil
        searchTask = Task { [weak self] in
        await self?.search(query: query)
        }
    }

    private func search(query: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let list = try await api.fetchStations(city: city, matching: query)
            try Task.checkCancellation()
            self.stations = list
        } catch is CancellationError {
            return
        } catch {
            self.stations = []
            if let urlErr = error as? URLError,
               [.notConnectedToInternet, .timedOut, .networkConnectionLost,
                .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed].contains(urlErr.code) {
                self.errorMessage = "Нет интернета"
            } else {
                self.errorMessage = "Не удалось загрузить станции"
            }
        }
    }
}
