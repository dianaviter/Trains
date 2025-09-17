
import Foundation
import OpenAPIRuntime

struct RealCarrierAPI: CarrierAPI {
    let scheduleService: SchedualBetweenStationsService

    /// Новый «прямой» метод — принимает коды.
    func fetchCarriers(fromCode: String, toCode: String, dateYMD: String? = nil) async throws -> [Carrier] {
        let segs = try await searchSegments(from: fromCode, to: toCode, dateYMD: dateYMD)
        guard !segs.isEmpty else {
            throw NSError(domain: "RealCarrierAPI", code: 11,
                          userInfo: [NSLocalizedDescriptionKey: "Нет рейсов по кодам \(fromCode) → \(toCode)."])
        }
        return segs.compactMap(mapCarrier)
    }

    // Сохраним старую сигнатуру на всякий случай — если где-то ещё передаются строки.
    func fetchCarriers(from: String, to: String) async throws -> [Carrier] {
        // 👉 РЕКОМЕНДАЦИЯ: перестать пользоваться этим методом и всегда
        // прокидывать fromCode/toCode из селектора станций.
        throw NSError(domain: "RealCarrierAPI", code: 9001,
                      userInfo: [NSLocalizedDescriptionKey: "Передавайте коды станций, а не строки."])
    }

    // MARK: network

    private func searchSegments(from: String, to: String, dateYMD: String?) async throws -> [Components.Schemas.Segment] {
        func call(transfers: Bool?, date: String?) async throws -> [Components.Schemas.Segment] {
            let box = try await scheduleService.getSchedualBetweenStations(
                from: from, to: to, transfers: transfers, date: date, transportTypes: "train,suburban"
            )
            let segs  = box.segments ?? []
            let ivals = box.interval_segments ?? []

            if segs.isEmpty, !ivals.isEmpty {
                return ivals.map {
                    Components.Schemas.Segment(
                        from: $0.from,
                        to: $0.to,
                        departure: $0.interval?.begin_time,
                        arrival:   $0.interval?.end_time,
                        thread:    $0.thread,
                        tickets_info: nil,
                        duration: nil
                    )
                }
            }
            return segs
        }

        // быстрые варианты: без пересадок → с пересадками, с датой → без
        if let d = dateYMD ?? todayYMD() as String? {
            if let r = try? await call(transfers: false, date: d), !r.isEmpty { return r }
            if let r = try? await call(transfers: true,  date: d), !r.isEmpty { return r }
        }
        if let r = try? await call(transfers: false, date: nil), !r.isEmpty { return r }
        if let r = try? await call(transfers: true,  date: nil), !r.isEmpty { return r }
        if let r = try? await call(transfers: nil,   date: dateYMD ?? todayYMD()), !r.isEmpty { return r }
        return try await call(transfers: nil, date: nil)
    }

    // MARK: mapping

    private func mapCarrier(_ seg: Components.Schemas.Segment) -> Carrier? {
        guard
            let thread = seg.thread,
            let depISO = seg.departure,
            let arrISO = seg.arrival
        else { return nil }

        let transferNote: String? = {
            if let mirror = try? JSONSerialization.jsonObject(with: (try? JSONEncoder().encode(seg)) ?? Data()) as? [String: Any],
               let hasTransfers = mirror["has_transfers"] as? Bool, hasTransfers {
                return "С пересадкой"
            }
            return nil
        }()

        return Carrier(
            logo: carrierLogo(from: thread),
            date: dateText(from: depISO),
            transferNote: transferNote,
            departure: timeText(from: depISO),
            duration: durationText(seconds: seg.duration, depISO: depISO, arrISO: arrISO),
            arrival: timeText(from: arrISO),
            departureTimeCategory: departureCategory(fromRaw: depISO)
        )
    }
}

// MARK: - Helpers (dates, formatting, logos)

private extension RealCarrierAPI {

    // yyyy-MM-dd для параметра date
    func todayYMD() -> String {
        let df = DateFormatter()
        df.calendar = .init(identifier: .gregorian)
        df.timeZone = .current
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    // Парсинг ISO-дат (с/без миллисекунд) + несколько запасных форматов
    var iso: ISO8601DateFormatter { ISO8601DateFormatter() }
    var isoFrac: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }
    func parseDate(_ s: String?) -> Date? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if let d = iso.date(from: s) ?? isoFrac.date(from: s) { return d }

        let fmts = [
            "yyyy-MM-dd'T'HH:mmXXXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.timeZone = .current
        for f in fmts {
            df.dateFormat = f
            if let d = df.date(from: s) { return d }
        }
        return nil
    }

    // Форматтеры
    var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }
    var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM"
        return f
    }

    // Текст «HH:mm» из строки-датЫ
    func timeText(from s: String) -> String {
        if let d = parseDate(s) { return timeFormatter.string(from: d) }
        if let r = s.range(of: #"\b\d{2}:\d{2}\b"#, options: .regularExpression) {
            return String(s[r])
        }
        return "—:—"
    }

    // Текст «22 августа» из строки-датЫ
    func dateText(from s: String) -> String {
        if let d = parseDate(s) { return dayFormatter.string(from: d) }
        return ""
    }

    // «X ч Y мин» — сначала по seconds, если нет — по разнице ISO
    func durationText(seconds: Int?, depISO: String, arrISO: String) -> String {
        if let s = seconds, s > 0 {
            let h = s / 3600, m = (s % 3600) / 60
            var parts: [String] = []
            if h > 0 { parts.append("\(h) ч") }
            if m > 0 { parts.append("\(m) мин") }
            return parts.joined(separator: " ")
        }
        if let d = parseDate(depISO), let a = parseDate(arrISO) {
            let s = Int(a.timeIntervalSince(d))
            let h = s / 3600, m = (s % 3600) / 60
            var parts: [String] = []
            if h > 0 { parts.append("\(h) ч") }
            if m > 0 { parts.append("\(m) мин") }
            return parts.joined(separator: " ")
        }
        return ""
    }

    // Категория времени отправления (ночь/утро/день/вечер)
    func departureCategory(from date: Date?) -> DepartureTime {
        guard let date else { return .day }
        switch Calendar.current.component(.hour, from: date) {
        case 0..<6:   return .night
        case 6..<12:  return .morning
        case 12..<18: return .day
        default:      return .evening
        }
    }
    func departureCategory(fromRaw s: String) -> DepartureTime {
        if let d = parseDate(s) { return departureCategory(from: d) }
        if let h = Int(timeText(from: s).prefix(2)) {
            switch h {
            case 0..<6:   return .night
            case 6..<12:  return .morning
            case 12..<18: return .day
            default:      return .evening
            }
        }
        return .day
    }

    // Лого перевозчика
    func carrierLogo(from thread: Components.Schemas.Thread?) -> String {
        let title = (thread?.carrier?.title ?? "").lowercased()
        let trans = (thread?.transport_type ?? "").lowercased()
        let iata  = (thread?.carrier?.codes?.iata ?? "").lowercased()

        if title.contains("ржд") || title.contains("rzd") { return "rzd" }
        if title.contains("фпк") || title.contains("цппк") || title.contains("мосгортранс") { return "rzd" }
        if iata == "f7" { return "fgk" } // пример
        if trans == "train" || trans == "suburban" { return "rzd" }
        return "uralLogistics"
    }
}

