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
    @Published var albumArtist: Artist? = nil
    @Published var albumArtworkData: Data? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var currentAlbumID: String? = nil

    // MARK: - Initialization
    init(interactor: AlbumDetailInteractorProtocol) {
        self.interactor = interactor
    }

    // MARK: - Commands (Actions from UI)
    func loadAlbum(by id: String) {
        if id == currentAlbumID {
            return
        }
        
        currentAlbumID = id
        
        Task {
            await loadAlbumAsync(by: id)
        }
    }

    func loadAlbumArtwork(from urlString: String) {
        Task {
            await loadAlbumArtworkAsync(from: urlString)
        }
    }

    func playSong(_ song: Song) {
        Task {
            guard let album = self.album else {
                await self.interactor.playSong(with: song.id, from: [song.id])
                return
            }
            await self.interactor.playSong(with: song.id, from: album.songIDs)
        }
    }

    // MARK: - Load Artist
    func loadArtist(by id: String) {
        Task {
            await loadArtistAsync(by: id)
        }
    }

    // MARK: - Private Async Methods
    private func loadAlbumAsync(by id: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            if self.album?.id != id {
                self.album = nil
                self.songs = []
                self.albumArtist = nil
                self.albumArtworkData = nil
            }
        }

        do {
            guard let (album, songs) = try await interactor.loadAlbum(by: id) else {
                await MainActor.run {
                    self.errorMessage = "Album not found"
                }
                return
            }

            await MainActor.run {
                self.album = album
                self.songs = songs
            }

            await loadArtistAsync(by: album.artistID)

            if let artworkURL = album.artworkURL {
                await loadAlbumArtworkAsync(from: artworkURL)
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

    private func loadArtistAsync(by id: String) async {
        do {
            guard let artist = try await interactor.fetchArtist(by: id) else {
                return
            }
            await MainActor.run {
                self.albumArtist = artist
            }
        } catch {
            print("DEBUG: AlbumDetailViewModel: Ошибка загрузки артиста \(id): \(error)")
        }
    }

    private func loadAlbumArtworkAsync(from urlString: String) async {
        do {
            guard let imageData = try await interactor.fetchImageData(from: urlString) else {
                return
            }
            await MainActor.run {
                self.albumArtworkData = imageData
            }
        } catch {
            print("DEBUG: AlbumDetailViewModel: Ошибка загрузки обложки \(urlString): \(error)")
        }
    }
}
