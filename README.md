Ecco il codice Markdown completo e aggiornato.

Ho inserito la sezione **Homebrew** subito dopo i requisiti (è il metodo consigliato) e ho spuntato la casella relativa nella **Roadmap**.

# Regia 🎬

![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=xcode&logoColor=white)
![License](https://img.shields.io/github/license/gionnio/Regia.app?style=for-the-badge)
![Views](https://komarev.com/ghpvc/?username=gionnio-Regia&style=for-the-badge&label=VIEWS&color=7F00FF)
![AI](https://img.shields.io/badge/AI-Assisted-blueviolet?style=for-the-badge&logo=openai&logoColor=white)

**Regia** is a native macOS application developed in SwiftUI designed to help users manage, organize, and rename their personal video library files efficiently using official metadata.

<img width="1040" height="788" alt="Regia Main Interface" src="https://github.com/user-attachments/assets/c63b551d-447c-48c1-bc4a-75daf12f68ff" />

## ✨ Features
- **Smart Anchor Logic:** Intelligently identifies the movie or show title by detecting the year or season, cleaning up inconsistent filenames automatically.
- **Metadata Integration:** Connects to TMDB to retrieve official titles and release years for accurate cataloging.
- **TV Series Support:** Native recognition of standard season/episode numbering patterns (`SxxExx`).
- **Structured Organization:** Optional feature to move files into a standardized folder hierarchy, compatible with popular media servers.
- **Plex & Jellyfin Support:** Supports standardized naming conventions including identifiers (`{tmdb-id}` for Plex, `[tmdbid-id]` for Jellyfin).
- **Dark Mode Support:** Native Light/Dark theme switching.
- **Disambiguation:** User interface to manually select the correct match when multiple titles are found.
- **Undo Capability:** Safety feature to revert the last rename or move operation instantly.
- **Multi-language:** Native support for Italian 🇮🇹 and English 🇬🇧.

<img width="1040" height="788" alt="Regia Settings and List" src="https://github.com/user-attachments/assets/761eab7a-32b3-4636-a8e9-147303b1b4d6" />

## 🚀 Requirements
- macOS 14.0 (Sonoma) or later.
- A personal [TMDB API Key](https://developer.themoviedb.org/docs/getting-started) (Free) is required to fetch metadata.

---

## 🍺 Installation via Homebrew (Recommended)

The easiest way to install and keep Regia updated is using Homebrew.

1. **Add the tap:**
   ```bash
   brew tap gionnio/regia

2. **Install the app:**
```bash
brew install --cask regia

```

### 🔄 Updating

To update Regia to the latest version in the future, simply run:

```bash
brew upgrade regia

```

---

## 📥 Manual Installation (Pre-built App)

If you don't want to compile the code yourself using Xcode or use Homebrew, you can download the ready-to-use app:

1. Go to the **[Releases](https://www.google.com/search?q=../../releases)** section on the right sidebar of this page.
2. Download the latest `.zip` file (e.g., `Regia_v1.3.2.zip`).
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

## 🚧 Roadmap & TODO

We are constantly working to improve Regia. Here are the features planned for upcoming releases:

* [ ] **System Notifications:** Implement native macOS notifications upon processing completion, useful for alerting the user when long background tasks are finished.
* [ ] **Custom Renaming Format:** Introduce a custom pattern editor (e.g., `{title} - [{year}]`) to allow users to create renaming styles beyond the *Standard*, *Compact*, and *Plex* presets.
* [x] **Homebrew Support:** Create a Cask to allow easy installation and updates via command line (e.g., `brew install --cask regia`).

## Privacy & Security

This application runs locally on your device. API Keys and file information are processed on your Mac and are never sent to external servers other than the official TMDB API for metadata retrieval.

## 🤖 AI Acknowledgment

This application was developed with the assistance of Artificial Intelligence for code generation, logic optimization, and problem-solving.

---

Created with AI, ❤️ and SwiftUI.

```
