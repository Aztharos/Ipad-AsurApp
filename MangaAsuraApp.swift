//MangaAsuraApp.swift

import SwiftUI
import SafariServices
import UIKit

@main
struct MangaAsuraApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
struct ContentView: View {
    @State private var isActive: Bool = true 

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    EmptyView()
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $isActive) {
                MangasView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationSplitViewStyle(.balanced)
            .navigationBarHidden(true)
        }
    }
}
    func openURLInSafari(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = UIColor.black
        safariVC.preferredControlTintColor = UIColor.systemPurple
        safariVC.dismissButtonStyle = .done
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(safariVC, animated: true, completion: nil)
        }
    }

