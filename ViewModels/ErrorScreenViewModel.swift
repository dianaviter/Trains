//
//  ErrorScreenViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation

enum AppErrorType: Sendable {
    case noInternet
    case serverError
}

@MainActor
final class ErrorScreenViewModel: ObservableObject {
    @Published var type: AppErrorType

    init(type: AppErrorType) {
        self.type = type
    }

    var imageName: String {
        switch type {
        case .noInternet:  return "No internet"
        case .serverError: return "server error"
        }
    }

    var title: String {
        switch type {
        case .noInternet:  return "Нет интернета"
        case .serverError: return "Ошибка сервера"
        }
    }
}
