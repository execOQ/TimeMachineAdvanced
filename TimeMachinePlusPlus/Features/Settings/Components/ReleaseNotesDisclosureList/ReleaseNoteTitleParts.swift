import Foundation

struct ReleaseNoteTitleParts {
    let symbol: String?
    let title: String

    init(_ rawTitle: String) {
        let trimmedTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        if let whitespaceIndex = trimmedTitle.firstIndex(where: \.isWhitespace) {
            let prefix = String(trimmedTitle[..<whitespaceIndex])
            if !prefix.containsLetterOrNumber {
                symbol = prefix
                title = trimmedTitle[whitespaceIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }
        }

        if let firstScalarCluster = trimmedTitle.first {
            let firstCluster = String(firstScalarCluster)
            let remainder = String(trimmedTitle.dropFirst())
            if !firstCluster.containsLetterOrNumber {
                symbol = firstCluster
                title = remainder.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }
        }

        symbol = nil
        title = trimmedTitle
    }
}

private extension String {
    var containsLetterOrNumber: Bool {
        contains { $0.isLetter || $0.isNumber }
    }
}
