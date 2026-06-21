import SwiftUI

struct RegexIntelligencePopover: View {
    @Environment(AppStateStore.self) private var store

    @Binding var request: String
    @Binding var generatedPattern: String
    @Binding var generatedForRequest: String
    var generationState: AIRegexGenerationState
    let onUse: (String) -> Void

    private var trimmedRequest: String {
        request.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isRequestLongEnough: Bool {
        trimmedRequest.count >= 8
    }

    private var isAlreadyGenerated: Bool {
        !generationState.isGenerating &&
        !generatedPattern.isEmpty &&
        !generatedForRequest.isEmpty &&
        trimmedRequest == generatedForRequest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Regex Helper")
                    .font(.headline)
                Spacer()
            }

            TextField("Add more detail to get a useful pattern", text: $request, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2 ... 4)
                .disabled(generationState.isGenerating)
                .onSubmit { primaryAction() }

            responseView()
            actionsView()
        }
        .padding(12)
        .frame(width: 340)
        .onKeyPress(.return) {
            primaryAction()
            return .handled
        }
        .onDisappear(perform: onDisappear)
    }

    // MARK: - View Components

    @ViewBuilder
    private func responseView() -> some View {
        if !generatedPattern.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("Generated")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(generatedPattern)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
            }
        }

        if let errorMessage = generationState.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func actionsView() -> some View {
        HStack {
            if generationState.isGenerating {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()

            Button("Generate") {
                generatePattern()
            }
            .disabled(generationState.isGenerating || !isRequestLongEnough || isAlreadyGenerated)

            Button("Use") {
                onUse(generatedPattern)
            }
            .buttonStyle(.borderedProminent)
            .disabled(generatedPattern.isEmpty || generationState.isGenerating)
        }
    }
}

private extension RegexIntelligencePopover {
    func primaryAction() {
        if isAlreadyGenerated {
            onUse(generatedPattern)
        } else if isRequestLongEnough && !generationState.isGenerating {
            generatePattern()
        }
    }

    func generatePattern() {
        let patternBinding = _generatedPattern
        let forRequestBinding = _generatedForRequest
        let requestText = trimmedRequest
        generationState.generate(request: requestText) { result in
            patternBinding.wrappedValue = result
            forRequestBinding.wrappedValue = requestText
        }
    }

    func onDisappear() {
        store.save()
    }
}
