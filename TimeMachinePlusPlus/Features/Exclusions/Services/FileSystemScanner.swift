import Foundation

struct FileSystemScanner {
    struct Candidate: Hashable {
        var path: String
        var isDirectory: Bool
        var sizeBytes: Int64?
    }

    func scan(settings: AppSettings, rules: [RegexRule]) -> [Candidate: RegexRule] {
        let enabledRules = rules.filter { $0.isEnabled && $0.kind != .path && RuleMatcher.validationError(for: $0) == nil }

        guard !enabledRules.isEmpty else { return [:] }
        return scan(settings: settings, enabledRules: enabledRules)
    }

    func scan(settings: AppSettings, rule: RegexRule, limit: Int? = nil) -> [Candidate] {
        guard rule.isEnabled, rule.kind != .path, RuleMatcher.validationError(for: rule) == nil else { return [] }
        return scan(settings: settings, enabledRule: rule, limit: limit)
    }

    private func scan(settings: AppSettings, enabledRules: [RegexRule]) -> [Candidate: RegexRule] {
        guard !enabledRules.isEmpty else { return [:] }

        var matches: [Candidate: RegexRule] = [:]
        let fileManager = FileManager.default
        let ignoredPaths = settings.ignoredPaths

        for root in settings.scanRoots where fileManager.fileExists(atPath: root) && !isIgnored(root, ignoredPaths: ignoredPaths) {
            let rootURL = URL(fileURLWithPath: root)
            let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey]
            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: keys,
                options: [.skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                let depth = relativeDepth(of: url, from: rootURL)
                if depth > settings.maxDepth {
                    enumerator.skipDescendants()
                    continue
                }

                let values = try? url.resourceValues(forKeys: Set(keys))
                let isDirectory = values?.isDirectory ?? false
                let path = url.standardizedFileURL.path
                if isIgnored(path, ignoredPaths: ignoredPaths) {
                    if isDirectory {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                for rule in enabledRules {
                    guard isDirectory || rule.includeFiles else { continue }
                    guard RuleMatcher.matches(path: path, isDirectory: isDirectory, rule: rule) else { continue }

                    let size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
                    matches[Candidate(path: path, isDirectory: isDirectory, sizeBytes: size > 0 ? size : nil)] = rule
                    if isDirectory {
                        enumerator.skipDescendants()
                    }
                    break
                }
            }
        }

        return matches
    }

    private func scan(settings: AppSettings, enabledRule rule: RegexRule, limit: Int?) -> [Candidate] {
        var matches: [Candidate] = []
        var seenPaths = Set<String>()
        let fileManager = FileManager.default
        let ignoredPaths = settings.ignoredPaths

        for root in settings.scanRoots where fileManager.fileExists(atPath: root) && !isIgnored(root, ignoredPaths: ignoredPaths) {
            let rootURL = URL(fileURLWithPath: root)
            let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey]
            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: keys,
                options: [.skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                if let limit, matches.count >= limit {
                    return matches.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
                }

                let depth = relativeDepth(of: url, from: rootURL)
                if depth > settings.maxDepth {
                    enumerator.skipDescendants()
                    continue
                }

                let values = try? url.resourceValues(forKeys: Set(keys))
                let isDirectory = values?.isDirectory ?? false
                let path = url.standardizedFileURL.path
                if isIgnored(path, ignoredPaths: ignoredPaths) {
                    if isDirectory {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                guard isDirectory || rule.includeFiles else { continue }

                guard !seenPaths.contains(path) else { continue }
                guard RuleMatcher.matches(path: path, isDirectory: isDirectory, rule: rule) else { continue }

                let size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
                matches.append(Candidate(path: path, isDirectory: isDirectory, sizeBytes: size > 0 ? size : nil))
                seenPaths.insert(path)
                if isDirectory {
                    enumerator.skipDescendants()
                }
            }
        }

        return matches.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    private func relativeDepth(of url: URL, from root: URL) -> Int {
        let rootComponents = root.standardizedFileURL.pathComponents
        let urlComponents = url.standardizedFileURL.pathComponents
        guard urlComponents.starts(with: rootComponents) else {
            return urlComponents.count
        }
        return urlComponents.dropFirst(rootComponents.count).count
    }

    private func isIgnored(_ path: String, ignoredPaths: [String]) -> Bool {
        let normalizedPath = PathNormalizer.normalized(path)
        return ignoredPaths.contains { ignoredPath in
            normalizedPath == ignoredPath || normalizedPath.hasPrefix(ignoredPath + "/")
        }
    }
}
