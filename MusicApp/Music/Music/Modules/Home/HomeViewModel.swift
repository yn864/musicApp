import Foundation
import SwiftUI
import Combine

// MARK: - HomeViewModel
class HomeViewModel: ObservableObject {
    // MARK: - Dependencies
    private let interactor: HomeInteractorProtocol

    // MARK: - State Properties
    @Published var albums: [Album] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var artworkCache: [String: Data] = [:]
    @Published var artistNames: [String: String] = [:]

    // MARK: - Initialization
    init(interactor: HomeInteractorProtocol) {
        self.interactor = interactor
    }

    // MARK: - Commands
    func loadRecommendations() {
        Task {
            await loadRecommendationsAsync()
        }
    }

    // MARK: - Private Async Methods
    private func loadRecommendationsAsync() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let albums = try await interactor.loadRecommendations()
            
            await withTaskGroup(of: Void.self) { group in
                for album in albums {
                    group.addTask {
                        await self.loadArtworkForAlbum(album)
                    }
                    group.addTask {
                        await self.loadArtistForAlbum(album)
                    }
                }
            }
            
            await MainActor.run {
                self.albums = albums
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func loadArtworkForAlbum(_ album: Album) async {
        if let artworkData = await interactor.loadAlbumArtwork(for: album) {
            await MainActor.run {
                self.artworkCache[album.id] = artworkData
            }
        }
    }
    
    private func loadArtistForAlbum(_ album: Album) async {
        if let name = await interactor.loadArtistName(for: album.artistID) {
            await MainActor.run {
                self.artistNames[album.artistID] = name
            }
        }
    }
}
