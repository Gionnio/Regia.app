//
//  MediaOrganizerApp.swift
//  Regia
//
//  Entry Point & Menu Management
//

import SwiftUI

@main
struct RegiaApp: App {
    @State private var aboutWindow: NSWindow?
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Regia") {
                    openAboutWindow()
                }
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Impostazioni...") {
                    NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    func openAboutWindow() {
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 380),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        
        window.center()
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: AboutView().preferredColorScheme(appTheme.colorScheme))
        window.isReleasedWhenClosed = false
        
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) { _ in
            self.aboutWindow = nil
        }

        window.makeKeyAndOrderFront(nil)
        self.aboutWindow = window
    }
}

struct AboutView: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 110, height: 110)
                .shadow(radius: 4)

            VStack(spacing: 5) {
                Text("Regia")
                    .font(.system(size: 26, weight: .bold))
                
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(width: 280)
                .padding(.vertical, 4)

            HStack(spacing: 4) {
                Text("Made with")
                    .font(.body)
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.body)
                Text("by Gionnio")
                    .font(.body)
                    .fontWeight(.medium)
            }

            Link(destination: URL(string: "https://github.com/gionnio/Regia.app")!) {
                HStack(spacing: 6) {
                    if let _ = NSImage(named: "GitHubIcon") {
                        Image("GitHubIcon")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Text("GitHub Repository")
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() }
                else { NSCursor.pop() }
            }

            Spacer().frame(height: 4)

            VStack(spacing: 3) {
                Text("MIT License")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("Copyright © 2026")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(30)
        .frame(width: 320)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
