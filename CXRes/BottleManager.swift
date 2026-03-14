import Foundation

/// Reads and writes the CrossOver Wine bottle `user.reg` to switch virtual desktop resolution.
struct BottleManager {
    private var regPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/CrossOver/Bottles/\(AppSettings.bottleName)/user.reg"
    }

    // MARK: - Current state

    /// Returns the currently active profile, or `nil` if virtual desktop is off.
    func currentProfile() -> ResolutionProfile? {
        guard let lines = readLines() else { return nil }
        var desktop = ""
        var resolution = ""
        var section: Section = .other

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            section = classify(trimmed, current: section)
            if section == .explorer, trimmed.hasPrefix("\"Desktop\"=") {
                desktop = extractValue(trimmed)
            }
            if section == .desktops, trimmed.hasPrefix("\"Default\"=") {
                resolution = extractValue(trimmed)
            }
        }

        guard !desktop.isEmpty else { return nil }
        return AppSettings.profiles.first { $0.resolution == resolution }
    }

    // MARK: - Apply

    /// Applies a resolution profile, or turns off virtual desktop if `nil`.
    func apply(_ profile: ResolutionProfile?) {
        guard var lines = readLines() else { return }
        let desktopValue = profile != nil ? "Default" : ""
        var section: Section = .other

        for i in lines.indices {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            section = classify(trimmed, current: section)
            if section == .explorer, trimmed.hasPrefix("\"Desktop\"=") {
                lines[i] = "\"Desktop\"=\"\(desktopValue)\"\n"
            }
            if section == .desktops, trimmed.hasPrefix("\"Default\"="), let profile {
                lines[i] = "\"Default\"=\"\(profile.resolution)\"\n"
            }
        }
        writeLines(lines)
    }

    // MARK: - Registry parsing

    private enum Section { case explorer, desktops, other }

    private func classify(_ line: String, current: Section) -> Section {
        if line.hasPrefix("[Software\\\\Wine\\\\Explorer\\\\Desktops]") {
            return .desktops
        } else if line.hasPrefix("[Software\\\\Wine\\\\Explorer]"), !line.contains("Desktops") {
            return .explorer
        } else if line.hasPrefix("["), !line.hasPrefix("#") {
            return .other
        }
        return current
    }

    private func extractValue(_ line: String) -> String {
        let parts = line.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { return "" }
        let raw = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("\""), raw.hasSuffix("\""), raw.count >= 2 {
            return String(raw.dropFirst().dropLast())
        }
        return raw
    }

    // MARK: - File I/O

    private func readLines() -> [String]? {
        guard let data = FileManager.default.contents(atPath: regPath),
              let content = String(data: data, encoding: .utf8)
        else { return nil }
        var lines: [String] = []
        content.enumerateLines { line, _ in lines.append(line + "\n") }
        return lines
    }

    private func writeLines(_ lines: [String]) {
        try? lines.joined().write(toFile: regPath, atomically: true, encoding: .utf8)
    }
}
