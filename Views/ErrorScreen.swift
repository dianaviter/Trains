//
//  ErrorScreen.swift
//  Trains
//
//  Created by Diana Viter on 07.08.2025.
//

import SwiftUI

enum AppErrorType {
    case noInternet
    case serverError
}

struct ErrorScreen: View {
    let type: AppErrorType

    var body: some View {
        VStack {
            Spacer()

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 223, height: 223)
                .clipShape(RoundedRectangle(cornerRadius: 40))

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 12)

            Spacer()
        }
        .padding()
    }

    private var imageName: String {
        switch type {
        case .noInternet: return "No internet"
        case .serverError: return "server error"
        }
    }

    private var title: String {
        switch type {
        case .noInternet: return "Нет интернета"
        case .serverError: return "Ошибка сервера"
        }
    }
}


#Preview {
    ErrorScreen(type: .serverError)
}
