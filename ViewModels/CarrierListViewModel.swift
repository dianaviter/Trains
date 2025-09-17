
import Foundation

struct PlaceKey {
    let station: String?
    let settlement: String?
}

struct Carrier: Identifiable, Hashable {
    let id = UUID()
    let logo: String
    let date: String
    let transferNote: String?   // "С пересадкой" если есть пересадки
    let departure: String       // "HH:mm"
    let duration: String        // "X ч Y мин"
    let arrival: String         // "HH:mm"
    let departureTimeCategory: DepartureTime
}

protocol CarrierAPI {
    func fetchCarriers(fromCode: String, toCode: String, dateYMD: String?) async throws -> [Carrier]
}

extension CarrierAPI {
    func fetchCarriers(fromCode: String, toCode: String) async throws -> [Carrier] {
        try await fetchCarriers(fromCode: fromCode, toCode: toCode, dateYMD: nil)
    }
}

@MainActor
final class CarrierListViewModel: ObservableObject {
    
    enum DepartureTime: String, CaseIterable, Hashable {
        case night, morning, day, evening
    }

    // Детали перевозчика при тапе по логотипу
    struct CarrierDetails: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let logoImageName: String
        let email: String
        let phone: String
    }

    // что показываем в шапке
    let fromText: String
    let toText: String

    // НОВОЕ: ключи для запросов
    let fromKey: PlaceKey
    let toKey: PlaceKey

    @Published var showFilters = false
    @Published var allCarriers: [Carrier] = []
    @Published var filteredCarriers: [Carrier] = []
    @Published var currentSelectedTimes: Set<Trains.DepartureTime> = []
    @Published var currentShowTransfers: Bool?
    @Published var selectedCarrier: Trains.CarrierDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: CarrierAPI

    init(fromText: String,
         toText: String,
         fromKey: PlaceKey,
         toKey: PlaceKey,
         api: CarrierAPI)
    {
        self.fromText = fromText
        self.toText = toText
        self.fromKey = fromKey
        self.toKey = toKey
        self.api = api
    }

    func onAppear() {
        if allCarriers.isEmpty { Task { await loadCarriers() } }
        else { applyFilters(times: currentSelectedTimes, transfers: currentShowTransfers) }
    }

    func openFilters() { showFilters = true }

    func applyFilters(times: Set<Trains.DepartureTime>, transfers: Bool?) {
        currentSelectedTimes = times
        currentShowTransfers = transfers

        filteredCarriers = allCarriers.filter { c in
            let timeOK = times.isEmpty || times.contains(c.departureTimeCategory)
            let transfersOK = transfers == nil || (transfers! == (c.transferNote != nil))
            return timeOK && transfersOK
        }
    }

    func didSelectCarrier(withLogo logo: String) {
        selectedCarrier = details(for: logo)
    }

    private func loadCarriers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Приоритет: код станции → код города (settlement)
            guard let fromCode = fromKey.station ?? fromKey.settlement,
                  let toCode   = toKey.station   ?? toKey.settlement
            else {
                self.allCarriers = []
                self.filteredCarriers = []
                self.errorMessage = "Не выбраны коды станций"
                return
            }

            // ⚡️ Сервер уже вернёт прямые И с пересадками.
            // Ничего не режем локально.
            let list = try await api.fetchCarriers(fromCode: fromCode, toCode: toCode)

            self.allCarriers = list
            if !currentSelectedTimes.isEmpty || currentShowTransfers != nil {
                applyFilters(times: currentSelectedTimes, transfers: currentShowTransfers)
            } else {
                self.filteredCarriers = list
            }
        } catch {
            self.allCarriers = []
            self.filteredCarriers = []
            if let urlErr = error as? URLError,
               [.notConnectedToInternet, .timedOut, .networkConnectionLost,
                .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed].contains(urlErr.code) {
                self.errorMessage = "Нет интернета"
            } else {
                self.errorMessage = "Не удалось загрузить рейсы"
            }
        }
    }

    private func details(for logo: String) -> Trains.CarrierDetails {
        switch logo {
        case "rzd":  return .init(name: "ОАО «РЖД»", logoImageName: "rzdHighRes", email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        case "fgk":  return .init(name: "ФГК",               logoImageName: "fgk",              email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        case "uralLogistics":
            return .init(name: "Урал логистика", logoImageName: "uralLogistics", email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        default:
            return .init(name: "Перевозчик", logoImageName: logo, email: "i.lozgkina@yandex.ru", phone: "+7 (904) 329-27-71")
        }
    }
}
