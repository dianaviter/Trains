//
//  StationSelectionView.swift
//  Trains
//
//  Created by Diana Viter on 05.08.2025.
//

import SwiftUI

private extension String {
    func removingTrailingParentheses() -> String {
        var result = self
        while let range = result.range(of: #"\s*\([^()]*\)$"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct StationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: StationSelectionViewModel

    private let city: String
    private let onSelect: (StationRef) -> Void
    private let api: any StationAPI

    init(city: String,
         api: any StationAPI,
         onSelect: @escaping (StationRef) -> Void) {
        self.city = city
        self.api = api
        self.onSelect = onSelect
        _vm = StateObject(wrappedValue: StationSelectionViewModel(city: city, api: api))
    }

    var body: some View {
        List {
            if vm.isLoading {
                VStack(spacing: 12) {
                    Spacer().frame(height: 160)
                    ProgressView()
                    Text("Ищем станции…")
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
            } else if vm.stations.isEmpty {
                VStack(spacing: 0) {
                    Spacer().frame(height: 176)
                    Text("Станции не найдены")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.trainsBlack)
                        .frame(maxWidth: .infinity)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(vm.stations) { st in
                    Button {
                        onSelect(st)
                    } label: {
                        HStack {
                            Text(st.title.removingTrailingParentheses())
                                .foregroundColor(.trainsBlack)
                                .padding(.vertical, 10)
                            Spacer(minLength: 8)
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
                Text("Выбор станции")
                    .font(.headline)
                    .foregroundColor(.trainsBlack)
            }
        }
        .onAppear { vm.onAppear() }
    }
}

//#Preview {
//    StationSelectionView(city: "Москва",
//                         api: MockStationAPI(),
//                         onSelect: { _ in })
//}
