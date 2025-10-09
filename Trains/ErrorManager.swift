//
//  ErrorManager.swift
//  Trains
//
//  Created by Diana Viter on 07.08.2025.
//

import Foundation

@MainActor
final class ErrorManager: ObservableObject {

    struct PresentedError: Identifiable, Sendable {
        let id = UUID()
        let type: AppErrorType
    }

    @Published var presentedError: PresentedError?

    func show(_ type: AppErrorType) {
        presentedError = .init(type: type)
    }

    func dismiss() {
        presentedError = nil
    }
}

