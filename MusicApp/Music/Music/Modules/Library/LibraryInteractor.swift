import Foundation

// MARK: - LibraryInteractorProtocol
protocol LibraryInteractorProtocol {
    func fetchAllPlaylists() async throws -> [Playlist]
    func createNewPlaylist(name: String) async throws -> Playlist
    func deletePlaylist(_ playlist: Playlist) async throws
    func updatePlaylistName(_ id: String, newName: String) async throws -> Playlist
}

// MARK: - LibraryInteractor
final class LibraryInteractor: LibraryInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    
    init(musicRepository: MusicRepositoryProtocol) {
        self.musicRepository = musicRepository
    }
    
    func fetchAllPlaylists() async throws -> [Playlist] {
        return try await musicRepository.getAllPlaylistsFromLocal()
    }
    
    func createNewPlaylist(name: String) async throws -> Playlist {
        let newPlaylist = Playlist(
            id: UUID().uuidString,
            name: name,
            songIDs: []
        )
        
        try await musicRepository.createPlaylist(newPlaylist)
        return newPlaylist
    }
    
    func deletePlaylist(_ playlist: Playlist) async throws {
        try await musicRepository.deletePlaylist(by: playlist.id)
    }
    
    func updatePlaylistName(_ id: String, newName: String) async throws -> Playlist {
        guard var playlist = try await musicRepository.getPlaylistFromLocal(by: id) else {
            throw NSError(domain: "Playlist not found", code: 404)
        }
        
        playlist.name = newName
        try await musicRepository.updatePlaylist(playlist)
        return playlist
    }
}
