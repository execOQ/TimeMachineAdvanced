import AppKit
import Foundation

extension AppStateStore {
    func addRule(undoManager: UndoManager? = nil) {
        guard canEdit else { return }
        let rule = RegexRule(name: "New rule", pattern: "cache/", kind: .pattern, isEnabled: false)
        undoManager?.registerUndo(withTarget: self) { store in
            undoManager?.registerUndo(withTarget: store) { store in
                store.rules.append(rule)
                store.save()
            }
            undoManager?.setActionName("Add Rule")
            store.rules.removeAll { $0.id == rule.id }
            store.save()
        }
        undoManager?.setActionName("Add Rule")
        rules.append(rule)
        save()
    }

    func addRule(from template: RuleTemplate, undoManager: UndoManager? = nil) {
        guard canEdit, !hasRule(from: template) else { return }
        let rule = template.rule
        undoManager?.registerUndo(withTarget: self) { store in
            undoManager?.registerUndo(withTarget: store) { store in
                store.rules.append(rule)
                store.save()
            }
            undoManager?.setActionName("Add Rule")
            store.rules.removeAll { $0.id == rule.id }
            store.save()
        }
        undoManager?.setActionName("Add Rule")
        rules.append(rule)
        save()
    }

    func addMissingRules(from templates: [RuleTemplate], undoManager: UndoManager? = nil) {
        guard canEdit else { return }
        let additions = templates.filter { !hasRule(from: $0) }.map(\.rule)
        guard !additions.isEmpty else { return }
        let addedIDs = Set(additions.map(\.id))
        undoManager?.registerUndo(withTarget: self) { store in
            undoManager?.registerUndo(withTarget: store) { store in
                store.rules.append(contentsOf: additions)
                store.save()
            }
            undoManager?.setActionName("Add Rules")
            store.rules.removeAll { addedIDs.contains($0.id) }
            store.save()
        }
        undoManager?.setActionName("Add Rules")
        rules.append(contentsOf: additions)
        save()
    }

    func hasRule(from template: RuleTemplate) -> Bool {
        rules.contains { rule in
            rule.kind == template.kind &&
                normalizedPattern(rule.pattern) == normalizedPattern(template.pattern) &&
                rule.includeFiles == template.includeFiles
        }
    }

    func deleteRule(_ rule: RegexRule, undoManager: UndoManager? = nil) {
        guard canEdit else { return }
        let originalIndex = rules.firstIndex(where: { $0.id == rule.id })
        undoManager?.registerUndo(withTarget: self) { store in
            undoManager?.registerUndo(withTarget: store) { store in
                store.rules.removeAll { $0.id == rule.id }
                store.save()
            }
            undoManager?.setActionName("Delete Rule")
            if let idx = originalIndex, idx <= store.rules.count {
                store.rules.insert(rule, at: idx)
            } else {
                store.rules.append(rule)
            }
            store.save()
        }
        undoManager?.setActionName("Delete Rule")
        rules.removeAll { $0.id == rule.id }
        save()
    }

    func addPathRules(_ urls: [URL], undoManager: UndoManager? = nil) {
        guard canEdit else { return }
        let known = Set(rules.filter { $0.kind == .path }.map(\.pattern))
        let additions = urls.map(\.path).filter { !known.contains($0) }
        let newRules = additions.map { path in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return RegexRule(name: name, pattern: path, kind: .path, isEnabled: true, includeFiles: true)
        }
        guard !newRules.isEmpty else { return }
        let addedIDs = Set(newRules.map(\.id))
        undoManager?.registerUndo(withTarget: self) { store in
            undoManager?.registerUndo(withTarget: store) { store in
                store.rules.append(contentsOf: newRules)
                store.save()
            }
            undoManager?.setActionName("Add Path Rules")
            store.rules.removeAll { addedIDs.contains($0.id) }
            store.save()
        }
        undoManager?.setActionName("Add Path Rules")
        rules.append(contentsOf: newRules)
        save()
    }

    func previewMatches(for rule: RegexRule) async -> [RulePreviewResult] {
        guard rule.isEnabled, rule.kind != .path, RuleMatcher.validationError(for: rule) == nil else { return [] }

        refreshAccessStatus()
        let activeRoots = activeScanRoots
        let scanSettings = settings.withScanRoots(activeRoots)
        let candidates = await Task.detached(priority: .userInitiated) { [scanSettings, scanner] in
            scanner.scan(settings: scanSettings, rule: rule, limit: scanSettings.previewResultLimit)
        }.value
        return candidates.map { candidate in
            RulePreviewResult(
                path: candidate.path,
                isDirectory: candidate.isDirectory,
                sizeBytes: candidate.sizeBytes
            )
        }
    }
}

private func normalizedPattern(_ pattern: String) -> String {
    pattern
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
}
