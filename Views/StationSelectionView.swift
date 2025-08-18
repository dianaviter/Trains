//
//  StationSelectionView.swift
//  Trains
//
//  Created by Diana Viter on 05.08.2025.
//

import SwiftUI

struct StationSelectionView: View {
    let city: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: StationSelectionViewModel

    init(city: String, onSelect: @escaping (String) -> Void) {
        self.city = city
        self.onSelect = onSelect
        _vm = StateObject(wrappedValue: StationSelectionViewModel(city: city))
    }

    var body: some View {
        List {
            if vm.stations.isEmpty && !vm.isLoading {
                VStack(spacing: 0) {
                    Spacer().frame(height: 100)
                    Text("Станция не найдена")
                        .font(.headline)
                        .foregroundColor(.trainsBlack)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(vm.stations, id: \.self) { station in
                    Button {
                        onSelect(station)
                    } label: {
                        HStack {
                            Text(station)
                                .foregroundColor(.trainsBlack)
                                .padding(.vertical, 10)
                                .font(.system(size: 17))
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
            prompt: "Введите станцию"
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.trainsBlack)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Выбор станции")
                    .font(.headline)
                    .foregroundColor(.trainsBlack)
            }
        }
        .onAppear { vm.onAppear() }
    }
}

#Preview {
    StationSelectionView(city: "Москва") { selectedStation in
        print("Selected station: \(selectedStation)")
    }
}
