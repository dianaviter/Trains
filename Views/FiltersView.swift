//
//  FiltersView.swift
//  Trains
//
//  Created by Diana Viter on 06.08.2025.
//

import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTimes: Set<DepartureTime> = []
    @State private var showTransfers: Bool? = nil

    /// 👇 Callback для передачи выбранных фильтров обратно
    var onApply: ((Set<DepartureTime>, Bool?) -> Void)? = nil

    private var isAnyFilterSelected: Bool {
        !selectedTimes.isEmpty || showTransfers != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
            .padding(.bottom, 4)

            Text("Время отправления")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 16)

            ForEach(DepartureTime.allCases, id: \.self) { time in
                HStack {
                    Text(time.rawValue)
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.trainsBlack, lineWidth: 2)
                            .frame(width: 18, height: 18)

                        if selectedTimes.contains(time) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.trainsBlack)
                                .frame(width: 18, height: 18)

                            Image(systemName: "checkmark")
                                .foregroundColor(.trainsWhite)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .onTapGesture {
                        if selectedTimes.contains(time) {
                            selectedTimes.remove(time)
                        } else {
                            selectedTimes.insert(time)
                        }
                    }
                }
                .padding(.bottom, 10)
            }

            Text("Показывать варианты с пересадками")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 24)
                .padding(.bottom, 16)

            HStack {
                Text("Да")
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.trainsBlack, lineWidth: 2)
                        .frame(width: 18, height: 18)

                    if showTransfers == true {
                        Circle()
                            .fill(Color.trainsBlack)
                            .frame(width: 10, height: 10)
                    }
                }
                .onTapGesture {
                    showTransfers = true
                }
            }
            .padding(.bottom, 10)

            HStack {
                Text("Нет")
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.trainsBlack, lineWidth: 2)
                        .frame(width: 18, height: 18)

                    if showTransfers == false {
                        Circle()
                            .fill(Color.trainsBlack)
                            .frame(width: 10, height: 10)
                    }
                }
                .onTapGesture {
                    showTransfers = false
                }
            }

            Spacer()

            if isAnyFilterSelected {
                Button(action: {
                    onApply?(selectedTimes, showTransfers)
                    dismiss()
                }) {
                    Text("Применить")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.trainsBlue)
                        .cornerRadius(16)
                }
                .padding(.bottom, 16)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

enum DepartureTime: String, CaseIterable {
    case morning = "Утро 06:00 - 12:00"
    case day = "День 12:00 - 18:00"
    case evening = "Вечер 18:00 - 00:00"
    case night = "Ночь 00:00 - 06:00"
}

#Preview {
    FiltersView()
}
