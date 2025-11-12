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
        guard id != currentAlbumID else {
            print("DEBUG: AlbumDetailViewModel: Альбом \(id) уже загружен — пропускаем запрос.")
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
            await interactor.playSong(with: song.id)
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
        }

        do {
            print("DEBUG: AlbumDetailViewModel: Загружаем альбом \(id) с API (без кэша).")
            guard let (album, songs) = try await interactor.loadAlbum(by: id) else {
                await MainActor.run {
                    self.errorMessage = "Album not found"
                }
                return
            }

            await MainActor.run {
                self.album = album
                self.songs = songs
                self.currentAlbumID = id
                print("DEBUG: AlbumDetailViewModel.songs обновлён, количество: \(songs.count)")
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
            print("DEBUG: AlbumDetailViewModel: Загружаем артиста \(id) для альбома.")
            guard let artist = try await interactor.fetchArtist(by: id) else {
                print("DEBUG: AlbumDetailViewModel: Артист \(id) не найден.")
                return
            }
            await MainActor.run {
                self.albumArtist = artist
                print("DEBUG: AlbumDetailViewModel: Артист \(artist.name) загружен.")
            }
        } catch {
            print("DEBUG: AlbumDetailViewModel: Ошибка загрузки артиста \(id): \(error)")
        }
    }

    private func loadAlbumArtworkAsync(from urlString: String) async {
        do {
            print("DEBUG: AlbumDetailViewModel: Загружаем обложку по пути: \(urlString)")
            guard let imageData = try await interactor.fetchImageData(from: urlString) else {
                print("DEBUG: AlbumDetailViewModel: Обложка не найдена по пути: \(urlString)")
                return
            }
            await MainActor.run {
                self.albumArtworkData = imageData
                print("DEBUG: AlbumDetailViewModel: Обложка загружена, размер: \(imageData.count) байт")
            }
        } catch {
            print("DEBUG: AlbumDetailViewModel: Ошибка загрузки обложки \(urlString): \(error)")
        }
    }
}
