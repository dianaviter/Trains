//
//  StoryThumbViewModel.swift
//  Trains
//
//  Created by Diana Viter on 17.08.2025.
//

import Foundation
import SwiftUI

@MainActor
final class StoriesViewerViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var currentIndex = 0

    private var progressTask: Task<Void, Never>?
    private let stepDuration: TimeInterval = 3
    private(set) var startDate: Date = .now

    deinit { progressTask?.cancel() }

    func next() {
        guard currentIndex < stories.count - 1 else { return }
        currentIndex += 1
        markCurrentViewed()
        restartTimer()
    }

    func prev() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        restartTimer()
    }

    func restartTimer() {
        startDate = .now
        progressTask?.cancel()

        let ns = UInt64(stepDuration * 1_000_000_000)
        progressTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: ns)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.next() }
        }
    }

    private func markCurrentViewed() {
        guard stories.indices.contains(currentIndex) else { return }
        if !stories[currentIndex].isViewed {
            stories[currentIndex].isViewed = true
        }
    }
}

