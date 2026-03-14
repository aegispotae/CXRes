import SwiftUI

struct SettingsView: View {
    @State private var profiles = AppSettings.profiles
    @State private var bottleName = AppSettings.bottleName

    var body: some View {
        Form {
            Section("CrossOver Bottle") {
                TextField("Bottle Name", text: $bottleName)
                Text("~/Library/Application Support/CrossOver/Bottles/\(bottleName)/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Resolution Profiles") {
                ForEach($profiles) { $profile in
                    HStack {
                        TextField("Name", text: $profile.name)
                            .frame(width: 120)
                        TextField("WxH", text: $profile.resolution)
                            .frame(width: 120)
                        Button {
                            withAnimation { profiles.removeAll { $0.id == profile.id } }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("Add Profile") {
                    withAnimation {
                        profiles.append(ResolutionProfile(name: "", resolution: "1920x1080"))
                    }
                }
            }

            Section {
                Button("Detect Displays") {
                    withAnimation { profiles = AppSettings.detectDisplayProfiles() }
                }
                .help("Create profiles from currently connected displays")

                Button("Restore Defaults") {
                    withAnimation {
                        profiles = [
                            ResolutionProfile(name: "Notebook", resolution: "2294x1490"),
                            ResolutionProfile(name: "External", resolution: "3840x2160"),
                        ]
                        bottleName = "Steam"
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: profiles) { _, newValue in AppSettings.profiles = newValue }
        .onChange(of: bottleName) { _, newValue in AppSettings.bottleName = newValue }
        .frame(minWidth: 380, minHeight: 300)
    }
}
