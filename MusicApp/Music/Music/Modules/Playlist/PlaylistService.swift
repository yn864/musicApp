import Foundation

// MARK: - PlaylistServiceProtocol
protocol PlaylistServiceProtocol {
    func getPlaylist(by id: Playlist.ID) async throws -> Playlist?
    func updatePlaylist(_ playlist: Playlist) async throws
    func deletePlaylist(_ playlist: Playlist) async throws
    func addSongToPlaylist(_ song: Song, playlist: Playlist) async throws -> Playlist
    func removeSongFromPlaylist(_ song: Song, playlist: Playlist) async throws -> Playlist
    func getPlaylistSongs(_ playlist: Playlist) async throws -> [Song]
}

// MARK: - PlaylistService
final class PlaylistService: PlaylistServiceProtocol {
    private let musicRepository: MusicRepositoryProtocol
    
    init(musicRepository: MusicRepositoryProtocol) {
        self.musicRepository = musicRepository
    }
    
    func getPlaylist(by id: Playlist.ID) async throws -> Playlist? {
        return try await musicRepository.getPlaylistFromLocal(by: id)
    }
    
    func updatePlaylist(_ playlist: Playlist) async throws {
        try await musicRepository.updatePlaylist(playlist)
    }
    
    func deletePlaylist(_ playlist: Playlist) async throws {
        try await musicRepository.deletePlaylist(by: playlist.id)
    }
    
    func addSongToPlaylist(_ song: Song, playlist: Playlist) async throws -> Playlist {
        
        if let _ = try? await musicRepository.getSongFromLocal(by: song.id) {
        
        } else {
            try await musicRepository.storeSong(song)
        }
        
        
        var updatedPlaylist = playlist
        if !updatedPlaylist.songIDs.contains(song.id) {
            updatedPlaylist.songIDs.append(song.id)
            try await musicRepository.updatePlaylist(updatedPlaylist)
        }
        
        return updatedPlaylist
    }
    
    func removeSongFromPlaylist(_ song: Song, playlist: Playlist) async throws -> Playlist {
        var updatedPlaylist = playlist
        updatedPlaylist.songIDs.removeAll { $0 == song.id }
        try await musicRepository.updatePlaylist(updatedPlaylist)
        return updatedPlaylist
    }
    
    func getPlaylistSongs(_ playlist: Playlist) async throws -> [Song] {
        var songs: [Song] = []
        
        
        for songID in playlist.songIDs {
            if let localSong = try? await musicRepository.getSongFromLocal(by: songID) {
                songs.append(localSong)
            }
        }
        
        
        if songs.count == playlist.songIDs.count {
            return songs
        }
        
        
        let missingSongIDs = playlist.songIDs.filter { songID in
            !songs.contains(where: { $0.id == songID })
        }
        
        for songID in missingSongIDs {
            if let apiSong = try await musicRepository.fetchSongFromAPI(by: songID) {
                try await musicRepository.storeSong(apiSong)
                songs.append(apiSong)
            } else {
                throw PlaylistServiceError.songNotFoundInAPI(songID: songID)
            }
        }
        
        return songs
    }
}

// MARK: - PlaylistServiceError
enum PlaylistServiceError: Error {
    case songNotFoundInAPI(songID: String)
}
