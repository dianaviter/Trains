//
//  StationSelectionView.swift
//  Trains
//
//  Created by Diana Viter on 05.08.2025.
//

import SwiftUI

struct StationSelectionView: View {
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
        Group {
            if vm.isLoading {
                loadingView
            } else if let message = vm.errorMessage {
                errorView(message)
            } else if vm.stations.isEmpty {
                emptyView
            } else {
                stationsList
            }
        }
        .navigationTitle(city)
        .navigationBarTitleDisplayMode(.inline)
        .task { vm.onAppear() }
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: vm.searchText) { vm.setSearchText($0) }
    }
}

// MARK: - Subviews

private extension StationSelectionView {
    var loadingView: some View {
        List {
            VStack(spacing: 12) {
                Spacer().frame(height: 160)
                ProgressView()
                Text("Ищем станции…")
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    func errorView(_ message: String) -> some View {
        List {
            VStack(spacing: 12) {
                Spacer().frame(height: 160)
                Text(message).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    var emptyView: some View {
        List {
            VStack(spacing: 12) {
                Spacer().frame(height: 160)
                Text("Станции не найдены")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    var stationsList: some View {
        List(vm.stations) { st in
            Button {
                onSelect(st)
            } label: {
                HStack {
                    Text(st.title)
                    Spacer(minLength: 8)
                    // при отладке удобно видеть код
                    Text(st.code)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }
}

//
//#Preview {
//    StationSelectionView(city: "Москва") { selectedStation in
//        print("Selected station: \(selectedStation)")
//    }
//}
