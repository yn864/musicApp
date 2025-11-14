import Foundation
import SwiftUI
import Combine

// MARK: - PlaylistViewModel
class PlaylistViewModel: ObservableObject {
    // MARK: - Dependencies
    private let interactor: PlaylistInteractorProtocol

    // MARK: - State Properties
    @Published var playlist: Playlist? = nil
    @Published var songs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var currentPlaylistID: String? = nil
    private var lastKnownSongCount: Int = 0

    // MARK: - Initialization
    init(interactor: PlaylistInteractorProtocol) {
        self.interactor = interactor
    }

    // MARK: - Commands (Actions from UI)
    func loadPlaylist(by id: String) {
        if id == currentPlaylistID {
            if let currentPlaylist = playlist,
               currentPlaylist.songIDs.count != lastKnownSongCount {
                Task {
                    await loadPlaylistAsync(by: id)
                }
                return
            }
            return
        }
        
        currentPlaylistID = id
        
        Task {
            await loadPlaylistAsync(by: id)
        }
    }
    
    func removeSongFromPlaylist(_ song: Song) {
        Task {
            await removeSongFromPlaylistAsync(song)
        }
    }
    
    func playSong(_ song: Song) {
        Task {
            await playSongAsync(song)
        }
    }
    
    func playPlaylist() {
        Task {
            await playPlaylistAsync()
        }
    }

    // MARK: - Private Async Methods
    private func loadPlaylistAsync(by id: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            guard let (playlist, songs) = try await interactor.loadPlaylist(by: id) else {
                await MainActor.run {
                    errorMessage = "Playlist not found"
                    isLoading = false
                }
                return
            }

            await MainActor.run {
                self.playlist = playlist
                self.songs = songs
                self.isLoading = false
                self.lastKnownSongCount = playlist.songIDs.count
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func removeSongFromPlaylistAsync(_ song: Song) async {
        guard let playlist = playlist else { return }
        
        do {
            let updatedPlaylist = try await interactor.removeSongFromPlaylist(song, playlist: playlist)
            let updatedSongs = songs.filter { $0.id != song.id }
            
            await MainActor.run {
                self.playlist = updatedPlaylist
                self.songs = updatedSongs
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func playSongAsync(_ song: Song) async {
        guard let playlist = playlist else { return }
        await interactor.playSong(song, from: playlist)
    }
    
    private func playPlaylistAsync() async {
        guard let playlist = playlist else { return }
        
        do {
            try await interactor.playPlaylist(playlist)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}
