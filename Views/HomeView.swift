//
//  HomeView.swift
//  Trains
//
//  Created by Diana Viter on 03.08.2025.
//

import SwiftUI
import OpenAPIURLSession

private extension String {
    var norm: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
    }
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    private let stationAPI: any StationAPI
    private let carrierAPI: any CarrierAPI

    init() {
        let client = Client(
            serverURL: try! Servers.Server1.url(),
            transport: URLSessionTransport()
        )

        let allStationsService = AllStationsService(
            client: client,
            apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
        )
        let directory = AllStationsDirectory(service: allStationsService)
        self.stationAPI = RealStationAPI(directory: directory)

        let scheduleService = SchedualBetweenStationsService(
            client: client,
            apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
        )
        self.carrierAPI = RealCarrierAPI(scheduleService: scheduleService)
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 44) {
                        StoriesStrip(
                            stories: Binding(get: { vm.stories }, set: { vm.stories = $0 }),
                            onSelect: { vm.tapStory(at: $0) }
                        )
                        .padding(.top)

                        let fromDisplay = displayText(city: vm.selectedFromCity, stationTitle: vm.fromSelected?.title)
                        let toDisplay   = displayText(city: vm.selectedToCity,   stationTitle: vm.toSelected?.title)

                        HStack {
                            VStack(spacing: 0) {
                                Button { vm.startSelectingFrom() } label: {
                                    HStack {
                                        Text(fromDisplay ?? (vm.fromText.isEmpty ? "Откуда" : vm.fromText))
                                            .foregroundColor((fromDisplay == nil && vm.fromText.isEmpty) ? .gray : .black)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                }

                                Button { vm.startSelectingTo() } label: {
                                    HStack {
                                        Text(toDisplay ?? (vm.toText.isEmpty ? "Куда" : vm.toText))
                                            .foregroundColor((toDisplay == nil && vm.toText.isEmpty) ? .gray : .black)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding()

                            Button { vm.swapDirections() } label: {
                                Image("Change direction")
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            .padding(.trailing, 16)
                        }
                        .background(Color.trainsBlue)
                        .cornerRadius(30)
                        .padding(.horizontal)

                        if !vm.fromText.isEmpty && !vm.toText.isEmpty {
                            Button("Найти") { vm.searchCarriers() }
                                .frame(width: 150, height: 60)
                                .foregroundColor(.white)
                                .background(Color.trainsBlue)
                                .cornerRadius(16)
                                .font(.headline)
                                .padding(.top, -32)
                        }
                    }
                    .padding(.bottom, 32)
                }

                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)

            .navigationDestination(
                isPresented: Binding(get: { vm.isSelectingFrom }, set: { vm.isSelectingFrom = $0 })
            ) {
                CitySelectionView { vm.selectFromCity($0) }
                    .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(get: { vm.isSelectingFromStation }, set: { vm.isSelectingFromStation = $0 })
            ) {
                StationSelectionView(
                    city: vm.selectedFromCity.isEmpty ? "Москва" : vm.selectedFromCity,
                    api: stationAPI
                ) { vm.selectFromStation($0) }
                .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(get: { vm.isSelectingTo }, set: { vm.isSelectingTo = $0 })
            ) {
                CitySelectionView { vm.selectToCity($0) }
                    .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(get: { vm.isSelectingToStation }, set: { vm.isSelectingToStation = $0 })
            ) {
                StationSelectionView(
                    city: vm.selectedToCity.isEmpty ? "Москва" : vm.selectedToCity,
                    api: stationAPI
                ) { vm.selectToStation($0) }
                .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(get: { vm.isShowingCarriers }, set: { vm.isShowingCarriers = $0 })
            ) {
                CarrierListView(
                    fromText: vm.fromText,
                    toText: vm.toText,
                    fromKey: .init(station: vm.fromSelected?.code, settlement: vm.fromSelected?.settlementCode),
                    toKey:   .init(station: vm.toSelected?.code,   settlement: vm.toSelected?.settlementCode),
                    api: carrierAPI
                )
                .toolbar(.hidden, for: .tabBar)
            }

            .fullScreenCover(
                isPresented: Binding(get: { vm.showStories }, set: { vm.showStories = $0 })
            ) {
                StoriesViewer(
                    stories: Binding(get: { vm.stories }, set: { vm.stories = $0 }),
                    currentIndex: Binding(get: { vm.currentStoryIndex }, set: { vm.currentStoryIndex = $0 })
                )
                .ignoresSafeArea()
            }
        }
        .task { await vm.loadStories() }
    }

    /// Гарантированно отдаёт «Город (Станция)»,
    /// в т.ч. когда stationTitle уже вида «Город (Что-то)».
    private func displayText(city rawCity: String, stationTitle rawStation: String?) -> String? {
        let city = rawCity.trimmed()
        let st = (rawStation ?? "").trimmed()
        if city.isEmpty && st.isEmpty { return nil }
        if city.isEmpty { return st }
        if st.isEmpty { return city }

        if let l = st.firstIndex(of: "("), let r = st.lastIndex(of: ")"), l < r {
            let prefix = String(st[..<l]).trimmed()
            let inside = String(st[st.index(after: l)..<r]).trimmed()
            if prefix.norm == city.norm, !inside.isEmpty {
                return "\(city) (\(inside))"
            }
        }
        return "\(city) (\(st))"
    }
}

#Preview { HomeView() }
