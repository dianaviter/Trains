//
//  CarrierListViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation

// MARK: - Модель рейса
struct Carrier: Identifiable {
    let id = UUID()
    let logo: String
    let date: String
    let transferNote: String?
    let departure: String
    let duration: String
    let arrival: String
    let departureTimeCategory: DepartureTime
}

// MARK: - Сетевой слой (абстракция)
protocol CarrierAPI {
    func fetchCarriers(from: String, to: String) async throws -> [Carrier]
}

struct MockCarrierAPI: CarrierAPI {
    func fetchCarriers(from: String, to: String) async throws -> [Carrier] {
        try await Task.sleep(nanoseconds: 150_000_000)
        return [
            Carrier(logo: "rzd",  date: "14 января", transferNote: "С пересадкой в Костроме", departure: "22:30", duration: "20 часов", arrival: "08:15", departureTimeCategory: .evening),
            Carrier(logo: "fgk",  date: "15 января", transferNote: nil,                           departure: "01:15", duration: "9 часов",  arrival: "09:00", departureTimeCategory: .night),
            Carrier(logo: "uralLogistics", date: "16 января", transferNote: nil,                  departure: "12:30", duration: "9 часов",  arrival: "21:00", departureTimeCategory: .day),
            Carrier(logo: "rzd",  date: "17 января", transferNote: "С пересадкой в Костроме",     departure: "22:30", duration: "20 часов", arrival: "08:15", departureTimeCategory: .evening),
            Carrier(logo: "uralLogistics", date: "16 января", transferNote: nil,                  departure: "12:30", duration: "9 часов",  arrival: "21:00", departureTimeCategory: .day)
        ]
    }
}

@MainActor
final class CarrierListViewModel: ObservableObject {

    let fromText: String
    let toText: String

    @Published var showFilters = false
    @Published var allCarriers: [Carrier] = []
    @Published var filteredCarriers: [Carrier] = []

    @Published var currentSelectedTimes: Set<DepartureTime> = []
    @Published var currentShowTransfers: Bool?

    @Published var selectedCarrier: CarrierDetails?

    private let api: CarrierAPI

    init(fromText: String, toText: String, api: CarrierAPI = MockCarrierAPI()) {
        self.fromText = fromText
        self.toText = toText
        self.api = api
    }

    // MARK: - Жизненный цикл
    func onAppear() {
        if allCarriers.isEmpty {
            Task { await loadCarriers() }
        } else {
            applyFilters(times: currentSelectedTimes, transfers: currentShowTransfers)
        }
    }

    // MARK: - Действия UI
    func openFilters() { showFilters = true }

    func applyFilters(times: Set<DepartureTime>, transfers: Bool?) {
        currentSelectedTimes = times
        currentShowTransfers = transfers

        filteredCarriers = allCarriers.filter { carrier in
            let timeOK = times.isEmpty || times.contains(carrier.departureTimeCategory)
            let transfersOK = transfers == nil || (transfers! == (carrier.transferNote != nil))
            return timeOK && transfersOK
        }
    }

    func didSelectCarrier(withLogo logo: String) {
        selectedCarrier = details(for: logo)
    }

    // MARK: - Загрузка
    private func loadCarriers() async {
        do {
            let list = try await api.fetchCarriers(from: fromText, to: toText)
            self.allCarriers = list
            self.filteredCarriers = list
            if !currentSelectedTimes.isEmpty || currentShowTransfers != nil {
                applyFilters(times: currentSelectedTimes, transfers: currentShowTransfers)
            }
        } catch {
            self.allCarriers = []
            self.filteredCarriers = []
        }
    }

    // MARK: - Маппер логотип → карточка
    private func details(for logo: String) -> CarrierDetails {
        switch logo {
        case "rzd":
            return CarrierDetails(
                name: "ОАО «РЖД»",
                logoImageName: "rzdHighRes",
                email: "i.lozgkina@yandex.ru",
                phone: "+7 (904) 329-27-71"
            )
        case "fgk":
            return CarrierDetails(name: "ФГК", logoImageName: "fgk", email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        case "uralLogistics":
            return CarrierDetails(name: "Урал логистика", logoImageName: "uralLogistics", email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        default:
            return CarrierDetails(name: "Перевозчик", logoImageName: logo, email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        }
    }
}
