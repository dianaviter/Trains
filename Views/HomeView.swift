//
//  HomeView.swift
//  Trains
//
//  Created by Diana Viter on 03.08.2025.
//

import SwiftUI
import OpenAPIURLSession

// MARK: - Helpers for display

private extension String {
    func removingTrailingParentheses() -> String {
        var result = self
        while let range = result.range(of: #"\s*\([^()]*\)$"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedForCompare: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
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
                            stories: Binding(
                                get: { vm.stories },
                                set: { vm.stories = $0 }
                            ),
                            onSelect: { index in vm.tapStory(at: index) }
                        )
                        .padding(.top)

                        HStack {
                                VStack(spacing: 0) {
                                    // "Откуда"
                                    Button {
                                        vm.startSelectingFrom()
                                    } label: {
                                        HStack {
                                            Text(vm.fromText.isEmpty ? "Откуда" : vm.fromText)
                                                .foregroundColor(vm.fromText.isEmpty ? .gray : .black)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.white)
                                    }

                                    // "Куда"
                                    Button {
                                        vm.startSelectingTo()
                                    } label: {
                                        HStack {
                                            Text(vm.toText.isEmpty ? "Куда" : vm.toText)
                                                .foregroundColor(vm.toText.isEmpty ? .gray : .black)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.white)
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(20)
                                .padding()

                                Button {
                                    vm.swapDirections()
                                } label: {
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


                        // Кнопка "Найти" — логика без изменений
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

            // MARK: - Навигация (без изменений)

            .navigationDestination(
                isPresented: Binding(
                    get: { vm.isSelectingFrom },
                    set: { vm.isSelectingFrom = $0 }
                )
            ) {
                CitySelectionView { city in
                    vm.selectFromCity(city)
                }
                .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(
                    get: { vm.isSelectingFromStation },
                    set: { vm.isSelectingFromStation = $0 }
                )
            ) {
                StationSelectionView(
                    city: vm.selectedFromCity.isEmpty ? "Москва" : vm.selectedFromCity,
                    api: stationAPI
                ) { s in
                    vm.selectFromStation(s)
                }
                .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(
                    get: { vm.isSelectingTo },
                    set: { vm.isSelectingTo = $0 }
                )
            ) {
                CitySelectionView { city in
                    vm.selectToCity(city)
                }
                .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(
                    get: { vm.isSelectingToStation },
                    set: { vm.isSelectingToStation = $0 }
                )
            ) {
                StationSelectionView(
                    city: vm.selectedToCity.isEmpty ? "Москва" : vm.selectedToCity,
                    api: stationAPI
                ) { s in
                    vm.selectToStation(s)
                }
                .toolbar(.hidden, for: .tabBar)
            }

            .navigationDestination(
                isPresented: Binding(
                    get: { vm.isShowingCarriers },
                    set: { vm.isShowingCarriers = $0 }
                )
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
                isPresented: Binding(
                    get: { vm.showStories },
                    set: { vm.showStories = $0 }
                )
            ) {
                StoriesViewer(
                    stories: Binding(
                        get: { vm.stories },
                        set: { vm.stories = $0 }
                    ),
                    currentIndex: Binding(
                        get: { vm.currentStoryIndex },
                        set: { vm.currentStoryIndex = $0 }
                    )
                )
                .ignoresSafeArea()
            }
        }
        .task { await vm.loadStories() }
    }
}

#Preview { HomeView() }
