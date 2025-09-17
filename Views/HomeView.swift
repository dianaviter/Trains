//
//  HomeView.swift
//  Trains
//
//  Created by Diana Viter on 03.08.2025.
//

import SwiftUI
import OpenAPIURLSession

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    // Справочник станций
    private let stationAPI: any StationAPI
    // Реальный API расписания по кодам
    private let carrierAPI: any CarrierAPI

    init() {
        // Общий клиент OpenAPI
        let client = Client(
            serverURL: try! Servers.Server1.url(),
            transport: URLSessionTransport()
        )

        // Станции (справочник)
        let allStationsService = AllStationsService(
            client: client,
            apikey: "6c4d43ec-59a3-4873-9f08-d227b0d3c9ed"
        )
        let directory = AllStationsDirectory(service: allStationsService)
        self.stationAPI = RealStationAPI(directory: directory)

        // Расписание между станциями (по кодам)
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
                                Button {
                                    vm.startSelectingFrom()
                                } label: {
                                    HStack {
                                        Text(vm.fromText.isEmpty ? "Откуда" : vm.fromText)
                                            .foregroundColor(vm.fromText.isEmpty ? .gray : .black)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .lineLimit(1)
                                }

                                Button {
                                    vm.startSelectingTo()
                                } label: {
                                    HStack {
                                        Text(vm.toText.isEmpty ? "Куда" : vm.toText)
                                            .foregroundColor(vm.toText.isEmpty ? .gray : .black)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .lineLimit(1)
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

            // MARK: - Навигация

            // Выбор города «Откуда»
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

            // Выбор станции «Откуда»
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

            // Выбор города «Куда»
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

            // Выбор станции «Куда»
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

            // Список рейсов
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

            // Stories
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
