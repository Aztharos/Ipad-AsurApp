//MangasViewModel.swift

import SwiftUI
import CoreGraphics
import CoreText
import UIKit
import Foundation

class MangasViewModel: ObservableObject {
    @Published var mangas = MangaStorage.loadMangas()
    @Published var mangaName = ""
    @Published var mangaURL = ""
    @Published var lastChapter = ""
    @Published var errorMessage = ""
    @Published var sortOption: SortOption = .priority
    
    enum SortOption {
        case priority
        case name
        case date
    }
    
    init() {
        loadFont(named: "mangatb", withExtension: "ttf")
        loadFont(named: "animeace2_bld", withExtension: "ttf")
    }
    
    func loadFont(named fontName: String, withExtension ext: String) {
        guard let fontURL = Bundle.main.url(forResource: fontName, withExtension: ext),
              let fontData = try? Data(contentsOf: fontURL) else { return }
        let provider = CGDataProvider(data: fontData as CFData)
        guard let font = CGFont(provider!) else { return }
        CTFontManagerRegisterGraphicsFont(font, nil)
    }
    
    func addManga() {
        guard !mangaName.isEmpty, !mangaURL.isEmpty else {
            errorMessage = "Tous les champs doivent être remplis."
            return
        }
        if let url = URL(string: mangaURL), UIApplication.shared.canOpenURL(url) {
            let newManga = Manga(
                name: mangaName,
                url: mangaURL,
                lastChapter: lastChapter.isEmpty ? "1" : lastChapter,
                newChapter: nil,
                chaptersUpdatedAt: Date(),
                lastChapterDate: Date()
            )
            if mangas.contains(where: { $0.url == mangaURL }) {
                errorMessage = "Ce manga est déjà enregistré."
                return
            }
            mangas.append(newManga)
            MangaStorage.saveMangas(mangas)
            mangaName = ""
            mangaURL = ""
            lastChapter = ""
            errorMessage = ""
        } else {
            errorMessage = "URL invalide."
        }
    }
    
    func checkForUpdates() {
        for index in mangas.indices {
            let manga = mangas[index]
            guard let lastChapterNumber = Int(manga.lastChapter) else {
                print("Impossible de convertir le chapitre en entier.")
                continue
            }
            let nextChapterNumber = lastChapterNumber + 1
            let nextChapterURL = manga.url.replacingOccurrences(of: "/chapter/\(lastChapterNumber)", with: "/chapter/\(nextChapterNumber)")
            guard let url = URL(string: nextChapterURL) else { continue }
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.mangas[index].newChapter = String(nextChapterNumber)
                        self.mangas[index].chaptersUpdatedAt = Date()
                        MangaStorage.saveMangas(self.mangas)
                    }
                }
            }.resume()
        }
    }
    
    func sortedMangas() -> [Manga] {
        switch sortOption {
        case .priority:
            return mangas.sorted { ($0.newChapter != nil ? 0 : 1) < ($1.newChapter != nil ? 0 : 1) }
        case .name:
            return mangas.sorted {
                if $0.newChapter != nil && $1.newChapter == nil {
                    return true
                } else if $0.newChapter == nil && $1.newChapter != nil {
                    return false
                } else {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }
        case .date:
            return mangas.sorted { $0.chaptersUpdatedAt > $1.chaptersUpdatedAt }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func exportMangasToFile() {
        let mangas = MangaStorage.loadMangas()
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(mangas) {
            let fileName = "mangas_backup.json"
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                try encodedData.write(to: fileURL)
                print("Données exportées vers \(fileURL)")
                errorMessage = "Exportation réussie !"    
                shareFile(fileURL: fileURL)               
            } catch {
                print("Erreur lors de l'écriture du fichier : \(error)")
                errorMessage = "Erreur d'exportation."
            }
        } else {
            errorMessage = "Erreur de conversion des données."
        }
    }
    
    func importMangasFromFile() {
        guard let fileURL = Bundle.main.url(forResource: "mangas_backup", withExtension: "json") else {
            print("mangas_backup.json introuvable dans le bundle.")
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let decodedMangas = try decoder.decode([Manga].self, from: data)
            mangas = decodedMangas
            MangaStorage.saveMangas(mangas)
            print("Mangas chargés avec succès depuis le bundle.")
        } catch {
            print("Erreur lors du chargement des mangas depuis le fichier: \(error)")
        }
    }
   
    func shareFile(fileURL: URL) {
        DispatchQueue.main.async {
            let activityViewController = ActivityViewController(activityItems: [fileURL])
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                let hostingController = UIHostingController(rootView: activityViewController)
                rootVC.present(hostingController, animated: true, completion: nil)
            }
        }
    }
    
    struct ActivityViewController: UIViewControllerRepresentable {
        var activityItems: [Any]   
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            return activityViewController
        }
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        }
    }

 func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func openLastReadChapter(for manga: Manga) {
        if let url = URL(string: manga.url), UIApplication.shared.canOpenURL(url) {
            openURLInSafari(url: url)
        }
    }
    
    func openNewChapter(for manga: Manga) {
        guard let newChapter = manga.newChapter,
              let lastChapterNumber = Int(manga.lastChapter) else { return }
        let chapterURL = manga.url.replacingOccurrences(of: "/chapter/\(lastChapterNumber)", with: "/chapter/\(newChapter)")
        if let url = URL(string: chapterURL), UIApplication.shared.canOpenURL(url) {
            openURLInSafari(url: url)
            if let index = mangas.firstIndex(where: { $0.id == manga.id }) {
                mangas[index].lastChapter = newChapter
                mangas[index].url = chapterURL
                mangas[index].newChapter = nil
                mangas[index].lastChapterDate = Date()
                MangaStorage.saveMangas(mangas)
            }
            checkForUpdates()
        }
    }
    
    func confirmAndDeleteManga(manga: Manga) {
        let alert = UIAlertController(title: "Confirmation", message: "Voulez-vous vraiment supprimer ce manga ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Supprimer", style: .destructive, handler: { _ in
            if let index = self.mangas.firstIndex(where: { $0.id == manga.id }) {
                self.mangas.remove(at: index)
                MangaStorage.saveMangas(self.mangas)
            }
        }))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }
}


