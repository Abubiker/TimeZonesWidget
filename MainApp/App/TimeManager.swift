import SwiftUI
import Combine

final class TimeManager: ObservableObject {
    @Published var currentTime: Date = Date()
    private var cancellable: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    private func startTimer() {
        // Update time once per second to reduce CPU usage while keeping the UI accurate.
        cancellable = Timer.publish(every: 1.0, tolerance: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
