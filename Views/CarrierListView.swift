//
//  CarrierListView.swift
//  Trains
//
//  Created by Diana Viter on 05.08.2025.
//

import SwiftUI

struct CarrierListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showFilters = false

    @State private var selectedTimes: Set<DepartureTime> = []
    @State private var showTransfers: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.trainsBlack)
                            .imageScale(.large)
                    }
                    Spacer()
                }
                .padding(.bottom, 16)

                Text("Москва (Ярославский вокзал)")
                    .foregroundColor(.trainsBlack)
                    .font(.system(size: 24, weight: .bold))
                +
                Text(" → ")
                    .foregroundColor(.trainsBlack)
                    .font(.system(size: 24, weight: .bold))
                +
                Text("Санкт Петербург (Балтийский вокзал)")
                    .foregroundColor(.trainsBlack)
                    .font(.system(size: 24, weight: .bold))
            }
            .padding()

            ScrollView {
                VStack(spacing: 16) {
                    CarrierRowView(
                        logo: "rzd-logo",
                        date: "14 января",
                        transferNote: "С пересадкой в Костроме",
                        departure: "22:30",
                        duration: "20 часов",
                        arrival: "08:15"
                    )
                    CarrierRowView(
                        logo: "fgk-logo",
                        date: "15 января",
                        transferNote: nil,
                        departure: "01:15",
                        duration: "9 часов",
                        arrival: "09:00"
                    )
                    CarrierRowView(
                        logo: "ural-logo",
                        date: "16 января",
                        transferNote: nil,
                        departure: "12:30",
                        duration: "9 часов",
                        arrival: "21:00"
                    )
                    CarrierRowView(
                        logo: "rzd-logo",
                        date: "17 января",
                        transferNote: "С пересадкой в Костроме",
                        departure: "22:30",
                        duration: "20 часов",
                        arrival: "08:15"
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }

            Button(action: {
                showFilters = true
            }) {
                Text("Уточнить время")
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.trainsBlue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showFilters) {
            FiltersView { times, transfers in
                self.selectedTimes = times
                self.showTransfers = transfers
                applyFilters()
            }
        }
        .background(Color.trainsWhite)
        .navigationBarBackButtonHidden(true)
    }

    func applyFilters() {
        // сюда вставь фильтрацию рейсов по `selectedTimes` и `showTransfers`
        print("Фильтры применены: \(selectedTimes), пересадки: \(showTransfers?.description ?? "nil")")
    }
}

#Preview {
    CarrierListView()
}

