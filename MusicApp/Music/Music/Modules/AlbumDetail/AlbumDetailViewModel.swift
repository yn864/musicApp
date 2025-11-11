import Foundation
import SwiftUI
import Combine

// MARK: - AlbumDetailViewModel
class AlbumDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    private let interactor: AlbumDetailInteractorProtocol

    // MARK: - State Properties
    @Published var album: Album? = nil
    @Published var songs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Initialization
    init(interactor: AlbumDetailInteractorProtocol) {
        self.interactor = interactor
    }

    // MARK: - Commands (Actions from UI)
    func loadAlbum(by id: String) {
        Task {
            await loadAlbumAsync(by: id)
        }
    }

    func playSong(_ song: Song) {
        Task {
            await interactor.playSong(with: song.id)
        }
    }

    // MARK: - Private Async Methods
    private func loadAlbumAsync(by id: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // ❌ УБИРАЕМ ПРОВЕРКУ КЭША
            print("DEBUG: AlbumDetailViewModel: Загружаем альбом \(id) с API (без кэша).")
            // 1. ВСЕГДА получаем альбом и песни с API
            guard let (album, songs) = try await interactor.loadAlbum(by: id) else {
                await MainActor.run {
                    self.errorMessage = "Album not found"
                }
                return
            }

            await MainActor.run {
                self.album = album
                self.songs = songs
                print("DEBUG: AlbumDetailViewModel.songs обновлён, количество: \(songs.count)")
            }

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            self.isLoading = false
        }
    }
}
