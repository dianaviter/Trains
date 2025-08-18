//
//  File.swift
//  Trains
//
//  Created by Diana Viter on 16.08.2025.
//

import Foundation

// MARK: - Модель
struct City: Identifiable, Hashable {
    var id: String { name }
    let name: String
}

// MARK: - Сетевой слой (абстракция)
protocol CityAPI {
    func fetchCities(matching query: String) async throws -> [City]
}

struct MockCityAPI: CityAPI {
    private let all: [City] = [
        .init(name: "Москва"),
        .init(name: "Санкт Петербург"),
        .init(name: "Сочи"),
        .init(name: "Горный воздух"),
        .init(name: "Краснодар"),
        .init(name: "Казань"),
        .init(name: "Омск"),
    ]

    func fetchCities(matching query: String) async throws -> [City] {
        try await Task.sleep(nanoseconds: 180_000_000)
        try Task.checkCancellation()

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }
}

// MARK: - ViewModel (UI не меняем)
@MainActor
final class CitySelectionViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var cities: [City] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let api: CityAPI
    private var searchTask: Task<Void, Never>? = nil

    init(api: CityAPI = MockCityAPI()) {
        self.api = api
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Жизненный цикл
    func onAppear() {
        if cities.isEmpty {
            searchImmediately(query: "")
        }
    }

    // MARK: - Интенты
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
            } catch {
            }
        }
    }

    private func searchImmediately(query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.search(query: query)
        }
    }

    private func search(query: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await api.fetchCities(matching: query)
            try Task.checkCancellation()
            self.cities = result
        } catch is CancellationError {
            return
        } catch {
            self.cities = []
            self.errorMessage = mapErrorMessage(error)
        }
    }

    // MARK: - Маппинг ошибок в человеко-читаемое сообщение (без изменения UI)
    private func mapErrorMessage(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost,
                 .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "Нет интернета"
            default:
                break
            }
        }
        if let http = error as? HTTPError, (500...599).contains(http.statusCode) {
            return "Ошибка сервера"
        }
        return "Не удалось загрузить города. Повторите попытку."
    }

    struct HTTPError: Error {
        let statusCode: Int
        let data: Data?
    }
}
