//
//  CitySelectionView.swift
//  Trains
//
//  Created by Diana Viter on 04.08.2025.
//

import SwiftUI
import OpenAPIURLSession

struct CitySelectionView: View {
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: CitySelectionViewModel

    init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect

        let client = Client(
            serverURL: try! Servers.Server1.url(),
            transport: URLSessionTransport()
        )
        let service = AllStationsService(client: client, apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed")
        let api = RealCityAPI(service: service)

        _vm = StateObject(wrappedValue: CitySelectionViewModel(api: api))
    }

    var body: some View {
        List {
            if vm.isLoading {
                VStack(spacing: 12) {
                    Spacer().frame(height: 160)
                    ProgressView()
                    Text("Ищем города…")
                        .foregroundColor(.trainsBlack)
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if let message = vm.errorMessage {
                VStack(spacing: 12) {
                    Spacer().frame(height: 160)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.trainsBlack)
                    Button("Повторить") {
                        vm.setSearchText(vm.searchText)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if vm.cities.isEmpty {
                VStack(spacing: 0) {
                    Spacer().frame(height: 176)
                    Text("Город не найден")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.trainsBlack)
                        .frame(maxWidth: .infinity)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(vm.cities) { city in
                    Button {
                        onSelect(city.name)
                    } label: {
                        HStack {
                            Text(city.name)
                                .foregroundColor(.trainsBlack)
                                .padding(.vertical, 10)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.trainsBlack)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.clear)
        .scrollContentBackground(.hidden)
        .searchable(
            text: Binding(
                get: { vm.searchText },
                set: { vm.setSearchText($0) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Введите запрос"
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.trainsBlack)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Выбор города")
                    .font(.headline)
                    .foregroundColor(.trainsBlack)
            }
        }
        .onAppear { vm.onAppear() }
    }
}

#Preview {
    CitySelectionView { city in
        print("Selected city: \(city)")
    }
}
