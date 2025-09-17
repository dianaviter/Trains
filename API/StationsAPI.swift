
import Foundation

struct StationRef: Hashable, Identifiable {
    var id: String { code }
    let title: String           // показываем в UI
    let code: String            // station yandex_code / code
    let city: String            // название поселения (для UI)
    let settlementCode: String? // <-- ДОБАВИЛИ: код поселения (город)
}

protocol StationAPI {
    func railStations(in city: String) async throws -> [StationRef]
    func suggest(in city: String, query: String) async throws -> [StationRef]
}

actor AllStationsDirectory {
    private let service: AllStationsProtocol
    private var cached: AllStations?

    init(service: AllStationsProtocol) { self.service = service }

    func getAll() async throws -> AllStations {
        if let cached { return cached }
        let all = try await service.getAllStations()
        cached = all
        return all
    }
}

struct RealStationAPI: StationAPI {
    let directory: AllStationsDirectory

    func railStations(in city: String) async throws -> [StationRef] {
        let all = try await directory.getAll()
        guard let ru = (all.countries ?? []).first(where: {
            let t = ($0.title ?? "").lowercased()
            return t.contains("россия") || t.contains("russia")
        }) else { return [] }

        let coverage = cityCoverage(for: city)
        var out = Set<StationRef>()

        for region in ru.regions ?? [] {
            for settlement in region.settlements ?? [] {
                let stl = normalize(settlement.title ?? "")
                guard coverage.contains(where: { fuzzyMatch($0, stl) }) else { continue }

                for st in settlement.stations ?? [] {
                    guard isRailStation(st) else { continue }
                    let code = st.codes?.yandex_code ?? st.code ?? ""
                    guard !code.isEmpty else { continue }

                    let title = makeDisplayName(station: st, settlement: settlement, cityKey: coverage.first ?? "")
                    let settlementCode = settlement.codes?.yandex_code
                    out.insert(.init(title: title,
                                     code: code,
                                     city: settlement.title ?? "",
                                     settlementCode: settlementCode))
                }
            }
        }

        return out.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func suggest(in city: String, query: String) async throws -> [StationRef] {
        let base = try await railStations(in: city)
        let q = normalize(query)
        guard !q.isEmpty else { return base }
        return base.filter { normalize($0.title).contains(q) }
    }

    // MARK: helpers

    private func makeDisplayName(station st: Components.Schemas.Station,
                                 settlement: Components.Schemas.Settlement,
                                 cityKey: String) -> String {
        let name = (st.title ?? st.popular_title ?? st.short_title ?? "").trimmed()
        var title = name

        // Если это не сам «город-запрос», добавим район в скобках
        if normalize(settlement.title ?? "") != cityKey {
            let town = (settlement.title ?? "").trimmed()
            if !town.isEmpty, !title.localizedCaseInsensitiveContains(town) {
                title += " (\(town))"
            }
        }
        return title
    }

    private func isRailStation(_ st: Components.Schemas.Station) -> Bool {
        let tr = (st.transport_type ?? "").lowercased()
        let stt = (st.station_type ?? "").lowercased()

        if stt.contains("bus") || stt.contains("underground") || stt.contains("metro")
            || stt.contains("trolley") || stt.contains("tram")
            || stt.contains("river") || stt.contains("sea") { return false }

        if tr == "train" || tr == "suburban" { return true }
        return stt.contains("train") || stt.contains("rail") || stt.contains("platform")
    }

    private func cityCoverage(for rawCity: String) -> [String] {
        let key = normalize(rawCity)
        // Можно расширять, это только примеры
        let map: [String: [String]] = [
            "москва": ["москва","внуково","домодедово","шереметьево","химки","лобня","битца","царицыно"],
            "санкт-петербург": ["санкт-петербург","санкт петербург","пулково"]
        ]
        return Array(Set([key] + (map[key] ?? []))).map(normalize)
    }

    private func normalize(_ s: String) -> String {
        var t = s.folding(options: [.diacriticInsensitive, .caseInsensitive],
                          locale: Locale(identifier: "ru_RU"))
        t = t.replacingOccurrences(of: "ё", with: "е")
             .replacingOccurrences(of: "–", with: "-")
             .replacingOccurrences(of: "—", with: "-")
             .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private func fuzzyMatch(_ a: String, _ b: String) -> Bool {
        let x = normalize(a), y = normalize(b)
        return x == y || x.contains(y) || y.contains(x)
    }
}

private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
