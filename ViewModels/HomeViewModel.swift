//
//  File.swift
//  Trains
//
//  Created by Diana Viter on 16.08.2025.
//

import Foundation
import SwiftUI

// MARK: - API (абстракция сетевого слоя)
protocol HomeAPI {
    func fetchStories() async throws -> [Story]
}

struct MockHomeAPI: HomeAPI {
    func fetchStories() async throws -> [Story] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return [
            .init(imageName: "stories1", isViewed: false),
            .init(imageName: "stories2", isViewed: false),
            .init(imageName: "stories3", isViewed: false),
            .init(imageName: "stories4", isViewed: false),
        ]
    }
}

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Ввод/вывод (публичные данные экрана)
    @Published var fromText: String = ""          // отображение в Home: "Город (Станция)"
    @Published var toText: String = ""            // отображение в Home: "Город (Станция)"

    @Published var selectedFromCity: String = ""  // выбранный город "Откуда"
    @Published var selectedToCity: String = ""    // выбранный город "Куда"

    @Published var fromSelected: StationRef?      // выбранная станция "Откуда"
    @Published var toSelected: StationRef?        // выбранная станция "Куда"

    @Published var fromCode: String?
    @Published var toCode: String?

    @Published var isSelectingFrom: Bool = false
    @Published var isSelectingTo: Bool = false
    @Published var isSelectingFromStation: Bool = false
    @Published var isSelectingToStation: Bool = false
    @Published var isShowingCarriers: Bool = false

    @Published var stories: [Story] = []
    @Published var showStories: Bool = false
    @Published var currentStoryIndex: Int = 0

    // MARK: - Зависимости
    private let api: HomeAPI

    // MARK: - Инициализация
    init(api: HomeAPI = MockHomeAPI()) {
        self.api = api
    }

    // MARK: - Интенции (действия UI)

    func startSelectingFrom() { isSelectingFrom = true }
    func startSelectingTo()   { isSelectingTo   = true }

    func selectFromCity(_ city: String) {
        selectedFromCity = city
        // открываем выбор станции
        isSelectingFrom = false
        isSelectingFromStation = true
    }

    func selectToCity(_ city: String) {
        selectedToCity = city
        isSelectingTo = false
        isSelectingToStation = true
    }

    /// Выбрали станцию "Откуда" (из StationSelectionView)
    func selectFromStation(_ s: StationRef) {
        fromSelected = s
        selectedFromCity = s.city.isEmpty ? selectedFromCity : s.city
        fromText = formatted(city: selectedFromCity, stationTitle: s.title)
        isSelectingFromStation = false
    }

    /// Выбрали станцию "Куда" (из StationSelectionView)
    func selectToStation(_ s: StationRef) {
        toSelected = s
        selectedToCity = s.city.isEmpty ? selectedToCity : s.city
        toText = formatted(city: selectedToCity, stationTitle: s.title)
        isSelectingToStation = false
    }

    /// Поддержка старого пути, если где-то зовётся через строку
    func selectFromStation(_ station: String) {
        fromSelected = nil
        fromText = formatted(city: selectedFromCity, stationTitle: station)
        isSelectingFromStation = false
    }

    /// Поддержка старого пути, если где-то зовётся через строку
    func selectToStation(_ station: String) {
        toSelected = nil
        toText = formatted(city: selectedToCity, stationTitle: station)
        isSelectingToStation = false
    }

    /// Поменять направления местами (город + станция), затем пересобрать тексты
    func swapDirections() {
        swap(&selectedFromCity, &selectedToCity)
        swap(&fromSelected, &toSelected)
        swap(&fromCode, &toCode)

        fromText = formatted(city: selectedFromCity, stationTitle: fromSelected?.title)
        toText   = formatted(city: selectedToCity,   stationTitle: toSelected?.title)
    }

    func searchCarriers() {
        guard !fromText.isEmpty, !toText.isEmpty else { return }
        isShowingCarriers = true
    }

    func tapStory(at index: Int) {
        currentStoryIndex = index
        showStories = true
    }

    // MARK: - Загрузка данных
    func loadStories() async {
        do {
            let items = try await api.fetchStories()
            self.stories = items
        } catch {
            self.stories = []
        }
    }
}

// MARK: - Приватная логика форматирования
private extension HomeViewModel {
    /// Формирует строку вида "Город (Станция)".
    /// - Если станция содержит хвосты в скобках — они обрезаются (например, "(МЦК)", "(Москва)").
    /// - Если город и станция совпадают — выводится один город.
    /// - Если чего-то нет — показывается то, что есть.
    func formatted(city: String, stationTitle: String?) -> String {
        let cityTrim = city.trimmingCharacters(in: .whitespacesAndNewlines)

        var st = (stationTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        // Срезаем все завершающие группы вида " (…)" у станции (например: "Андроновка (МЦК) (Москва)" -> "Андроновка")
        while let range = st.range(of: #"\s*\([^()]*\)$"#, options: .regularExpression) {
            st.removeSubrange(range)
        }
        let stTrim = st.trimmingCharacters(in: .whitespacesAndNewlines)

        if cityTrim.isEmpty && stTrim.isEmpty { return "" }
        if cityTrim.isEmpty { return stTrim }
        if stTrim.isEmpty || cityTrim.lowercased() == stTrim.lowercased() { return cityTrim }
        return "\(cityTrim) (\(stTrim))"
    }
}
