//MangaModel.swift

import SwiftUI
import Foundation
import UIKit

struct Manga: Identifiable, Codable {
    var id = UUID()
    var name: String
    var url: String
    var lastChapter: String
    var newChapter: String?
    var chaptersUpdatedAt: Date
    var lastChapterDate: Date?
}

class MangaStorage {
    private static let key = "savedMangas"
    
    static func saveMangas(_ mangas: [Manga]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(mangas) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func loadMangas() -> [Manga] {
        if let savedMangas = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            if let loadedMangas = try? decoder.decode([Manga].self, from: savedMangas) {
                return loadedMangas
            }
        }
        return []
    }
}

struct CustomButton: View {
    var icon: String
    var action: () -> Void
@Binding var color: Color
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 2)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.green)
                    .padding(3)
            }
            .frame(width: 30, height: 30)
        }
    }
}
struct CustomTextField: View {
    var placeholder: String
    @Binding var value: String
    @Binding var color: Color
    var body: some View {
        TextField(placeholder, text: $value)
            .padding(5)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(5)
            .font(.custom("AnimeAce2.0BB-Bold", size: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 2)
            )
    }
}

func toolbarButton(imageName: String, urlString: String) -> some View {
    Button(action: {
        if let url = URL(string: urlString) {
            openURLInSafari(url: url)
        }
    }) {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 35, height: 35)
    }
}


func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: icon)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(color)
    }
}
