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
            guard let data = defaults.data(forKey: "profiles"),
                  let decoded = try? JSONDecoder().decode([ResolutionProfile].self, from: data)
            else { return detectDisplayProfiles() }
            return decoded
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
