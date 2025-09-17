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
    @Published var fromText: String = ""
    @Published var toText: String = ""

    @Published var selectedFromCity: String = ""
    @Published var selectedToCity: String = ""
    @Published var fromCode: String?
    @Published var toCode: String?
    @Published var fromSelected: StationRef?
    @Published var toSelected: StationRef?

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
        isSelectingFrom = false
        isSelectingFromStation = true
    }

    func selectFromStation(_ station: String) {
        fromText = "\(selectedFromCity) (\(station))"
        isSelectingFromStation = false
    }

    func selectToCity(_ city: String) {
        selectedToCity = city
        isSelectingTo = false
        isSelectingToStation = true
    }

    func selectToStation(_ station: String) {
        toText = "\(selectedToCity) (\(station))"
        isSelectingToStation = false
    }

    func swapDirections() {
        swap(&fromText, &toText)
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

extension HomeViewModel {
    func selectFromStation(_ s: StationRef) {
        fromSelected = s
        fromText = s.title
        selectedFromCity = s.city
        isSelectingFromStation = false
    }

    func selectToStation(_ s: StationRef) {
        toSelected = s
        toText = s.title
        selectedToCity = s.city
        isSelectingToStation = false
    }
}
