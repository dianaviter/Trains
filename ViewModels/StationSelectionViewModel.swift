//
//  StationSelectionViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation

@MainActor
final class StationSelectionViewModel: ObservableObject {
    @Published var searchText: String = ""

    @Published var stations: [StationRef] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let city: String
    private let api: StationAPI
    private var searchTask: Task<Void, Never>? = nil

    init(city: String, api: StationAPI) {
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

    // MARK: - Поиск

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
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let result: [StationRef]
            if trimmed.isEmpty {
                let list = try await loadFullListForCity()
                result = list
            } else {
                result = try await api.suggest(in: city, query: trimmed)
            }

            try Task.checkCancellation()
            self.stations = sortStations(deduplicated(result))
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

    // MARK: - Helpers

    private func loadFullListForCity() async throws -> [StationRef] {
        async let baseA: [StationRef] = api.railStations(in: city)
        async let baseB: [StationRef] = (try? await api.suggest(in: city, query: "")) ?? []

        var combined = try await (baseA + baseB)

        let keywords = [
            "вокзал", "терминал", "станция", "пасс", "пасс.",
            "terminal", "station", "rail", "railway"
        ]
        for key in keywords {
            if let extra = try? await api.suggest(in: city, query: key) {
                combined.append(contentsOf: extra)
            }
        }
        return combined
    }

    private func deduplicated(_ items: [StationRef]) -> [StationRef] {
        var seenByCode  = Set<String>()
        var seenByTitle = Set<String>()
        var out: [StationRef] = []
        out.reserveCapacity(items.count)

        for s in items {
            let code = (s.code as String?) ?? ""
            if !code.isEmpty {
                if seenByCode.insert(code).inserted {
                    out.append(s)
                }
            } else {
                let key = s.title
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if seenByTitle.insert(key).inserted {
                    out.append(s)
                }
            }
        }
        return out
    }

    private func sortStations(_ items: [StationRef]) -> [StationRef] {
        items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
