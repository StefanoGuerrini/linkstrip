import SwiftUI

/// About window showing version, copyright, license, and credits.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 0) {
                Text("Link")
                    .font(.custom("Space Grotesk", size: 28))
                    .fontWeight(.regular)
                Text("Strip")
                    .font(.custom("Space Grotesk", size: 28))
                    .fontWeight(.bold)
            }

            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("A privacy-first menu-bar app that removes tracking parameters from copied URLs.")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Divider()
                .frame(maxWidth: 280)

            VStack(spacing: 4) {
                Text("Created by Stefano Guerrini")
                    .font(.callout)
                Text("Licensed under MIT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Open Source Repository") {
                if let url = URL(string: "https://github.com/StefanoGuerrini/LinkStrip") {
                    NSWorkspace.shared.open(url)
                }
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(width: 420, height: 420)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}
