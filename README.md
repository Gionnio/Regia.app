# Regia 🎬

![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=xcode&logoColor=white)
![License](https://img.shields.io/github/license/gionnio/Regia.app?style=for-the-badge)
![Views](https://komarev.com/ghpvc/?username=gionnio-Regia&style=for-the-badge&label=VIEWS&color=7F00FF)
![Downloads](https://img.shields.io/github/downloads/gionnio/Regia.app/total?style=for-the-badge&color=success)
![AI](https://img.shields.io/badge/AI-Assisted-blueviolet?style=for-the-badge&logo=openai&logoColor=white)

**Regia** is a native macOS application developed in SwiftUI designed to help users manage, organize, and rename their personal video library files efficiently using official metadata.

<img width="1212" alt="Regia Main Interface" src="https://github.com/user-attachments/assets/b0250c3e-a255-4a9f-91ee-ac4faf035e79" />

## ✨ Features
- **Smart Anchor Logic:** Intelligently identifies the movie or show title by detecting the year or season, cleaning up inconsistent filenames automatically.
- **Metadata Integration:** Connects to TMDB to retrieve official titles and release years for accurate cataloging.
- **TV Series Support:** Native recognition of standard season/episode numbering patterns (`SxxExx`).
- **Structured Organization:** Optional feature to move files into a standardized folder hierarchy (`Series Name/Season X/Episode`), compatible with most media center software (e.g., Plex, Emby).
- **Disambiguazione:** User interface to manually select the correct match when multiple titles are found.
- **Undo Capability:** Safety feature to revert the last rename or move operation instantly.
- **Multi-language:** Native support for Italian 🇮🇹 and English 🇬🇧.

<img width="1212" alt="Regia Settings and List" src="https://github.com/user-attachments/assets/077a0031-eade-4af8-a09d-4419e47a0340" />

## 🚀 Requirements
- macOS 14.0 (Sonoma) or later.
- A personal TMDB API Key (Free) is required to fetch metadata.

## 📥 Installation (Pre-built App)
If you don't want to compile the code yourself using Xcode, you can download the ready-to-use app:

1. Go to the **[Releases](../../releases)** section on the right sidebar of this page.
2. Download the latest `.zip` file (e.g., `Regia_v1.0.zip`).
3. Unzip the file and move `Regia.app` to your **Applications** folder.

### ⚠️ Important: How to open the app
Since this is an open-source project and not signed with a paid Apple Developer ID, macOS might block the first launch with a security warning ("App cannot be opened because the developer cannot be verified").

**To open it:**
1. **Right-click** (or Control+Click) on the `Regia` icon.
2. Select **Open** from the context menu.
3. Click **Open** in the dialog box that appears.

*You only need to do this once. Subsequent launches will work normally.*

## 🛠 Build from Source
1. Clone the repository or download the source code.
2. Open `Regia.xcodeproj` with Xcode.
3. Run the app (Cmd+R).
4. Go to the **Settings** tab and enter your TMDB API Key.

## Privacy & Security
This application runs locally on your device. API Keys and file information are processed on your Mac and are never sent to external servers other than the official TMDB API for metadata retrieval.

## 🚧 Roadmap

Leveraging the new **Foundation Models framework** introduced in macOS 26, Regia is evolving to become smarter and completely Regex-free.

- [ ] **Semantic Filename Parsing:** Replace current regex logic with Apple's **on-device Foundation Model**. By using the new Swift APIs, Regia will "read" messy filenames semantically to extract titles and years with human-like understanding, even for complex edge cases.
- [ ] **Privacy-First Intelligence:** All AI processing will happen locally using the Neural Engine, ensuring zero data leaves your Mac, consistent with the Apple Intelligence privacy promise.
- [ ] **Smart Folder Watcher:** A background agent monitoring the "Downloads" folder to auto-suggest renaming actions.
- [ ] **Subtitle Auto-Match:** Automatically detect and rename orphan `.srt` files to match video filenames.

## 🤖 AI Acknowledgment
This application was developed with the assistance of Artificial Intelligence for code generation, logic optimization, and problem-solving.

---
Created with AI, ❤️ and SwiftUI.
