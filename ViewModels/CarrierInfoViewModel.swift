//
//  CarrierInfoViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation


protocol CarrierDetailsAPI {
    func carrierDetails(for name: String) async throws -> CarrierDetails
}

struct MockCarrierDetailsAPI: CarrierDetailsAPI {
    func carrierDetails(for name: String) async throws -> CarrierDetails {
        try await Task.sleep(nanoseconds: 160_000_000)
        switch name {
        case "ОАО «РЖД»":
            return CarrierDetails(name: name, logoImageName: "rzdHighRes",
                                  email: "info@rzd.ru", phone: "+7 (800) 775-00-00")
        case "ФГК":
            return CarrierDetails(name: name, logoImageName: "fgk",
                                  email: "support@fgk.ru", phone: "+7 (495) 123-45-67")
        case "Урал логистика":
            return CarrierDetails(name: name, logoImageName: "uralLogistics",
                                  email: "support@fgk.ru", phone: "+7 (495) 123-45-67")
        default:
            return CarrierDetails(name: name, logoImageName: "carrier",
                                  email: nil, phone: nil)
        }
    }
}

@MainActor
final class CarrierDetailViewModel: ObservableObject {
    @Published var name: String
    @Published var logoImageName: String
    @Published var email: String?
    @Published var phone: String?

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let api: CarrierDetailsAPI
    private let lookupKey: String

    init(initial: CarrierDetails, api: CarrierDetailsAPI = MockCarrierDetailsAPI()) {
        self.api = api
        self.lookupKey = initial.name
        self.name = initial.name
        self.logoImageName = initial.logoImageName
        self.email = initial.email
        self.phone = initial.phone
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fresh = try await api.carrierDetails(for: lookupKey)
            self.name = fresh.name
            self.logoImageName = fresh.logoImageName
            self.email = fresh.email
            self.phone = fresh.phone
        } catch {
            self.errorMessage = "Не удалось загрузить информацию о перевозчике"
        }
    }
}
