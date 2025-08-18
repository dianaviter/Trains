//
//  CitySelectionView.swift
//  Trains
//
//  Created by Diana Viter on 04.08.2025.
//

import SwiftUI

struct CitySelectionView: View {
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CitySelectionViewModel()

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
