import AppKit

struct ResolutionProfile: Codable, Identifiable, Equatable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var resolution: String
}

enum AppSettings {
    private nonisolated(unsafe) static let defaults = UserDefaults.standard

    static var profiles: [ResolutionProfile] {
        get {
            if let data = defaults.data(forKey: "profiles"),
               let decoded = try? JSONDecoder().decode([ResolutionProfile].self, from: data) {
                return decoded
            }
            // First launch — detect, store, and return stable IDs
            let detected = detectDisplayProfiles()
            if let data = try? JSONEncoder().encode(detected) {
                defaults.set(data, forKey: "profiles")
            }
            return detected
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: "profiles")
        }
    }

    static var bottleName: String {
        get { defaults.string(forKey: "bottleName") ?? "Steam" }
        set { defaults.set(newValue, forKey: "bottleName") }
    }

    /// Returns all CrossOver bottle names found in ~/Library/Application Support/CrossOver/Bottles/.
    /// Skips symlinks and hidden files.
    static func availableBottles() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let bottlesDir = "\(home)/Library/Application Support/CrossOver/Bottles"
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: bottlesDir) else { return [] }
        return contents
            .filter { !$0.hasPrefix(".") }
            .filter { name in
                let full = "\(bottlesDir)/\(name)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: full, isDirectory: &isDir), isDir.boolValue else { return false }
                // Skip symlinks (e.g. "default -> Steam")
                let attrs = try? fm.attributesOfItem(atPath: full)
                return attrs?[.type] as? FileAttributeType != .typeSymbolicLink
            }
            .sorted()
    }

    /// Detects connected displays and creates profiles from their backing-store resolution.
    static func detectDisplayProfiles() -> [ResolutionProfile] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return [ResolutionProfile(name: "Default", resolution: "1920x1080")]
        }
        var profiles: [ResolutionProfile] = []
        var seen = Set<String>()
        for screen in screens {
            let backing = screen.convertRectToBacking(screen.frame)
            let w = Int(backing.width)
            let h = Int(backing.height)
            let res = "\(w)x\(h)"
            guard !seen.contains(res) else { continue }
            seen.insert(res)
            let name = screen == screens.first ? "Built-in" : "External"
            profiles.append(ResolutionProfile(name: name, resolution: res))
        }
        return profiles
    }
}
