import SwiftUI

import SwiftUI

struct CarrierListView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: CarrierListViewModel

    private let fromDisplay: String
    private let toDisplay: String

    init(
        fromText: String,
        toText: String,
        fromKey: PlaceKey,
        toKey: PlaceKey,
        api: CarrierAPI,
        fromDisplay: String,
        toDisplay: String
    ) {
        _vm = StateObject(
            wrappedValue: CarrierListViewModel(
                fromText: fromText,
                toText: toText,
                fromKey: fromKey,
                toKey: toKey,
                api: api
            )
        )
        self.fromDisplay = fromDisplay
        self.toDisplay = toDisplay
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView { content }
            filterButton
        }
        .background(Color.trainsWhite)
        .navigationBarBackButtonHidden(true)
        .onAppear { vm.onAppear() }
        .navigationDestination(
            item: Binding(get: { vm.selectedCarrier }, set: { vm.selectedCarrier = $0 })
        ) { carrier in
            CarrierDetailView(carrier: carrier)
                .toolbar(.hidden, for: .tabBar)
        }
        .fullScreenCover(
            isPresented: Binding(get: { vm.showFilters }, set: { vm.showFilters = $0 })
        ) {
            FiltersView(
                initialSelectedTimes: vm.currentSelectedTimes,
                initialShowTransfers: vm.currentShowTransfers
            ) { selectedTimes, showTransfers in
                vm.applyFilters(times: selectedTimes, transfers: showTransfers)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.trainsBlack)
                        .imageScale(.large)
                }
                Spacer()
            }
            .padding(.bottom, 4)

            Text("\(fromDisplay) → \(toDisplay)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.trainsBlack)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
        .padding()
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 8) {
            if vm.isLoading {
                loadingView
            } else if let message = vm.errorMessage {
                errorView(message)
            } else if vm.filteredCarriers.isEmpty {
                emptyView
            } else {
                ForEach(vm.filteredCarriers, id: \.id) { c in
                    CarrierRowView(
                        logo: c.logo,
                        date: c.date,
                        transferNote: c.transferNote,
                        departure: c.departure,
                        duration: c.duration,
                        arrival: c.arrival,
                        onCarrierTap: { vm.didSelectCarrier(withLogo: c.logo) }
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 80)
    }

    struct CarrierRowView: View {
        let logo: String
        let date: String
        let transferNote: String?
        let departure: String
        let duration: String
        let arrival: String
        let onCarrierTap: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(logo)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding(.bottom, 16)
                        .contentShape(Rectangle())
                        .onTapGesture { onCarrierTap() }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(logoName(for: logo))
                            .font(.system(size: 17))
                            .foregroundColor(.black)
                            .contentShape(Rectangle())
                            .onTapGesture { onCarrierTap() }

                        if let note = transferNote {
                            Text(note)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 16)

                    Spacer()

                    Text(date)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                        .padding(.bottom, 25)
                }

                HStack {
                    Text(departure)
                        .font(.system(size: 17))

                    ZstackDuration(duration)

                    Text(arrival)
                        .font(.system(size: 17))
                }
                .foregroundColor(.black)
            }
            .padding()
            .background(Color.trainsLightGray)
            .cornerRadius(24)
        }

        private func logoName(for imageName: String) -> String {
            switch imageName {
            case "rzd":           return "РЖД"
            case "fgk":           return "ФГК"
            case "uralLogistics": return "Урал логистика"
            default:              return "Перевозчик"
            }
        }

        @ViewBuilder
        private func ZstackDuration(_ duration: String) -> some View {
            ZStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)

                Text(duration)
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .background(Color.trainsLightGray)
            }
            .frame(height: 20)
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 230)
            ProgressView()
            Text("Ищем рейсы…")
                .foregroundColor(.trainsBlack)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 230)
            Text(message)
                .foregroundColor(.trainsBlack)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        Text("Вариантов нет")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.trainsBlack)
            .frame(maxWidth: .infinity)
            .padding(.top, 230)
    }

    private var filterButton: some View {
        Button(action: { vm.openFilters() }) {
            HStack(spacing: 6) {
                Text("Уточнить время")
                    .foregroundColor(.white)
                    .font(.headline)

                if !vm.currentSelectedTimes.isEmpty || vm.currentShowTransfers != nil {
                    Circle()
                        .fill(Color.trainsRed)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}
