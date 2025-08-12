//
//  CarrierInfo.swift
//  Trains
//
//  Created by Diana Viter on 11.08.2025.
//

import SwiftUI

struct CarrierDetails: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let logoImageName: String
    let email: String?
    let phone: String?
}

struct CarrierDetailView: View {
    
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    
    let carrier: CarrierDetails
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(carrier.logoImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 104)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top) 
                    .padding(.horizontal)
                
                Text(carrier.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.leading)
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 20) {
                    if let email = carrier.email, !email.isEmpty {
                        InfoRow(
                            title: "E-mail",
                            value: email,
                            valueColor: Color.trainsBlue
                        ) {
                            openURL(URL(string: "mailto:\(email)")!)
                        }
                    }
                    
                    if let phone = carrier.phone, !phone.isEmpty {
                        InfoRow(
                            title: "Телефон",
                            value: phone,
                            valueColor: Color.trainsBlue
                        ) {
                            let digits = phone.filter { "+0123456789".contains($0) }
                            if let url = URL(string: "tel:\(digits)") {
                                openURL(url)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Информация о перевозчике")
        .foregroundStyle(Color.trainsBlack)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.trainsBlack)
                }
            }
        }
    }
    
    private struct InfoRow: View {
        let title: String
        let value: String
        let valueColor: Color
        let action: () -> Void
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.trainsBlack)
                
                Button(action: action) {
                    Text(value)
                        .font(.system(size: 12))
                        .foregroundColor(valueColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    CarrierDetailView(
        carrier: CarrierDetails(
            name: "ОАО «РЖД»",
            logoImageName: "rzdHighRes",
            email: "i.lozgkina@yandex.ru",
            phone: "+7 (904) 329-27-71"
        )
    )
}
