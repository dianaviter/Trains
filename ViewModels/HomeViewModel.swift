//
//  File.swift
//  Trains
//
//  Created by Diana Viter on 16.08.2025.
//

import Foundation
import SwiftUI

protocol HomeAPI: Sendable {
    func fetchStories() async throws -> [Story]
}

struct MockHomeAPI: HomeAPI {
    func fetchStories() async throws -> [Story] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return [
            .init(imageName: "stories1", isViewed: false),
            .init(imageName: "stories2", isViewed: false),
            .init(imageName: "stories3", isViewed: false),
            .init(imageName: "stories4", isViewed: false)
        ]
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var fromText: String = ""
    @Published var toText: String = ""
    @Published var selectedFromCity: String = ""
    @Published var selectedToCity: String = ""
    @Published var fromSelected: StationRef?
    @Published var toSelected: StationRef?
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

    private let api: HomeAPI

    init(api: HomeAPI = MockHomeAPI()) {
        self.api = api
    }

    func startSelectingFrom() { isSelectingFrom = true }
    func startSelectingTo() { isSelectingTo = true }

    func selectFromCity(_ city: String) {
        selectedFromCity = city
        isSelectingFrom = false
        isSelectingFromStation = true
    }

    func selectToCity(_ city: String) {
        selectedToCity = city
        isSelectingTo = false
        isSelectingToStation = true
    }

    func selectFromStation(_ s: StationRef) {
        fromSelected = s
        selectedFromCity = s.city.isEmpty ? selectedFromCity : s.city
        fromText = formatted(city: selectedFromCity, stationTitle: s.title)
        isSelectingFromStation = false
    }

    func selectToStation(_ s: StationRef) {
        toSelected = s
        selectedToCity = s.city.isEmpty ? selectedToCity : s.city
        toText = formatted(city: selectedToCity, stationTitle: s.title)
        isSelectingToStation = false
    }

    func selectFromStation(_ station: String) {
        fromSelected = nil
        fromText = formatted(city: selectedFromCity, stationTitle: station)
        isSelectingFromStation = false
    }

    func selectToStation(_ station: String) {
        toSelected = nil
        toText = formatted(city: selectedToCity, stationTitle: station)
        isSelectingToStation = false
    }

    func swapDirections() {
        swap(&selectedFromCity, &selectedToCity)
        swap(&fromSelected, &toSelected)
        swap(&fromCode, &toCode)

        fromText = formatted(city: selectedFromCity, stationTitle: fromSelected?.title)
        toText = formatted(city: selectedToCity, stationTitle: toSelected?.title)
    }

    func searchCarriers() {
        guard !fromText.isEmpty, !toText.isEmpty else { return }
        isShowingCarriers = true
    }

    func tapStory(at index: Int) {
        currentStoryIndex = index
        showStories = true
    }

    func loadStories() async {
        do {
            let items = try await api.fetchStories()
            stories = items
        } catch {
            stories = []
        }
    }
}

private extension HomeViewModel {
    func formatted(city: String, stationTitle: String?) -> String {
        let cityTrim = city.trimmingCharacters(in: .whitespacesAndNewlines)
        var st = (stationTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
