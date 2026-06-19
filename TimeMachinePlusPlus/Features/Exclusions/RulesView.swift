import SwiftUI

struct RulesView: View {
    @Environment(AppStateStore.self) private var store
    @Environment(\.undoManager) private var undoManager
    var showsHeader: Bool = true
    @State private var autosaveTask: Task<Void, Never>?
    @State private var isTemplateSheetPresented = false
    @State private var isShowingAppManagedExclusions = false

    var body: some View {
        @Bindable var store = store

        PageView(title: "Rules", subtitle: "Exclude by pattern or add exact paths") {
            rulesList(rules: $store.rules)
        }
        .safeAreaInset(edge: .bottom, content: accessWarning)
        .toolbar {
            RulesToolbar(
                isTemplateSheetPresented: $isTemplateSheetPresented,
                isShowingAppManagedExclusions: $isShowingAppManagedExclusions
            )
        }
        .sheet(isPresented: $isTemplateSheetPresented) {
            RuleTemplatesSheet()
        }
        .sheet(isPresented: $isShowingAppManagedExclusions) {
            AppManagedExclusionsView()
        }
        .onChange(of: store.rules, scheduleAutosave)
        .onDisappear(perform: onDisappear)
    }

    // MARK: - View Components

    @ViewBuilder
    private func rulesList(rules: Binding<[RegexRule]>) -> some View {
        Group {
            if !rules.wrappedValue.isEmpty {
                List {
                    ForEach(rules) { $rule in
                        RuleRow(rule: $rule) {
                            self.store.deleteRule(rule, undoManager: undoManager)
                        }
                    }
                }
                .listStyle(.inset)
                .disabled(!store.canEdit)
            } else {
                ContentUnavailableView("No rules added", systemImage: "plus", description: Text("Click plus in toolbar to create a new rule"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func accessWarning() -> some View {
        if let warning = store.accessWarningMessage {
            Label(warning, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.yellow.opacity(0.16), in: .rect)
        }
    }
}

private extension RulesView {
    func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            store.saveInBackground()
        }
    }

    func onDisappear() {
        autosaveTask?.cancel()
        store.save()
    }
}
