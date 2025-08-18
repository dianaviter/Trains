//
//  SettingsView.swift
//  Trains
//
//  Created by Diana Viter on 03.08.2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @State private var path: [SettingsRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: SettingsRoute.self) { route in
                    switch route {
                    case .userAgreement:
                        UserAgreementView(onBack: {
                            path.removeLast()
                            vm.closeRoute()
                        })
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
        }
        .preferredColorScheme(vm.isDarkMode ? .dark : .light)
        .onChange(of: vm.route) { _, newValue in
            if let r = newValue, path.last != r { path.append(r) }
            if newValue == nil, !path.isEmpty { path.removeAll() }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Toggle("Тёмная тема",
                           isOn: Binding(get: { vm.isDarkMode },
                                         set: { vm.toggleDarkMode($0) }))
                        .tint(.trainsBlue)
                        .listRowBackground(Color.clear)
                        .padding(.vertical)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("toggle_dark_mode")
                }

                Section {
                    HStack {
                        Text("Пользовательское соглашение")
                            .foregroundColor(.trainsBlack)
                            .tracking(0.4)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.trainsBlack)
                            .font(.system(size: 24, weight: .medium))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.openAgreement()
                        if vm.route == .userAgreement { path.append(.userAgreement) }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier("cell_user_agreement")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.clear)

            footer
        }
    }

    private var footer: some View {
        VStack {
            Text("Приложение использует API «Яндекс.Расписания»")
                .font(.system(size: 12))
                .foregroundColor(.trainsBlack)
                .multilineTextAlignment(.center)
                .padding()
                .tracking(0.4)

            Text("Версия 1.0 (beta)")
                .font(.system(size: 12))
                .foregroundColor(.trainsBlack)
                .padding(.bottom, 24)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Agreement View
struct UserAgreementView: View {
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Оферта на оказание образовательных услуг дополнительного образования Яндекс.Практикум для физических лиц")
                    .font(.system(size: 24, weight: .bold))

                Text("""
                    Данный документ является действующим, если расположен по адресу: https://yandex.ru/legal/practicum_offer

                    Российская Федерация, город Москва

                    """)
                    .font(.system(size: 17, weight: .regular))

                Text("1. ТЕРМИНЫ")
                    .font(.system(size: 24, weight: .bold))

                Text("""
                Понятия, используемые в Оферте, означают следующее:  Авторизованные адреса — адреса электронной почты каждой Стороны. Авторизованным адресом Исполнителя является адрес электронной почты, указанный в разделе 11 Оферты. Авторизованным адресом Студента является адрес электронной почты, указанный Студентом в Личном кабинете.  Вводный курс — начальный Курс обучения по представленным на Сервисе Программам обучения в рамках выбранной Студентом Профессии или Курсу, рассчитанный на определенное количество часов самостоятельного обучения, который предоставляется Студенту единожды при регистрации на Сервисе на безвозмездной основе. В процессе обучения в рамках Вводного курса Студенту предоставляется возможность ознакомления с работой Сервиса и определения возможности Студента продолжить обучение в рамках Полного курса по выбранной Студентом Программе обучения. Точное количество часов обучения в рамках Вводного курса зависит от выбранной Студентом Профессии или Курса и определяется в Программе обучения, размещенной на Сервисе. Максимальный срок освоения Вводного курса составляет 1 (один) год с даты начала обучения.
                """)
                .font(.system(size: 17, weight: .regular))
            }
            .padding()
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Пользовательское соглашение")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.trainsBlack)
                }
            }
        }
    }
}

#Preview { SettingsView() }
