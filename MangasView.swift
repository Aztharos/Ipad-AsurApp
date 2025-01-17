//MangasView.swift

import SwiftUI
import UIKit

extension Color {
    // Sauvegarder la couleur dans UserDefaults
    func saveToUserDefaults(key: String) {
        if let uiColor = UIColor(self).cgColor.components {
            let colorData: [CGFloat] = [uiColor[0], uiColor[1], uiColor[2], uiColor[3]]
            UserDefaults.standard.set(colorData, forKey: key)
        }
    }
    
    // Charger la couleur depuis UserDefaults
    static func loadFromUserDefaults(key: String) -> Color {
        if let colorData = UserDefaults.standard.array(forKey: key) as? [CGFloat], colorData.count == 4 {
            let color = Color(
                UIColor(red: colorData[0], green: colorData[1], blue: colorData[2], alpha: colorData[3])
            )
            return color
        }
        return Color.purple // Valeur par défaut si aucune couleur n'est trouvée
    }
}

struct MangasView: View {
    @StateObject private var viewModel = MangasViewModel()
    @State private var selectedColor: Color = .purple
    
    private let colorKey = "selectedColorKey"
    
    var body: some View {
        VStack {
            HStack {
                CustomTextField(placeholder: "Nom du manga", value: $viewModel.mangaName, color: $selectedColor)
                CustomTextField(placeholder: "URL du manga", value: $viewModel.mangaURL, color: $selectedColor)
                CustomTextField(placeholder: "Dernier chapitre lu", value: $viewModel.lastChapter, color: $selectedColor)
                    .onChange(of: viewModel.lastChapter) { newValue in
                        if viewModel.mangaURL.isEmpty {
                            viewModel.lastChapter = ""
                            return
                        }
                        if !newValue.allSatisfy({ $0.isNumber }) {
                            viewModel.lastChapter = newValue.filter { $0.isNumber }
                        }
                        if let lastChapterNumber = Int(viewModel.lastChapter),
                           let urlChapter = Int(viewModel.mangaURL.split(separator: "/").last ?? "") {
                            if lastChapterNumber > urlChapter {
                                viewModel.lastChapter = String(urlChapter)
                            }
                        }
                    }
                    .frame(width: 160)
                
                HStack(spacing: 20) {
                    CustomButton(icon: "plus", action: viewModel.addManga, color: $selectedColor)
                    CustomButton(icon: "arrow.clockwise", action: viewModel.checkForUpdates, color: $selectedColor)
                    CustomButton(icon: "square.and.arrow.up", action: viewModel.exportMangasToFile, color: $selectedColor)
                    CustomButton(icon: "square.and.arrow.down", action: viewModel.importMangasFromFile, color: $selectedColor)
                }
                .padding(5)
            }
            .padding(.horizontal, 20)
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.custom("manga temple", size: 14))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                  //add your website and logo here 
                    toolbarButton(imageName: "FR_Team", urlString: "https://fmteam.fr")
                    toolbarButton(imageName: "Demon", urlString: "https://demonicscans.org")
                    toolbarButton(imageName: "ori", urlString: "https://mangas-origines.fr/oeuvre/519-the-beginning-after-the-end/")
                    toolbarButton(imageName: "Comick", urlString: "https://comick.io/comic/hiding-a-logistics-center-in-the-apocalypse")
                    toolbarButton(imageName: "Solo", urlString: "https://reaper-scans.fr/chapter/1962fca878b-53a24d71af9/")
                    toolbarButton(imageName: "phenix", urlString: "https://phenixscans.fr/manga/solo-leveling-ragnarok/")
                    
                    Picker("Trier par :", selection: $viewModel.sortOption) {
                        Text("Priorité").tag(MangasViewModel.SortOption.priority)
                        Text("Nom").tag(MangasViewModel.SortOption.name)
                        Text("Date").tag(MangasViewModel.SortOption.date)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                        .padding()
                        .onChange(of: selectedColor) { newValue in
                            newValue.saveToUserDefaults(key: colorKey) // Sauvegarde de la couleur à chaque changement
                        }
                }
            }
        }
        ScrollView {
            ForEach(viewModel.sortedMangas()) { manga in
                HStack(spacing: 20) { 
                    Image("mangaLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                    VStack(alignment: .leading) {
                        Text(manga.name)
                            .font(.custom("manga temple", size: 18))
                            .foregroundColor(.purple)
                        Text("Dernier chapitre: \(manga.lastChapter)")
                            .font(.custom("AnimeAce2.0BB-Bold", size: 14))
                            .foregroundColor(.yellow)
                        if let newChapter = manga.newChapter {
                            Text("Nouveau chapitre: \(newChapter)")
                                .font(.custom("manga temple", size: 14))
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                    HStack(spacing: 25) {
                        if let lastChapterDate = manga.lastChapterDate {
                            Text(" \(viewModel.formattedDate(lastChapterDate))")
                                .font(.custom("AnimeAce2.0BB-Bold", size: 14))
                                .foregroundColor(selectedColor)
                        }
                        actionButton(icon: "link", color: .yellow) {
                            viewModel.openLastReadChapter(for: manga)
                        }
                        actionButton(icon: "link", color: .green) {
                            viewModel.openNewChapter(for: manga)
                        }
                        actionButton(icon: "trash", color: .red) {
                            viewModel.confirmAndDeleteManga(manga: manga)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(45)
                .overlay(
                    RoundedRectangle(cornerRadius: 45)
                        .stroke(selectedColor, lineWidth: 2)
                        .shadow(color: .red.opacity(0.5), radius: 4, x: 2, y: 2)
                )
            }
        }
        .padding()
        .onAppear {
            selectedColor = Color.loadFromUserDefaults(key: colorKey) 
        }
    }
}
