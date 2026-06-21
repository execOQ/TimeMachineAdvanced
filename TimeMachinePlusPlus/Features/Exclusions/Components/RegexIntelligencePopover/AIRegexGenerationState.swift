import SwiftUI

@MainActor
@Observable
final class AIRegexGenerationState {
    var isGenerating = false
    var errorMessage: String?
    private var task: Task<Void, Never>?

    func generate(
        request: String,
        onSuccess: @escaping (String) -> Void
    ) {
        task?.cancel()
        errorMessage = nil
        isGenerating = true

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await AppleIntelligenceRegexHelper.generateRegex(for: request)
                guard !Task.isCancelled else { return }
                onSuccess(result)
                self.isGenerating = false
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
        }
    }
}
