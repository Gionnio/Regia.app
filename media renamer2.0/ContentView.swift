//
//  ContentView.swift
//  Regia
//
//  Version: 1.2.2 (Stable - Compiler Fix)
//  Target: macOS 12.0+
//  Description: Fixed 'subscript' error by converting NSRange to String.Index correctly.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Localizzazione

enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "Italiano"; case english = "English"
    var id: String { self.rawValue }
    var apiCode: String { self == .italian ? "it" : "en" }
}

struct Strings {
    static func get(_ key: String, lang: AppLanguage) -> String {
        let dict: [String: [AppLanguage: String]] = [
            "app_title": [.italian: "Regia", .english: "Regia"],
            "settings_title": [.italian: "Impostazioni", .english: "Settings"],
            "status_ready": [.italian: "Pronto", .english: "Ready"],
            "status_not_found": [.italian: "Non Trovato", .english: "Not Found"],
            "status_manual": [.italian: "Pronto (Manuale)", .english: "Ready (Manual)"],
            "status_moved": [.italian: "Spostato!", .english: "Moved!"],
            "status_restored": [.italian: "Ripristinato", .english: "Restored"],
            "status_error_move": [.italian: "Errore File", .english: "File Error"],
            "status_error_net": [.italian: "Errore Rete", .english: "Network Error"],
            "msg_ready": [.italian: "Trascina qui file o cartelle.", .english: "Drag files here."],
            "msg_adding": [.italian: "Analisi in corso...", .english: "Analyzing..."],
            "msg_added": [.italian: "File aggiunti.", .english: "Files added."],
            "msg_scanning": [.italian: "Scansione...", .english: "Scanning..."],
            "msg_no_files": [.italian: "Nessun file video.", .english: "No video files."],
            "msg_scan_done": [.italian: "Scansione completata.", .english: "Scan completed."],
            "msg_cleaned": [.italian: "Lista svuotata.", .english: "List cleared."],
            "msg_searching": [.italian: "Ricerca TMDB...", .english: "Searching TMDB..."],
            "msg_search_done": [.italian: "Ricerca completata.", .english: "Search completed."],
            "msg_processing": [.italian: "Elaborazione...", .english: "Processing..."],
            "msg_done": [.italian: "Tutto fatto!", .english: "All done!"],
            "msg_undoing": [.italian: "Ripristino...", .english: "Restoring..."],
            "msg_undo_done": [.italian: "Ripristinati:", .english: "Restored:"],
            "msg_manual_search": [.italian: "Cerca:", .english: "Search:"],
            "err_no_folder": [.italian: "Nessuna cartella.", .english: "No folder."],
            "err_no_api": [.italian: "Manca API Key.", .english: "Missing API Key."],
            "err_no_ready": [.italian: "Nessun file pronto.", .english: "No files ready."],
            "err_ambiguous": [.italian: "Risolvi ambiguità.", .english: "Resolve ambiguities."],
            "col_original": [.italian: "File Originale", .english: "Original File"],
            "col_proposed": [.italian: "Nuovo Nome", .english: "New Name"],
            "col_status": [.italian: "Stato", .english: "Status"],
            "sheet_title": [.italian: "Seleziona Titolo", .english: "Select Title"],
            "sheet_cancel": [.italian: "Annulla", .english: "Cancel"],
            "sec_api": [.italian: "API", .english: "API"],
            "sec_format": [.italian: "Stile", .english: "Style"],
            "sec_folders": [.italian: "Cartelle", .english: "Folders"],
            "sec_language": [.italian: "Lingua", .english: "Language"],
            "lbl_format": [.italian: "Formato", .english: "Format"],
            "lbl_subfolders": [.italian: "Includi sottocartelle", .english: "Include subfolders"],
            "lbl_move": [.italian: "Sposta in cartelle", .english: "Move to folders"],
            "lbl_lang": [.italian: "Lingua", .english: "Language"],
            "btn_search": [.italian: "Cerca", .english: "Search"],
            "btn_done": [.italian: "Fatto", .english: "Done"],
            "alert_confirm_title": [.italian: "Conferma", .english: "Confirm"],
            "alert_confirm_msg": [.italian: "Procedere?", .english: "Proceed?"],
            "alert_manual_title": [.italian: "Manuale", .english: "Manual"],
            "btn_process": [.italian: "Elabora", .english: "Process"],
            "tip_open": [.italian: "Apri cartella", .english: "Open folder"],
            "tip_scan": [.italian: "Scansiona", .english: "Scan"],
            "tip_reset": [.italian: "Reset", .english: "Reset"],
            "tip_undo": [.italian: "Annulla", .english: "Undo"],
            "tip_tmdb": [.italian: "Cerca manuale", .english: "Manual Search"],
            "tip_process": [.italian: "Applica", .english: "Apply"],
            "tip_settings": [.italian: "Impostazioni", .english: "Settings"],
            "tip_sel_all": [.italian: "Tutti", .english: "All"],
            "tip_desel_all": [.italian: "Nessuno", .english: "None"],
            "tip_filter": [.italian: "Filtra", .english: "Filter"]
        ]
        return dict[key]?[lang] ?? key
    }
}

// MARK: - Models

struct DisambiguationCandidate: Identifiable { let id: String; let title: String; let year: String; let date: String }
struct AmbiguousMatch: Identifiable { let id = UUID(); let fileIndices: [Int]; let candidates: [DisambiguationCandidate]; let isTV: Bool }
struct RenameHistoryItem { let originalURL: URL; let newURL: URL; let fileID: UUID }

enum RenameFormat: String, CaseIterable, Identifiable {
    case standard = "standard"; case compact = "compact"; case plex = "plex"
    var id: String { self.rawValue }
    func label(for lang: AppLanguage) -> String {
        switch self {
        case .standard: return lang == .italian ? "Titolo (Anno)" : "Title (Year)"
        case .compact: return lang == .italian ? "Titolo.Anno" : "Title.Year"
        case .plex: return lang == .italian ? "Titolo (Anno) {tmdb-id}" : "Title (Year) {tmdb-id}"
        }
    }
}

struct TMDBResponse<T: Codable>: Codable { let results: [T] }
struct MovieResult: Codable, Identifiable {
    let id: Int; let title: String; let releaseDate: String?
    enum CodingKeys: String, CodingKey { case id, title; case releaseDate = "release_date" }
    var year: String { guard let d = releaseDate, d.count >= 4 else { return "N/A" }; return String(d.prefix(4)) }
}
struct TVResult: Codable, Identifiable {
    let id: Int; let name: String; let firstAirDate: String?
    enum CodingKeys: String, CodingKey { case id, name; case firstAirDate = "first_air_date" }
    var year: String { guard let d = firstAirDate, d.count >= 4 else { return "N/A" }; return String(d.prefix(4)) }
}

enum FileStatus {
    case pronto, nonTrovato, manuale, spostato, ripristinato, erroreSpostamento, erroreRete, erroreRegex
    func label(for lang: AppLanguage) -> String {
        switch self {
        case .pronto: return Strings.get("status_ready", lang: lang)
        case .nonTrovato: return Strings.get("status_not_found", lang: lang)
        case .manuale: return Strings.get("status_manual", lang: lang)
        case .spostato: return Strings.get("status_moved", lang: lang)
        case .ripristinato: return Strings.get("status_restored", lang: lang)
        case .erroreSpostamento: return Strings.get("status_error_move", lang: lang)
        case .erroreRete: return Strings.get("status_error_net", lang: lang)
        case .erroreRegex: return "Error"
        }
    }
}

final class MediaFile: ObservableObject, Identifiable {
    let id = UUID(); let originalURL: URL; let originalName: String
    @Published var proposedName: String; @Published var isSelected: Bool
    @Published var status: FileStatus; @Published var isTVShow: Bool; @Published var tmdbID: String = ""
    var parsedSeason: String?; var parsedEpisode: String?
    @Published var ambiguousCandidates: [DisambiguationCandidate]? = nil

    init(url: URL, status: FileStatus, proposedName: String = "", isSelected: Bool = false, isTVShow: Bool = false,
         tmdbID: String = "", parsedSeason: String? = nil, parsedEpisode: String? = nil) {
        self.originalURL = url; self.originalName = url.lastPathComponent; self.status = status
        self.proposedName = proposedName; self.isSelected = isSelected; self.isTVShow = isTVShow
        self.tmdbID = tmdbID; self.parsedSeason = parsedSeason; self.parsedEpisode = parsedEpisode
    }
}

// MARK: - LOGICA REGEX (Fixata per Swift String Index)

func cleanFileNameRegex(_ raw: String) -> (title: String, year: String?, isTV: Bool) {
    let nsString = raw as NSString
    let nameWithoutExt = nsString.deletingPathExtension
    // Primo passaggio: sostituisci punti e underscore con spazi
    let clean = nameWithoutExt.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ")
    
    // 1. PRIORITÀ ALTA: Muro SxxExx (Serie TV)
    let tvPattern = try! NSRegularExpression(pattern: #"(?i)\b(s\d{1,2}e\d{1,3}|\d{1,2}x\d{1,3})\b"#)
    let range = NSRange(clean.startIndex..., in: clean)
    
    if let match = tvPattern.firstMatch(in: clean, options: [], range: range),
       let tRange = Range(match.range, in: clean) {
        let rawTitle = String(clean[..<tRange.lowerBound])
        return (cleanupTitleString(rawTitle), nil, true)
    }
    
    // 2. PRIORITÀ MEDIA: Muro Anno (Film)
    let yearPattern = try! NSRegularExpression(pattern: #"\b(19\d{2}|20\d{2})\b"#)
    if let match = yearPattern.firstMatch(in: clean, options: [], range: range),
       let yRange = Range(match.range, in: clean) {
        let yearFound = String(clean[yRange])
        let titlePart = String(clean[..<yRange.lowerBound])
        return (cleanupTitleString(titlePart), yearFound, false)
    }
    
    // 3. PRIORITÀ BASSA: "Muro Spazzatura" (Per file senza anno ma con tag)
    let junkPattern = try! NSRegularExpression(pattern: #"(?i)\b(1080p|720p|4k|2160p|bluray|web-dl|webrip|hdtv|h264|h265|hevc|x264|x265|ita|eng|multi|sub|repack|remux|ac3|aac|ddp)\b"#)
    
    // FIX COMPILAZIONE QUI SOTTO: Convertiamo match.range in Range<String.Index>
    if let match = junkPattern.firstMatch(in: clean, options: [], range: range),
       let junkRange = Range(match.range, in: clean) {
        
        let rawTitle = String(clean[..<junkRange.lowerBound])
        return (cleanupTitleString(rawTitle), nil, false)
    }
    
    // 4. FALLBACK TOTALE
    return (cleanupTitleString(clean), nil, false)
}

func cleanupTitleString(_ text: String) -> String {
    var t = text
    t = t.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
         .replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
    let multiSpace = try! NSRegularExpression(pattern: #" {2,}"#)
    t = multiSpace.stringByReplacingMatches(in: t, range: NSRange(t.startIndex..., in: t), withTemplate: " ")
    return t.trimmingCharacters(in: .whitespacesAndNewlines)
}

func sanitizeFileName(_ name: String) -> String {
    let illegal = [":", "/", "\\", "?", "*", "\"", "<", ">", "|"]
    return illegal.reduce(name) { $0.replacingOccurrences(of: $1, with: " ") }.trimmingCharacters(in: .whitespaces)
}

func calcolaETA(processed: Int, total: Int, startTime: Date) -> String {
    guard processed > 0 else { return "..." }
    let remaining = (Date().timeIntervalSince(startTime) / Double(processed)) * Double(total - processed)
    return remaining < 60 ? "\(Int(remaining)) sec" : "\(Int(remaining / 60)) min"
}

// MARK: - ViewModel

@MainActor
final class MediaOrganizerViewModel: ObservableObject {
    @Published var fileList: [MediaFile] = []
    @Published var selectedFolderURL: URL?
    @Published var statusText = "..."
    @Published var isScanning = false; @Published var isProcessing = false
    @Published var progress: Double = 0.0; @Published var etaText: String = ""
    @Published var isShowingRetryAlert = false; @Published var retrySearchName = ""
    @Published var targetFileForManualSearch: MediaFile? = nil
    @Published var showConfirmationAlert = false
    @Published var showSettingsSheet = false
    
    @AppStorage("tmdbApiKey") var apiKey: String = ""
    @AppStorage("includeSubfolders") var includeSubfolders = true
    @AppStorage("createSubfolders") var createSubfolders = true
    @AppStorage("renameFormat") var renameFormat: RenameFormat = .plex
    @AppStorage("appLanguage") var appLanguage: AppLanguage = .italian
    
    @Published var filterNonTrovati = false
    @Published var undoHistory: [RenameHistoryItem] = []
    @Published var ambiguousMatches: [AmbiguousMatch] = []
    @Published var currentAmbiguity: AmbiguousMatch? = nil
    @Published var pendingProcessAfterDisambiguation = false
    
    private let videoExtensions = ["mkv", "mp4", "avi", "mov", "m4v"]
    let episodeRegex = try! NSRegularExpression(pattern: #"(?i)(?:s|stagione|^)[.\s]*(\d{1,2})[.\s]*(?:e|ep|episodio|x|-)[.\s]*(\d{1,3})|(\d{1,2})x(\d{1,3})"#, options: [])
    let absoluteEpRegex = try! NSRegularExpression(pattern: #"(?i)(?:^|[\s_\-\[])(?:e|ep|episodio)[.\s]*(\d{2,4})(?:[\s_\-\]]|$)"#, options: [])
    
    init() { self.statusText = Strings.get("msg_ready", lang: .italian) }
    func t(_ key: String) -> String { return Strings.get(key, lang: appLanguage) }
    func updateStatusReady() { self.statusText = t("msg_ready") }

    func parseEpisodeInfo(from name: String) -> (isTV: Bool, season: String?, episode: String?) {
        let ns = NSRange(name.startIndex..., in: name)
        if let m = episodeRegex.firstMatch(in: name, range: ns) {
            let sR = m.range(at: 1).location != NSNotFound ? m.range(at: 1) : m.range(at: 3)
            let eR = m.range(at: 2).location != NSNotFound ? m.range(at: 2) : m.range(at: 4)
            if let rS = Range(sR, in: name), let rE = Range(eR, in: name) {
                return (true, String(format: "%02d", Int(name[rS]) ?? 0), String(format: "%02d", Int(name[rE]) ?? 0))
            }
        }
        if let m = absoluteEpRegex.firstMatch(in: name, range: ns), let r = Range(m.range(at: 1), in: name) {
            return (true, nil, String(format: "%02d", Int(name[r]) ?? 0))
        }
        return (false, nil, nil)
    }

    func addDroppedFiles(urls: [URL]) {
        guard !apiKey.isEmpty else { statusText = t("err_no_api"); return }
        let videoExts = Set(videoExtensions.map { $0.lowercased() })
        let candidates = urls.filter { videoExts.contains($0.pathExtension.lowercased()) }
        guard !candidates.isEmpty else { return }
        if self.selectedFolderURL == nil, let first = candidates.first { self.selectedFolderURL = first.deletingLastPathComponent() }
        statusText = t("msg_adding"); isScanning = true; progress = 0
        Task {
            var newFiles: [MediaFile] = []
            for url in candidates {
                let parsed = parseEpisodeInfo(from: url.lastPathComponent)
                newFiles.append(MediaFile(url: url, status: .pronto, isTVShow: parsed.isTV, parsedSeason: parsed.season, parsedEpisode: parsed.episode))
            }
            await searchNamesForFiles(newFiles)
            self.fileList.append(contentsOf: newFiles); self.statusText = self.t("msg_added")
        }
    }
    
    func scanFolder() {
        guard let baseURL = selectedFolderURL else { statusText = t("err_no_folder"); return }
        guard !apiKey.isEmpty else { statusText = t("err_no_api"); return }
        statusText = t("msg_scanning"); isScanning = true; progress = 0; etaText = ""
        Task {
            let access = baseURL.startAccessingSecurityScopedResource(); defer { if access { baseURL.stopAccessingSecurityScopedResource() } }
            let fm = FileManager.default; var urls: [URL] = []
            if includeSubfolders {
                if let en = fm.enumerator(at: baseURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    while let obj = en.nextObject() { if let url = obj as? URL { urls.append(url) } }
                }
            } else { if let c = try? fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) { urls = c } }
            let videoExts = Set(self.videoExtensions.map { $0.lowercased() })
            let candidates = urls.filter { videoExts.contains($0.pathExtension.lowercased()) }
            if candidates.isEmpty { await MainActor.run { self.statusText = self.t("msg_no_files"); self.isScanning = false }; return }
            var newFiles: [MediaFile] = []
            for url in candidates {
                let parsed = self.parseEpisodeInfo(from: url.lastPathComponent)
                newFiles.append(MediaFile(url: url, status: .pronto, isTVShow: parsed.isTV, parsedSeason: parsed.season, parsedEpisode: parsed.episode))
            }
            await self.searchNamesForFiles(newFiles)
            await MainActor.run { self.fileList = newFiles; self.statusText = self.t("msg_scan_done"); self.isScanning = false; self.progress = 0 }
        }
    }
    
    func resetAll() {
        isScanning = false; isProcessing = false; progress = 0
        fileList.removeAll(); ambiguousMatches.removeAll(); undoHistory.removeAll(); currentAmbiguity = nil; statusText = t("msg_cleaned")
    }
    
    func searchNamesForFiles(_ files: [MediaFile]) async {
        await MainActor.run { statusText = self.t("msg_searching") }
        progress = 0; let total = files.count; let start = Date(); var processed = 0
        for file in files {
            if apiKey.isEmpty { file.status = .erroreRete; continue }
            await searchName(for: file)
            processed += 1
            await MainActor.run { progress = Double(processed) / Double(total); if processed > 3 { etaText = calcolaETA(processed: processed, total: total, startTime: start) } }
        }
        await MainActor.run { isScanning = false; statusText = self.t("msg_search_done"); checkForAmbiguities(); if !ambiguousMatches.isEmpty { currentAmbiguity = ambiguousMatches.first } }
    }
    
    func searchName(for file: MediaFile, overrideQuery: String? = nil, year: String? = nil) async {
        var query = ""; var yearToUse: String? = nil; var isTV = file.isTVShow
        
        if let q = overrideQuery, !q.isEmpty {
            query = q
        } else {
            let cleaned = cleanFileNameRegex(file.originalName)
            query = cleaned.title
            yearToUse = cleaned.year
            if cleaned.isTV {
                isTV = true
                await MainActor.run { file.isTVShow = true }
            }
        }
        
        guard !query.isEmpty else { await MainActor.run { file.status = .nonTrovato }; return }
        
        do {
            if isTV {
                let results: [TVResult] = try await fetchFromTMDB(query: query, endpoint: "search/tv", year: yearToUse)
                handleResults(results, file: file)
            } else {
                let results: [MovieResult] = try await fetchFromTMDB(query: query, endpoint: "search/movie", year: yearToUse)
                handleResults(results, file: file)
            }
        } catch { await MainActor.run { file.status = .erroreRete } }
    }

    func handleResults<T: Identifiable>(_ results: [T], file: MediaFile) {
        let sortedResults = results.sorted { a, b in
            let dateA = (a as? MovieResult)?.releaseDate ?? (a as? TVResult)?.firstAirDate ?? "0000"
            let dateB = (b as? MovieResult)?.releaseDate ?? (b as? TVResult)?.firstAirDate ?? "0000"
            return dateA > dateB
        }
        if sortedResults.count > 1 {
            let cands = sortedResults.map { item -> DisambiguationCandidate in
                if let m = item as? MovieResult { return DisambiguationCandidate(id: "\(m.id)", title: m.title, year: m.year, date: m.releaseDate ?? "N/A") }
                if let t = item as? TVResult { return DisambiguationCandidate(id: "\(t.id)", title: t.name, year: t.year, date: t.firstAirDate ?? "N/A") }
                return DisambiguationCandidate(id: "0", title: "??", year: "", date: "")
            }
            file.status = .nonTrovato; file.ambiguousCandidates = cands
        } else if let first = sortedResults.first { applyFromAPI(first, to: file) }
        else { file.status = .nonTrovato }
    }
    
    func applyFromAPI<T: Identifiable>(_ item: T, to file: MediaFile) {
        let title: String; let year: String; let id: String
        if let m = item as? MovieResult { title = m.title; year = m.year; id = "\(m.id)" }
        else if let t = item as? TVResult { title = t.name; year = t.year; id = "\(t.id)" }
        else { return }
        generateAndSetProposedName(title: title, year: year, id: id, file: file)
    }
    
    func applyFromCandidate(_ cand: DisambiguationCandidate, to file: MediaFile) {
        generateAndSetProposedName(title: cand.title, year: cand.year, id: cand.id, file: file)
    }
    
    private func generateAndSetProposedName(title: String, year: String, id: String, file: MediaFile) {
        file.tmdbID = id; var finalName = ""
        switch renameFormat {
        case .standard: finalName = "\(title) (\(year))"
        case .compact: finalName = "\(title.replacingOccurrences(of: " ", with: ".")) .\(year)"
        case .plex:
            if file.isTVShow { finalName = "\(title) (\(year))" }
            else { finalName = "\(title) (\(year)) {tmdb-\(id)}" }
        }
        if file.isTVShow, let s = file.parsedSeason, let e = file.parsedEpisode {
            finalName += (renameFormat == .compact ? "." : " ") + "S\(s)E\(e)"
        }
        file.proposedName = sanitizeFileName(finalName)
        file.status = .pronto; file.isSelected = true; file.ambiguousCandidates = nil
    }

    func fetchFromTMDB<T: Codable>(query: String, endpoint: String, year: String? = nil) async throws -> [T] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { throw URLError(.badURL) }
        var urlStr = "https://api.themoviedb.org/3/\(endpoint)?api_key=\(apiKey)&query=\(encoded)&language=\(appLanguage.apiCode)"
        if let y = year, !y.isEmpty { urlStr += endpoint == "search/tv" ? "&first_air_date_year=\(y)" : "&year=\(y)" }
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TMDBResponse<T>.self, from: data).results
    }

    func prepareManualSearch(for file: MediaFile) {
        self.targetFileForManualSearch = file; let cleaned = cleanFileNameRegex(file.originalName)
        self.retrySearchName = cleaned.title; self.isShowingRetryAlert = true
    }
    
    func retrySearchManual(name: String) {
        let q = name.trimmingCharacters(in: .whitespacesAndNewlines); guard !q.isEmpty else { return }
        guard !apiKey.isEmpty else { statusText = t("err_no_api"); return }
        let toRetry = targetFileForManualSearch != nil ? [targetFileForManualSearch!] : fileList.filter { $0.isSelected || [.nonTrovato, .erroreRete, .erroreRegex].contains($0.status) }
        statusText = "\(t("msg_manual_search")) '\(q)'..."; isScanning = true; progress = 0
        Task {
            let total = toRetry.count; var processed = 0
            for f in toRetry { await searchName(for: f, overrideQuery: q); processed += 1; await MainActor.run { progress = Double(processed) / Double(total) } }
            await MainActor.run {
                isScanning = false; statusText = self.t("msg_done"); retrySearchName = ""
                checkForAmbiguities(); if let t = targetFileForManualSearch {
                    if let m = ambiguousMatches.first(where: { $0.fileIndices.contains { idx in fileList[idx].id == t.id } }) { currentAmbiguity = m }
                } else if !ambiguousMatches.isEmpty { currentAmbiguity = ambiguousMatches.first }
                targetFileForManualSearch = nil
            }
        }
    }

    func requestProcessing() {
        guard selectedFolderURL != nil else { statusText = t("err_no_folder"); return }
        checkForAmbiguities()
        if let blocking = ambiguousMatches.first(where: { m in m.fileIndices.contains { fileList[$0].isSelected } }) {
            pendingProcessAfterDisambiguation = true; currentAmbiguity = blocking; statusText = t("err_ambiguous"); return
        }
        let toProcess = fileList.filter { $0.isSelected && !$0.proposedName.isEmpty }
        guard !toProcess.isEmpty else { statusText = t("err_no_ready"); return }
        showConfirmationAlert = true
    }

    func checkAndRequestPermission(for url: URL) {
        let path = url.path
        if !FileManager.default.isWritableFile(atPath: path) {
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.message = "Regia necessita del permesso di scrittura per questa cartella. Seleziona '\(url.lastPathComponent)'."
                panel.prompt = "Concedi Accesso"
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.directoryURL = url
                if panel.runModal() == .OK { _ = panel.url?.startAccessingSecurityScopedResource() }
            }
        }
    }

    func executeProcessing() {
        guard let baseURL = selectedFolderURL else { return }
        checkAndRequestPermission(for: baseURL)
        let toProcess = fileList.filter { $0.isSelected && !$0.proposedName.isEmpty }
        
        isProcessing = true; statusText = t("msg_processing"); progress = 0; undoHistory.removeAll()
        Task(priority: .userInitiated) {
            let fm = FileManager.default; let total = toProcess.count; var processed = 0
            let access = baseURL.startAccessingSecurityScopedResource(); defer { if access { baseURL.stopAccessingSecurityScopedResource() } }
            for file in toProcess {
                let ext = file.originalURL.pathExtension; let newName = file.proposedName; var destURL: URL
                if createSubfolders {
                    do {
                        let folder: URL
                        if file.isTVShow {
                            let regex = try! NSRegularExpression(pattern: #"^(.* \(\d{4}\)).*?(S\d{2})E(\d{2,3})$"#)
                            if let match = regex.firstMatch(in: newName, range: NSRange(newName.startIndex..., in: newName)),
                               let seriesRange = Range(match.range(at: 1), in: newName), let seasonRange = Range(match.range(at: 2), in: newName) {
                                let series = String(newName[seriesRange]); let seasonNum = String(newName[seasonRange].dropFirst())
                                var rootName = series
                                if renameFormat == .plex && !file.tmdbID.isEmpty { rootName += " {tmdb-\(file.tmdbID)}" }
                                let root = sanitizeFileName(rootName)
                                folder = baseURL.appendingPathComponent(root).appendingPathComponent("Season \(seasonNum)", isDirectory: true)
                            } else { folder = baseURL.appendingPathComponent(sanitizeFileName(newName)) }
                        } else { folder = baseURL.appendingPathComponent(sanitizeFileName(newName)) }
                        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
                        destURL = folder.appendingPathComponent("\(newName).\(ext)")
                    } catch { await MainActor.run { file.status = .erroreSpostamento }; processed += 1; continue }
                } else { destURL = file.originalURL.deletingLastPathComponent().appendingPathComponent("\(newName).\(ext)") }
                do {
                    let historyItem = RenameHistoryItem(originalURL: file.originalURL, newURL: destURL, fileID: file.id)
                    try fm.moveItem(at: file.originalURL, to: destURL)
                    await MainActor.run { file.status = .spostato; self.undoHistory.append(historyItem) }
                } catch { await MainActor.run { file.status = .erroreSpostamento } }
                processed += 1; await MainActor.run { progress = Double(processed) / Double(total) }
            }
            await MainActor.run { isProcessing = false; statusText = self.t("msg_done"); for f in toProcess where f.status == .spostato { f.isSelected = false } }
        }
    }
    
    func undoLastOperation() {
        guard !undoHistory.isEmpty else { statusText = ""; return }
        statusText = t("msg_undoing"); let fm = FileManager.default; var restoredCount = 0
        for item in undoHistory {
            do {
                try fm.moveItem(at: item.newURL, to: item.originalURL)
                if let file = fileList.first(where: { $0.id == item.fileID }) { file.status = .ripristinato; file.isSelected = true }
                restoredCount += 1
            } catch { print("Errore Undo: \(error)") }
        }
        undoHistory.removeAll(); statusText = "\(t("msg_undo_done")) \(restoredCount)."
    }
    
    func selectAll() { fileList.filter { [.pronto, .manuale].contains($0.status) }.forEach { $0.isSelected = true } }
    func deselectAll() { fileList.forEach { $0.isSelected = false } }
    
    func resolveAmbiguity(selected: DisambiguationCandidate) {
        guard let current = currentAmbiguity else { return }
        for idx in current.fileIndices { applyFromCandidate(selected, to: fileList[idx]) }
        ambiguousMatches.removeAll(where: { $0.id == current.id })
        if pendingProcessAfterDisambiguation {
            currentAmbiguity = ambiguousMatches.first { match in match.fileIndices.contains { fileList[$0].isSelected } }
            if currentAmbiguity == nil { pendingProcessAfterDisambiguation = false; requestProcessing() }
        } else { currentAmbiguity = ambiguousMatches.first }
    }
    
    func checkForAmbiguities() {
        var matches: [AmbiguousMatch] = []
        for (i, file) in fileList.enumerated() {
            if file.status == .nonTrovato, let cands = file.ambiguousCandidates, !cands.isEmpty { matches.append(AmbiguousMatch(fileIndices: [i], candidates: cands, isTV: file.isTVShow)) }
        }
        ambiguousMatches = matches
    }
}

// MARK: - UI Views

struct ContentView: View {
    @StateObject private var vm = MediaOrganizerViewModel()
    @State private var isDropTargeted = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isScanning { ScanningView(vm: vm) }
                else if vm.fileList.isEmpty {
                    Text(vm.selectedFolderURL == nil ? vm.t("msg_ready") : vm.t("msg_no_files"))
                        .font(.title2).foregroundColor(.secondary).frame(maxHeight: .infinity)
                } else { FileListView(vm: vm) }
                Divider(); HStack { Text(vm.statusText).font(.caption).lineLimit(1); Spacer() }.padding(8).background(Color(NSColor.windowBackgroundColor))
            }
            .navigationTitle(vm.t("app_title"))
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    HStack {
                        Button {
                            vm.selectedFolderURL = nil; let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false
                            panel.begin { if $0 == .OK { vm.selectedFolderURL = panel.url; vm.scanFolder() } }
                        } label: { Label(vm.t("btn_open"), systemImage: "folder") }
                        .disabled(vm.isScanning).help(vm.t("tip_open"))
                        if let url = vm.selectedFolderURL { Text(url.lastPathComponent).font(.caption).foregroundColor(.secondary).padding(.leading, 4) }
                    }
                    Button { vm.scanFolder() } label: { Image(systemName: "magnifyingglass") }.disabled(vm.selectedFolderURL == nil || vm.isScanning).help(vm.t("tip_scan"))
                    Button { vm.undoLastOperation() } label: { Image(systemName: "arrow.uturn.backward") }.disabled(vm.undoHistory.isEmpty || vm.isProcessing).help(vm.t("tip_undo"))
                    Button { vm.resetAll() } label: { Image(systemName: "arrow.clockwise") }.disabled(vm.isScanning).help(vm.t("tip_reset"))
                    Button { vm.selectAll() } label: { Image(systemName: "checklist") }.disabled(vm.fileList.isEmpty).help(vm.t("tip_sel_all"))
                    Button { vm.deselectAll() } label: { Image(systemName: "checklist.unchecked") }.disabled(vm.fileList.isEmpty).help(vm.t("tip_desel_all"))
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { vm.targetFileForManualSearch = nil; vm.isShowingRetryAlert = true } label: { Label(vm.t("btn_tmdb"), systemImage: "magnifyingglass.circle") }.disabled(vm.isScanning).help(vm.t("tip_tmdb"))
                    Toggle(isOn: $vm.filterNonTrovati) { Image(systemName: "line.3.horizontal.decrease.circle") }.toggleStyle(.button).disabled(vm.fileList.isEmpty).help(vm.t("tip_filter"))
                    Button { vm.requestProcessing() } label: { Label(vm.t("btn_process"), systemImage: "play.fill") }.disabled(vm.fileList.isEmpty || vm.isScanning || vm.isProcessing).help(vm.t("tip_process"))
                    Button { vm.showSettingsSheet = true } label: { Label(vm.t("settings_title"), systemImage: "gearshape") }.help(vm.t("tip_settings")).keyboardShortcut(",", modifiers: .command)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettings"))) { _ in
                vm.showSettingsSheet = true
            }
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
                let group = DispatchGroup(); var collected: [URL] = []
                for provider in providers { group.enter(); provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) { collected.append(url) } else if let url = item as? URL { collected.append(url) }; group.leave() } }
                group.notify(queue: .main) { if !collected.isEmpty { vm.addDroppedFiles(urls: collected) } }; return true
            }
            .sheet(isPresented: $vm.showSettingsSheet) { SettingsSheetView(vm: vm) }
            .alert(vm.t("alert_manual_title"), isPresented: $vm.isShowingRetryAlert) {
                TextField("...", text: $vm.retrySearchName)
                Button(vm.t("btn_search")) { vm.retrySearchManual(name: vm.retrySearchName); vm.retrySearchName = "" }
                Button(vm.t("sheet_cancel"), role: .cancel) { vm.retrySearchName = ""; vm.targetFileForManualSearch = nil }
            }
            .alert(vm.t("alert_confirm_title"), isPresented: $vm.showConfirmationAlert) {
                Button(vm.t("sheet_cancel"), role: .cancel) { }
                Button(vm.t("btn_process")) { vm.executeProcessing() }
            } message: { Text(vm.t("alert_confirm_msg")) }
            .sheet(item: $vm.currentAmbiguity) { amb in DisambiguationSheetView(ambiguity: amb, onSelect: { vm.resolveAmbiguity(selected: $0) }).environmentObject(vm) }
        }
    }
}

struct ScanningView: View {
    @ObservedObject var vm: MediaOrganizerViewModel
    var body: some View {
        VStack {
            Text(vm.statusText).font(.title2).padding(.bottom, 8)
            ProgressView(value: vm.progress).progressViewStyle(.linear).padding(.horizontal, 50)
            Text(vm.etaText).font(.caption).foregroundColor(.secondary).padding(.top, 4)
        }.frame(maxHeight: .infinity)
    }
}

struct FileListView: View {
    @ObservedObject var vm: MediaOrganizerViewModel
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(vm.t("col_original")).frame(maxWidth: .infinity, alignment: .leading)
                Text(vm.t("col_proposed")).frame(maxWidth: .infinity, alignment: .leading)
                Text(vm.t("col_status")).frame(width: 140, alignment: .leading)
            }.font(.headline).padding(.horizontal).padding(.top, 8)
            Divider()
            List {
                ForEach($vm.fileList) { $file in
                    if !vm.filterNonTrovati || [.nonTrovato, .erroreRete, .erroreRegex].contains(file.status) {
                        FileRowView(file: file, onManualSearch: { vm.prepareManualSearch(for: file) }).environmentObject(vm)
                    }
                }
            }.listStyle(.plain)
        }
    }
}

struct FileRowView: View {
    @ObservedObject var file: MediaFile
    @EnvironmentObject var vm: MediaOrganizerViewModel
    var onManualSearch: () -> Void
    var body: some View {
        HStack {
            Toggle("", isOn: $file.isSelected).toggleStyle(.checkbox).frame(width: 30)
            Text(file.originalName).font(.caption).lineLimit(2).foregroundColor(color(for: file.status)).frame(maxWidth: .infinity, alignment: .leading)
            TextField("...", text: $file.proposedName).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
            HStack {
                Text(file.status.label(for: vm.appLanguage)).font(.callout).foregroundColor(color(for: file.status))
                if [.nonTrovato, .erroreRete, .erroreRegex].contains(file.status) {
                    Button(action: onManualSearch) { Image(systemName: "magnifyingglass").foregroundColor(.blue) }.buttonStyle(.plain)
                }
            }.frame(width: 140, alignment: .leading)
        }.padding(.vertical, 4)
    }
    private func color(for s: FileStatus) -> Color { return [.pronto, .manuale, .spostato, .ripristinato].contains(s) ? .primary : .red }
}

struct SettingsSheetView: View {
    @ObservedObject var vm: MediaOrganizerViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Text(vm.t("settings_title")).font(.title2).padding()
            Form {
                Section(vm.t("sec_api")) { SecureField("API Key TMDB", text: $vm.apiKey) }
                Section(vm.t("sec_language")) {
                    Picker(vm.t("lbl_lang"), selection: $vm.appLanguage) {
                        ForEach(AppLanguage.allCases) { Text($0.rawValue).tag($0) }
                    }.onChange(of: vm.appLanguage) { _, _ in vm.updateStatusReady() }
                }
                Section(vm.t("sec_format")) {
                    Picker(vm.t("lbl_format"), selection: $vm.renameFormat) {
                        ForEach(RenameFormat.allCases) { Text($0.label(for: vm.appLanguage)).tag($0) }
                    }
                }
                Section(vm.t("sec_folders")) {
                    Toggle(vm.t("lbl_subfolders"), isOn: $vm.includeSubfolders)
                    Toggle(vm.t("lbl_move"), isOn: $vm.createSubfolders)
                }
            }.padding()
            Button(vm.t("btn_done")) { dismiss() }.buttonStyle(.borderedProminent).padding()
        }.frame(width: 400, height: 500)
    }
}

struct DisambiguationSheetView: View {
    let ambiguity: AmbiguousMatch
    let onSelect: (DisambiguationCandidate) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: MediaOrganizerViewModel
    var body: some View {
        VStack {
            Text(vm.t("sheet_title")).font(.title2).padding()
            List(ambiguity.candidates) { cand in
                Button(action: { onSelect(cand) }) {
                    HStack {
                        Text(cand.title).bold(); Spacer()
                        VStack(alignment: .trailing) { Text(cand.year).font(.body); if !cand.date.isEmpty { Text(cand.date).font(.caption).foregroundColor(.secondary) } }
                    }
                }
            }
            Button(vm.t("sheet_cancel")) { dismiss() }.padding()
        }.frame(minWidth: 400, minHeight: 500)
    }
}
