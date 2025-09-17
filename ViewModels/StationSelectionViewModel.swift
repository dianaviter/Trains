//
//  StationSelectionViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation

@MainActor
final class StationSelectionViewModel: ObservableObject {
    // ввод пользователя
    @Published var searchText: String = ""

    // результат поиска — уже не [String], а [StationRef]
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

    // Привязано к .searchable
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
            let list: [StationRef]
            if trimmed.isEmpty {
                list = try await api.railStations(in: city)
            } else {
                list = try await api.suggest(in: city, query: trimmed)
            }

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
