//
//  SettingsViewModel.swift
//  Trains
//
//  Created by Diana Viter on 16.08.2025.
//

import Foundation

protocol SettingsStore {
    var isDarkMode: Bool { get set }
}

final class UserDefaultsSettingsStore: SettingsStore {
    private let key = "isDarkMode"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [key: false])
    }

    var isDarkMode: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

enum SettingsRoute: Hashable {
    case userAgreement
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool
    @Published var route: SettingsRoute? = nil

    private var store: SettingsStore

    init(store: SettingsStore = UserDefaultsSettingsStore()) {
        self.store = store
        self.isDarkMode = store.isDarkMode
    }

    func toggleDarkMode(_ value: Bool) {
        Task { @MainActor in
            isDarkMode = value
            await saveDarkMode(value)
        }
    }

    func openAgreement() { route = .userAgreement }
    func closeRoute() { route = nil }

    func refreshSettings() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        isDarkMode = store.isDarkMode
    }

    private func saveDarkMode(_ value: Bool) async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        store.isDarkMode = value
    }
}
