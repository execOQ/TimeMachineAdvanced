import AppKit
import Foundation
import SwiftUI

struct ContentView: View {
    @Environment(AppStateStore.self) private var store
    @State private var helperObserver = HelperNotificationObserver()

    var body: some View {
        RulesView()
            .sheet(isPresented: onboardingBinding) {
                AccessOnboardingView()
            }
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
            .onReceive(
                NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification),
                perform: onAppDidBecomeActive
            )
    }
}

extension ContentView {
    // MARK: - Lifecycle

    private func onAppear() {
        guard !AppRuntime.isRunningForPreviews else { return }
        store.refreshHelperStatus()
        store.refreshAccessStatus()
        helperObserver.start {
            store.refreshHelperStatus()
        }
    }

    private func onDisappear() {
        helperObserver.stop()
    }

    // MARK: - Actions

    private func onAppDidBecomeActive(_ notification: Notification) {
        guard !AppRuntime.isRunningForPreviews else { return }
        store.refreshHelperStatus()
        store.refreshAccessStatus()
    }

    var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !store.settings.onboardingCompleted },
            set: { isPresented in
                if !isPresented {
                    store.settings.onboardingCompleted = true
                    store.save()
                }
            }
        )
    }
}
