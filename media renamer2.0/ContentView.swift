//
//  ContentView.swift
//  Regia
//
//  Description: A native macOS app for organizing and renaming media files
//  using TMDB metadata with a "Plex-friendly" focus. Made with the help of AI
//
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import FoundationModels
import NaturalLanguage

// MARK: - Localizzazione & Lingue

enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "Italiano"
    case english = "English"
    
    var id: String { self.rawValue }
    
    // Codice per API TMDB
    var apiCode: String {
        switch self {
        case .italian: return "it-IT"
        case .english: return "en-US"
        }
    }
}

struct Strings {
    static func get(_ key: String, lang: AppLanguage) -> String {
        let dict: [String: [AppLanguage: String]] = [
            "tab_organizer": [.italian: "Regia", .english: "Regia"],
            "tab_settings": [.italian: "Impostazioni", .english: "Settings"],
            "status_ready": [.italian: "Pronto", .english: "Ready"],
            "status_not_found": [.italian: "Non Trovato", .english: "Not Found"],
            "status_manual": [.italian: "Pronto (Manuale)", .english: "Ready (Manual)"],
            "status_moved": [.italian: "Spostato!", .english: "Moved!"],
            "status_restored": [.italian: "Ripristinato", .english: "Restored"],
            "status_error_move": [.italian: "Errore Spostamento", .english: "Move Error"],
            "status_error_net": [.italian: "Errore Rete", .english: "Network Error"],
            "status_error_parse": [.italian: "Errore Parsing", .english: "Parsing Error"],
            "btn_open": [.italian: "Apri", .english: "Open"],
            "btn_scan": [.italian: "Scan", .english: "Scan"],
            "btn_reset": [.italian: "Reset", .english: "Reset"],
            "btn_undo": [.italian: "Annulla", .english: "Undo"],
            "btn_tmdb": [.italian: "TMDB", .english: "TMDB"],
            "btn_process": [.italian: "Elabora", .english: "Process"],
            "msg_ready": [.italian: "Pronto. Seleziona cartella o trascina file.", .english: "Ready. Select folder or drag files."],
            "msg_adding": [.italian: "Aggiunta file...", .english: "Adding files..."],
            "msg_added": [.italian: "Aggiunta completata.", .english: "Add completed."],
            "msg_scanning": [.italian: "Scansione...", .english: "Scanning..."],
            "msg_no_files": [.italian: "Nessun file video trovato.", .english: "No video files found."],
            "msg_scan_done": [.italian: "Scansione completata.", .english: "Scan completed."],
            "msg_cleaned": [.italian: "Lista pulita.", .english: "List cleared."],
            "msg_searching": [.italian: "Ricerca metadati...", .english: "Searching metadata..."],
            "msg_search_done": [.italian: "Ricerca completata.", .english: "Search completed."],
            "msg_processing": [.italian: "Elaborazione...", .english: "Processing..."],
            "msg_done": [.italian: "Fatto!", .english: "Done!"],
            "msg_undoing": [.italian: "Ripristino in corso...", .english: "Restoring..."],
            "msg_undo_done": [.italian: "Ripristinati", .english: "Restored"],
            "msg_retry": [.italian: "Riprovo con:", .english: "Retrying with:"],
            "msg_manual_search": [.italian: "Ricerca manuale:", .english: "Manual search:"],
            "err_no_folder": [.italian: "Errore: Nessuna cartella selezionata.", .english: "Error: No folder selected."],
            "err_no_api": [.italian: "Errore: API Key TMDB mancante.", .english: "Error: Missing TMDB API Key."],
            "err_no_ready": [.italian: "Nessun file pronto.", .english: "No files ready."],
            "err_ambiguous": [.italian: "Risolvi le ambiguità dei file selezionati.", .english: "Resolve ambiguities for selected files."],
            "col_original": [.italian: "File Originale", .english: "Original File"],
            "col_proposed": [.italian: "Nome Proposto", .english: "Proposed Name"],
            "col_status": [.italian: "Stato", .english: "Status"],
            "sheet_title": [.italian: "Scegli titolo", .english: "Choose title"],
            "sheet_cancel": [.italian: "Annulla", .english: "Cancel"],
            "sec_api": [.italian: "API", .english: "API"],
            "sec_format": [.italian: "Formattazione", .english: "Formatting"],
            "sec_folders": [.italian: "Cartelle", .english: "Folders"],
            "sec_language": [.italian: "Lingua", .english: "Language"],
            "lbl_format": [.italian: "Formato Nomi", .english: "Naming Format"],
            "lbl_subfolders": [.italian: "Scansiona sottocartelle", .english: "Scan subfolders"],
            "lbl_move": [.italian: "Sposta in sottocartelle", .english: "Move to subfolders"],
            "lbl_lang": [.italian: "Lingua App", .english: "App Language"],
            "alert_confirm_title": [.italian: "Conferma", .english: "Confirm"],
            "alert_confirm_msg": [.italian: "Avviare rinomina/spostamento?", .english: "Start rename/move?"],
            "alert_manual_title": [.italian: "Ricerca Manuale", .english: "Manual Search"],
            "btn_search": [.italian: "Cerca", .english: "Search"]
        ]
        return dict[key]?[lang] ?? key
    }
}

// MARK: - Enums e Strutture Dati

struct DisambiguationCandidate: Identifiable {
    let id: String
    let title: String
    let year: String
    let date: String
}

struct AmbiguousMatch: Identifiable {
    let id = UUID()
    let fileIndices: [Int]
    let candidates: [DisambiguationCandidate]
    let isTV: Bool
}

struct RenameHistoryItem {
    let originalURL: URL
    let newURL: URL
    let fileID: UUID
}

// FIX: Formattazione Localizzata
enum RenameFormat: String, CaseIterable, Identifiable {
    case standard = "standard"
    case scene = "scene"
    case plex = "plex"
    
    var id: String { self.rawValue }
    
    func label(for lang: AppLanguage) -> String {
        switch self {
        case .standard:
            return lang == .italian ? "Titolo (Anno)" : "Title (Year)"
        case .scene:
            return lang == .italian ? "Titolo.Anno" : "Title.Year"
        case .plex:
            return lang == .italian ? "Titolo (Anno) {tmdb-id}" : "Title (Year) {tmdb-id}"
        }
    }
}

// MARK: - Modelli API (Solo TMDB)

struct TMDBResponse<T: Codable>: Codable { let results: [T] }

struct MovieResult: Codable, Identifiable {
    let id: Int
    let title: String
    let releaseDate: String?
    enum CodingKeys: String, CodingKey {
        case id, title
        case releaseDate = "release_date"
    }
    var year: String {
        guard let d = releaseDate, d.count >= 4 else { return "N/A" }
        return String(d.prefix(4))
    }
}

struct TVResult: Codable, Identifiable {
    let id: Int
    let name: String
    let firstAirDate: String?
    enum CodingKeys: String, CodingKey {
        case id, name
        case firstAirDate = "first_air_date"
    }
    var year: String {
        guard let d = firstAirDate, d.count >= 4 else { return "N/A" }
        return String(d.prefix(4))
    }
}

// MARK: - Enum Status

enum FileStatus {
    case pronto
    case nonTrovato
    case manuale
    case spostato
    case ripristinato
    case erroreSpostamento
    case erroreRete
    case erroreRegex
    
    func label(for lang: AppLanguage) -> String {
        switch self {
        case .pronto: return Strings.get("status_ready", lang: lang)
        case .nonTrovato: return Strings.get("status_not_found", lang: lang)
        case .manuale: return Strings.get("status_manual", lang: lang)
        case .spostato: return Strings.get("status_moved", lang: lang)
        case .ripristinato: return Strings.get("status_restored", lang: lang)
        case .erroreSpostamento: return Strings.get("status_error_move", lang: lang)
        case .erroreRete: return Strings.get("status_error_net", lang: lang)
        case .erroreRegex: return Strings.get("status_error_parse", lang: lang)
        }
    }
}

// MARK: - Classe MediaFile

final class MediaFile: ObservableObject, Identifiable {
    let id = UUID()
    let originalURL: URL
    let originalName: String
    @Published var proposedName: String
    @Published var isSelected: Bool
    @Published var status: FileStatus
    @Published var isTVShow: Bool
    @Published var tmdbID: String = ""
    var parsedSeason: String?
    var parsedEpisode: String?
    @Published var ambiguousCandidates: [DisambiguationCandidate]? = nil

    init(url: URL, status: FileStatus, proposedName: String = "", isSelected: Bool = false, isTVShow: Bool = false,
         tmdbID: String = "", parsedSeason: String? = nil, parsedEpisode: String? = nil) {
        self.originalURL = url
        self.originalName = url.lastPathComponent
        self.status = status
        self.proposedName = proposedName
        self.isSelected = isSelected
        self.isTVShow = isTVShow
        self.tmdbID = tmdbID
        self.parsedSeason = parsedSeason
        self.parsedEpisode = parsedEpisode
    }
}

// MARK: - Logica "Anchor"

func cleanFileName(_ raw: String) -> (title: String, year: String?) {
    let nsString = raw as NSString
    let nameWithoutExt = nsString.deletingPathExtension
    let clean = nameWithoutExt.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ")
    
    let yearPattern = try! NSRegularExpression(pattern: #"\b(19\d{2}|20\d{2})\b"#)
    let range = NSRange(clean.startIndex..., in: clean)
    
    // Strategia 1: Anno trovato
    if let match = yearPattern.firstMatch(in: clean, options: [], range: range),
       let yRange = Range(match.range, in: clean) {
        let yearFound = String(clean[yRange])
        let titlePart = String(clean[..<yRange.lowerBound])
        return (cleanupTitleString(titlePart), yearFound)
    }
    
    // Strategia 2: Serie TV senza anno
    let tvAnchor = try! NSRegularExpression(pattern: #"(?i)\b(s\d{1,2}e\d{1,3}|\d{1,2}x\d{1,3})\b"#)
    if let match = tvAnchor.firstMatch(in: clean, options: [], range: range),
       let tRange = Range(match.range, in: clean) {
        let titlePart = String(clean[..<tRange.lowerBound])
        return (cleanupTitleString(titlePart), nil)
    }
    
    return (cleanupTitleString(clean), nil)
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
    let clean = illegal.reduce(name) { $0.replacingOccurrences(of: $1, with: " ") }
    return clean.trimmingCharacters(in: .whitespaces)
}

func calcolaETA(processed: Int, total: Int, startTime: Date) -> String {
    guard processed > 0 else { return "..." }
    let elapsed = Date().timeIntervalSince(startTime)
    let remaining = (elapsed / Double(processed)) * Double(total - processed)
    if remaining < 60 { return "\(Int(remaining)) sec" }
    return "\(Int(remaining / 60)) min"
}

// MARK: - ViewModel Principale

@MainActor
final class MediaOrganizerViewModel: ObservableObject {
    @Published var fileList: [MediaFile] = []
    @Published var selectedFolderURL: URL?
    @Published var statusText = "..."
    @Published var isScanning = false
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var etaText: String = ""
    
    @Published var isShowingRetryAlert = false
    @Published var retrySearchName = ""
    @Published var targetFileForManualSearch: MediaFile? = nil
    
    // Configurazione
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
    
    let episodeRegex = try! NSRegularExpression(
        pattern: #"(?i)(?:s|stagione|^)[.\s]*(\d{1,2})[.\s]*(?:e|ep|episodio|x|-)[.\s]*(\d{1,3})|(\d{1,2})x(\d{1,3})"#, options: []
    )
    let absoluteEpRegex = try! NSRegularExpression(
        pattern: #"(?i)(?:^|[\s_\-\[])(?:e|ep|episodio)[.\s]*(\d{2,4})(?:[\s_\-\]]|$)"#, options: []
    )
    
    init() {
        self.statusText = Strings.get("msg_ready", lang: .italian)
    }
    
    func t(_ key: String) -> String {
        return Strings.get(key, lang: appLanguage)
    }
    
    func updateStatusReady() {
        self.statusText = t("msg_ready")
    }

    // MARK: Parsing Info Episodi
    func parseEpisodeInfo(from name: String) -> (isTV: Bool, season: String?, episode: String?) {
        let ns = NSRange(name.startIndex..., in: name)
        if let m = episodeRegex.firstMatch(in: name, range: ns) {
            let sRange = m.range(at: 1).location != NSNotFound ? m.range(at: 1) : m.range(at: 3)
            let eRange = m.range(at: 2).location != NSNotFound ? m.range(at: 2) : m.range(at: 4)
            if let rS = Range(sRange, in: name), let rE = Range(eRange, in: name) {
                let s = String(format: "%02d", Int(name[rS]) ?? 0)
                let e = String(format: "%02d", Int(name[rE]) ?? 0)
                return (true, s, e)
            }
        }
        if let m = absoluteEpRegex.firstMatch(in: name, range: ns), let r = Range(m.range(at: 1), in: name) {
            let e = String(format: "%02d", Int(name[r]) ?? 0)
            return (true, nil, e)
        }
        return (false, nil, nil)
    }

    // MARK: Drag & Drop
    func addDroppedFiles(urls: [URL]) {
        guard !apiKey.isEmpty else { statusText = t("err_no_api"); return }

        let videoExts = Set(videoExtensions.map { $0.lowercased() })
        let candidates = urls.filter { videoExts.contains($0.pathExtension.lowercased()) }
        guard !candidates.isEmpty else { return }

        if self.selectedFolderURL == nil, let first = candidates.first {
            self.selectedFolderURL = first.deletingLastPathComponent()
        }

        statusText = t("msg_adding")
        isScanning = true; progress = 0
        
        Task {
            var newFiles: [MediaFile] = []
            for url in candidates {
                let parsed = parseEpisodeInfo(from: url.lastPathComponent)
                let mf = MediaFile(url: url, status: .pronto, isTVShow: parsed.isTV,
                                   parsedSeason: parsed.season, parsedEpisode: parsed.episode)
                newFiles.append(mf)
            }
            await searchNamesForFiles(newFiles)
            self.fileList.append(contentsOf: newFiles)
            self.statusText = self.t("msg_added")
        }
    }
    
    // MARK: Scansione
    func scanFolder() {
        guard let baseURL = selectedFolderURL else { statusText = t("err_no_folder"); return }
        guard !apiKey.isEmpty else { statusText = t("err_no_api"); return }

        statusText = t("msg_scanning"); isScanning = true; progress = 0; etaText = ""
        
        Task {
            let access = baseURL.startAccessingSecurityScopedResource()
            defer { if access { baseURL.stopAccessingSecurityScopedResource() } }

            let fm = FileManager.default
            var urls: [URL] = []
            if includeSubfolders {
                if let en = fm.enumerator(at: baseURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    while let obj = en.nextObject() { if let url = obj as? URL { urls.append(url) } }
                }
            } else {
                if let contents = try? fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    urls = contents
                }
            }

            let videoExts = Set(self.videoExtensions.map { $0.lowercased() })
            let candidates = urls.filter { videoExts.contains($0.pathExtension.lowercased()) }
            
            if candidates.isEmpty {
                await MainActor.run { self.statusText = self.t("msg_no_files"); self.isScanning = false }
                return
            }

            var newFiles: [MediaFile] = []
            for url in candidates {
                let parsed = self.parseEpisodeInfo(from: url.lastPathComponent)
                let mf = MediaFile(url: url, status: .pronto, isTVShow: parsed.isTV, parsedSeason: parsed.season, parsedEpisode: parsed.episode)
                newFiles.append(mf)
            }
            
            await self.searchNamesForFiles(newFiles)
            
            await MainActor.run {
                self.fileList = newFiles
                self.statusText = self.t("msg_scan_done"); self.isScanning = false; self.progress = 0
            }
        }
    }
    
    func resetAll() {
        isScanning = false; isProcessing = false; progress = 0
        fileList.removeAll(); ambiguousMatches.removeAll(); undoHistory.removeAll()
        currentAmbiguity = nil; statusText = t("msg_cleaned")
    }
    
    // MARK: Ricerca
    func searchNamesForFiles(_ files: [MediaFile]) async {
        await MainActor.run { statusText = self.t("msg_searching") }
        progress = 0
        let total = files.count; let start = Date()
        var processed = 0
        
        for file in files {
            if apiKey.isEmpty { file.status = .erroreRete; continue }
            if file.isTVShow && (file.parsedSeason == nil || file.parsedEpisode == nil) {
                file.status = .erroreRegex; processed += 1; continue
            }
            await searchName(for: file)
            processed += 1
            await MainActor.run {
                progress = Double(processed) / Double(total)
                if processed > 3 { etaText = calcolaETA(processed: processed, total: total, startTime: start) }
            }
        }
        
        await MainActor.run {
            isScanning = false; statusText = self.t("msg_search_done")
            checkForAmbiguities()
            if !ambiguousMatches.isEmpty { currentAmbiguity = ambiguousMatches.first }
        }
    }
    
    func searchName(for file: MediaFile, overrideQuery: String? = nil, year: String? = nil) async {
        var (query, yearToUse) = ("", year)
        if let q = overrideQuery, !q.isEmpty {
            query = q
        } else {
            let cleaned = cleanFileName(file.originalName)
            query = cleaned.title; yearToUse = cleaned.year
        }
        
        guard !query.isEmpty else { file.status = .nonTrovato; return }
        
        do {
            if file.isTVShow {
                let results: [TVResult] = try await fetchFromTMDB(query: query, endpoint: "search/tv", year: yearToUse)
                handleResults(results, file: file)
            } else {
                let results: [MovieResult] = try await fetchFromTMDB(query: query, endpoint: "search/movie", year: yearToUse)
                handleResults(results, file: file)
            }
        } catch { file.status = .erroreRete }
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
            file.status = .nonTrovato
            file.ambiguousCandidates = cands
        } else if let first = sortedResults.first {
            applyFromAPI(first, to: file)
        } else {
            file.status = .nonTrovato
        }
    }
    
    // MARK: - Applicazione Nomi
    
    func applyFromAPI<T: Identifiable>(_ item: T, to file: MediaFile) {
        let title: String
        let year: String
        let id: String
        
        if let m = item as? MovieResult {
            title = m.title; year = m.year; id = "\(m.id)"
        } else if let t = item as? TVResult {
            title = t.name; year = t.year; id = "\(t.id)"
        } else { return }
        
        generateAndSetProposedName(title: title, year: year, id: id, file: file)
    }
    
    func applyFromCandidate(_ cand: DisambiguationCandidate, to file: MediaFile) {
        generateAndSetProposedName(title: cand.title, year: cand.year, id: cand.id, file: file)
    }
    
    private func generateAndSetProposedName(title: String, year: String, id: String, file: MediaFile) {
        file.tmdbID = id
        
        var finalName = ""
        switch renameFormat {
        case .standard: finalName = "\(title) (\(year))"
        case .scene:
            let safeTitle = title.replacingOccurrences(of: " ", with: ".")
            finalName = "\(safeTitle).\(year)"
        case .plex: finalName = "\(title) (\(year)) {tmdb-\(id)}"
        }
        
        if file.isTVShow {
            if let s = file.parsedSeason, let e = file.parsedEpisode {
                let sep = renameFormat == .scene ? "." : " "
                finalName += "\(sep)S\(s)E\(e)"
            }
        }
        
        file.proposedName = sanitizeFileName(finalName)
        file.status = .pronto
        file.isSelected = true
        file.ambiguousCandidates = nil
    }

    // MARK: - Retry Search
    
    func prepareManualSearch(for file: MediaFile) {
        self.targetFileForManualSearch = file
        let cleaned = cleanFileName(file.originalName)
        self.retrySearchName = cleaned.title
        self.isShowingRetryAlert = true
    }
    
    func retrySearchManual(name: String) {
        let q = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        guard !apiKey.isEmpty else { statusText = t("err_no_api"); return }
        
        let toRetry: [MediaFile]
        if let target = targetFileForManualSearch {
            toRetry = [target]
        } else {
            toRetry = fileList.filter { $0.isSelected || [.nonTrovato, .erroreRete, .erroreRegex].contains($0.status) }
        }
        
        statusText = "\(t("msg_manual_search")) '\(q)'..."
        isScanning = true; progress = 0
        
        Task {
            let total = toRetry.count; var processed = 0
            for f in toRetry {
                await searchName(for: f, overrideQuery: q)
                processed += 1
                await MainActor.run { progress = Double(processed) / Double(total) }
            }
            await MainActor.run {
                isScanning = false; statusText = self.t("msg_done"); retrySearchName = ""
                
                checkForAmbiguities()
                if let target = targetFileForManualSearch {
                    if let match = ambiguousMatches.first(where: { $0.fileIndices.contains { idx in fileList[idx].id == target.id } }) {
                        currentAmbiguity = match
                    }
                } else if !ambiguousMatches.isEmpty {
                    currentAmbiguity = ambiguousMatches.first
                }
                
                targetFileForManualSearch = nil
            }
        }
    }

    // MARK: - Chiamate API (Solo TMDB)
    
    func fetchFromTMDB<T: Codable>(query: String, endpoint: String, year: String? = nil) async throws -> [T] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { throw URLError(.badURL) }
        var urlStr = "https://api.themoviedb.org/3/\(endpoint)?api_key=\(apiKey)&query=\(encoded)&language=\(appLanguage.apiCode)"
        if let y = year, !y.isEmpty { urlStr += endpoint == "search/tv" ? "&first_air_date_year=\(y)" : "&year=\(y)" }
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TMDBResponse<T>.self, from: data).results
    }

    // MARK: - Elaborazione & Undo
    
    func startProcessing() {
        guard let baseURL = selectedFolderURL else { statusText = t("err_no_folder"); return }
        
        checkForAmbiguities()
        
        let blockingMatch = ambiguousMatches.first { match in match.fileIndices.contains { fileList[$0].isSelected } }
        
        if let blocking = blockingMatch {
            pendingProcessAfterDisambiguation = true
            currentAmbiguity = blocking
            statusText = t("err_ambiguous")
            return
        }
        
        let toProcess = fileList.filter { $0.isSelected && !$0.proposedName.isEmpty }
        guard !toProcess.isEmpty else { statusText = t("err_no_ready"); return }
        
        isProcessing = true; statusText = t("msg_processing"); progress = 0; undoHistory.removeAll()
        
        Task(priority: .userInitiated) {
            let fm = FileManager.default
            let total = toProcess.count; var processed = 0
            
            let access = baseURL.startAccessingSecurityScopedResource()
            defer { if access { baseURL.stopAccessingSecurityScopedResource() } }
            
            for file in toProcess {
                let ext = file.originalURL.pathExtension
                let newName = file.proposedName
                var destURL: URL
                
                if createSubfolders {
                    do {
                        let folder: URL
                        if file.isTVShow {
                            let regex = try! NSRegularExpression(pattern: #"^(.* \(\d{4}\)).*?(S\d{2})E(\d{2,3})$"#)
                            if let match = regex.firstMatch(in: newName, range: NSRange(newName.startIndex..., in: newName)),
                               let seriesRange = Range(match.range(at: 1), in: newName),
                               let seasonRange = Range(match.range(at: 2), in: newName) {
                                let series = String(newName[seriesRange])
                                let seasonNum = String(newName[seasonRange].dropFirst())
                                let root = sanitizeFileName(series)
                                folder = baseURL.appendingPathComponent(root).appendingPathComponent("Season \(seasonNum)", isDirectory: true)
                            } else { folder = baseURL.appendingPathComponent(sanitizeFileName(newName)) }
                        } else { folder = baseURL.appendingPathComponent(sanitizeFileName(newName)) }
                        
                        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
                        destURL = folder.appendingPathComponent("\(newName).\(ext)")
                    } catch {
                        await MainActor.run { file.status = .erroreSpostamento }; processed += 1; continue
                    }
                } else {
                    destURL = file.originalURL.deletingLastPathComponent().appendingPathComponent("\(newName).\(ext)")
                }
                
                do {
                    let historyItem = RenameHistoryItem(originalURL: file.originalURL, newURL: destURL, fileID: file.id)
                    try fm.moveItem(at: file.originalURL, to: destURL)
                    await MainActor.run {
                        file.status = .spostato
                        self.undoHistory.append(historyItem)
                    }
                } catch {
                    await MainActor.run { file.status = .erroreSpostamento }
                }
                processed += 1
                await MainActor.run { progress = Double(processed) / Double(total) }
            }
            
            await MainActor.run {
                isProcessing = false; statusText = self.t("msg_done")
                for f in toProcess where f.status == .spostato { f.isSelected = false }
            }
        }
    }
    
    func undoLastOperation() {
        guard !undoHistory.isEmpty else { statusText = ""; return }
        statusText = t("msg_undoing")
        let fm = FileManager.default
        var restoredCount = 0
        
        for item in undoHistory {
            do {
                try fm.moveItem(at: item.newURL, to: item.originalURL)
                if let file = fileList.first(where: { $0.id == item.fileID }) {
                    file.status = .ripristinato
                    file.isSelected = true
                }
                restoredCount += 1
            } catch { print("Errore Undo: \(error)") }
        }
        undoHistory.removeAll()
        statusText = "\(t("msg_undo_done")) \(restoredCount)."
    }
    
    // Helpers
    func selectAll() { fileList.filter { [.pronto, .manuale].contains($0.status) }.forEach { $0.isSelected = true } }
    func deselectAll() { fileList.forEach { $0.isSelected = false } }
    
    func checkForAmbiguities() {
        var matches: [AmbiguousMatch] = []
        for (i, file) in fileList.enumerated() {
            if file.status == .nonTrovato, let cands = file.ambiguousCandidates, !cands.isEmpty {
                matches.append(AmbiguousMatch(fileIndices: [i], candidates: cands, isTV: file.isTVShow))
            }
        }
        ambiguousMatches = matches
    }
    
    func resolveAmbiguity(selected: DisambiguationCandidate) {
        guard let current = currentAmbiguity else { return }
        for idx in current.fileIndices {
            let file = fileList[idx]
            applyFromCandidate(selected, to: file)
        }
        ambiguousMatches.removeAll(where: { $0.id == current.id })
        
        if pendingProcessAfterDisambiguation {
            currentAmbiguity = ambiguousMatches.first { match in
                match.fileIndices.contains { fileList[$0].isSelected }
            }
            if currentAmbiguity == nil {
                pendingProcessAfterDisambiguation = false
                startProcessing()
            }
        } else {
            currentAmbiguity = ambiguousMatches.first
        }
    }
}

// MARK: - UI Views

struct ContentView: View {
    @StateObject private var vm = MediaOrganizerViewModel()
    var body: some View {
        TabView {
            OrganizerView(vm: vm).tabItem { Label(Strings.get("tab_organizer", lang: vm.appLanguage), systemImage: "film") }
            SettingsView(vm: vm).tabItem { Label(Strings.get("tab_settings", lang: vm.appLanguage), systemImage: "gear") }
        }.frame(minWidth: 1100, minHeight: 700)
    }
}

struct OrganizerView: View {
    @ObservedObject var vm: MediaOrganizerViewModel
    @State private var showFolderPicker = false
    @State private var showProcessAlert = false
    
    @ViewBuilder
    private var scanningView: some View {
        VStack {
            Text(vm.statusText).font(.title2).padding(.bottom, 8)
            ProgressView(value: vm.progress).progressViewStyle(.linear).padding(.horizontal, 50)
            Text(vm.etaText).font(.caption).foregroundColor(.secondary).padding(.top, 4)
        }.frame(maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private func organizerToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { showFolderPicker = true } label: { Label(vm.t("btn_open"), systemImage: "folder") }.disabled(vm.isScanning)
            if let url = vm.selectedFolderURL { Text(url.lastPathComponent).font(.caption).foregroundColor(.secondary).lineLimit(1).frame(maxWidth: 150) }
            Button { vm.scanFolder() } label: { Label(vm.t("btn_scan"), systemImage: "magnifyingglass") }.disabled(vm.selectedFolderURL == nil || vm.isScanning)
            Button { vm.resetAll() } label: { Label(vm.t("btn_reset"), systemImage: "arrow.clockwise") }.disabled(vm.isScanning || vm.isProcessing)
            Button { vm.undoLastOperation() } label: { Label(vm.t("btn_undo"), systemImage: "arrow.uturn.backward") }
                .disabled(vm.undoHistory.isEmpty || vm.isProcessing)
                .keyboardShortcut("z", modifiers: .command)
            
            Button { vm.selectAll() } label: { Image(systemName: "checklist") }.disabled(vm.fileList.isEmpty)
            Button { vm.deselectAll() } label: { Image(systemName: "checklist.unchecked") }.disabled(vm.fileList.isEmpty)
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Button { vm.targetFileForManualSearch = nil; vm.isShowingRetryAlert = true } label: { Label(vm.t("btn_tmdb"), systemImage: "magnifyingglass.circle") }
                .help("Cerca manuale").disabled(vm.isScanning)
            
            Toggle(isOn: $vm.filterNonTrovati) { Image(systemName: "line.3.horizontal.decrease.circle") }
                .toggleStyle(.button).disabled(vm.fileList.isEmpty)
            
            Button { showProcessAlert = true } label: { Label(vm.t("btn_process"), systemImage: "sparkles.rectangle.stack") }
                .buttonStyle(.borderedProminent)
                .disabled(vm.fileList.isEmpty || vm.isScanning || vm.isProcessing)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isScanning {
                    scanningView
                } else if vm.fileList.isEmpty {
                    Text(vm.selectedFolderURL == nil ? vm.t("msg_ready") : vm.t("msg_no_files"))
                        .font(.title2).foregroundColor(.secondary).frame(maxHeight: .infinity)
                } else {
                    HStack {
                        Text(vm.t("col_original")).frame(maxWidth: .infinity, alignment: .leading)
                        Text(vm.t("col_proposed")).frame(maxWidth: .infinity, alignment: .leading)
                        Text(vm.t("col_status")).frame(width: 140, alignment: .leading)
                    }.font(.headline).padding(.horizontal).padding(.top, 8)
                    Divider()
                    List {
                        ForEach($vm.fileList) { $file in
                            if !vm.filterNonTrovati || [.nonTrovato, .erroreRete, .erroreRegex].contains(file.status) {
                                FileRowView(file: file, onManualSearch: {
                                    vm.prepareManualSearch(for: file)
                                }).environmentObject(vm)
                            }
                        }
                    }.listStyle(.plain)
                }
                Divider()
                HStack { Text(vm.statusText).font(.caption).lineLimit(1); Spacer() }
                .padding(8).background(Color(NSColor.windowBackgroundColor))
            }
            .navigationTitle(Strings.get("tab_organizer", lang: vm.appLanguage))
            .toolbar { organizerToolbar() }
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
                let group = DispatchGroup()
                var collected: [URL] = []
                for provider in providers {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) { collected.append(url) }
                        else if let url = item as? URL { collected.append(url) }
                        group.leave()
                    }
                }
                group.notify(queue: .main) { if !collected.isEmpty { vm.addDroppedFiles(urls: collected) } }
                return true
            }
            .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { res in
                if case let .success(url) = res { vm.selectedFolderURL = url; vm.updateStatusReady() }
            }
            .alert(vm.t("alert_confirm_title"), isPresented: $showProcessAlert) {
                Button(vm.t("sheet_cancel"), role: .cancel) { }
                Button(vm.t("btn_process"), role: .destructive) { vm.startProcessing() }
            } message: { Text(vm.t("alert_confirm_msg")) }
            .alert(vm.t("alert_manual_title"), isPresented: $vm.isShowingRetryAlert) {
                TextField("...", text: $vm.retrySearchName)
                Button(vm.t("btn_search")) {
                    vm.retrySearchManual(name: vm.retrySearchName)
                    vm.retrySearchName = ""
                }
                Button(vm.t("sheet_cancel"), role: .cancel) { vm.retrySearchName = ""; vm.targetFileForManualSearch = nil }
            }
            .sheet(item: $vm.currentAmbiguity) { amb in
                DisambiguationSheetView(ambiguity: amb, onSelect: { vm.resolveAmbiguity(selected: $0) })
                    .environmentObject(vm)
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var vm: MediaOrganizerViewModel
    var body: some View {
        Form {
            Section(vm.t("sec_api")) {
                SecureField("API Key TMDB", text: $vm.apiKey)
            }
            Section(vm.t("sec_language")) {
                Picker(vm.t("lbl_lang"), selection: $vm.appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .onChange(of: vm.appLanguage) { _, _ in
                    vm.updateStatusReady()
                }
            }
            Section(vm.t("sec_format")) {
                Picker(vm.t("lbl_format"), selection: $vm.renameFormat) {
                    ForEach(RenameFormat.allCases) { fmt in
                        Text(fmt.label(for: vm.appLanguage)).tag(fmt)
                    }
                }
            }
            Section(vm.t("sec_folders")) {
                Toggle(vm.t("lbl_subfolders"), isOn: $vm.includeSubfolders)
                Toggle(vm.t("lbl_move"), isOn: $vm.createSubfolders)
            }
        }.padding().frame(maxWidth: 500)
    }
}

struct FileRowView: View {
    @ObservedObject var file: MediaFile
    @EnvironmentObject var vm: MediaOrganizerViewModel
    var onManualSearch: () -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: $file.isSelected).toggleStyle(.checkbox).frame(width: 30)
            
            Text(file.originalName)
                .font(.caption).lineLimit(2)
                .foregroundColor(color(for: file.status))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("...", text: $file.proposedName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            
            HStack {
                Text(file.status.label(for: vm.appLanguage))
                    .font(.callout)
                    .foregroundColor(color(for: file.status))
                
                if file.status == .nonTrovato || file.status == .erroreRete || file.status == .erroreRegex {
                    Button(action: onManualSearch) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Search manually")
                }
            }
            .frame(width: 140, alignment: .leading)
        }.padding(.vertical, 4)
    }
    
    private func color(for s: FileStatus) -> Color {
        switch s {
        case .pronto, .manuale, .spostato, .ripristinato: return .primary
        default: return .red
        }
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
                        Text(cand.title).bold()
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(cand.year).font(.body)
                            if !cand.date.isEmpty && cand.date != "N/A" {
                                Text(cand.date).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            Button(vm.t("sheet_cancel")) { dismiss() }.padding()
        }.frame(minWidth: 400, minHeight: 500)
    }
}
