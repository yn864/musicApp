import Foundation

// MARK: - PlaylistInteractorProtocol
protocol PlaylistInteractorProtocol {
    func loadPlaylist(by id: Playlist.ID) async throws -> (playlist: Playlist, songs: [Song])?
    func removeSongFromPlaylist(_ song: Song, playlist: Playlist) async throws -> Playlist
    func playSong(_ song: Song, from playlist: Playlist) async
    func playPlaylist(_ playlist: Playlist) async throws
}

// MARK: - PlaylistInteractor
final class PlaylistInteractor: PlaylistInteractorProtocol {
    private let playlistService: PlaylistServiceProtocol
    private let playerInteractor: PlayerInteractorProtocol
    private let musicRepository: MusicRepositoryProtocol
    
    init(
        playlistService: PlaylistServiceProtocol,
        playerInteractor: PlayerInteractorProtocol,
        musicRepository: MusicRepositoryProtocol
    ) {
        self.playlistService = playlistService
        self.playerInteractor = playerInteractor
        self.musicRepository = musicRepository
    }
    
    func loadPlaylist(by id: Playlist.ID) async throws -> (playlist: Playlist, songs: [Song])? {
        guard let playlist = try await playlistService.getPlaylist(by: id) else {
            return nil
        }
        
        let songs = try await playlistService.getPlaylistSongs(playlist)
        return (playlist: playlist, songs: songs)
    }
    
    func removeSongFromPlaylist(_ song: Song, playlist: Playlist) async throws -> Playlist {
        return try await playlistService.removeSongFromPlaylist(song, playlist: playlist)
    }
    
    func playSong(_ song: Song, from playlist: Playlist) async {
        try? await playerInteractor.playSong(with: song.id, from: playlist.songIDs)
    }
    
    func playPlaylist(_ playlist: Playlist) async throws {
        let songs = try await playlistService.getPlaylistSongs(playlist)
        guard let firstSong = songs.first else {
            throw PlaylistInteractorError.emptyPlaylist
        }
        
        try await playerInteractor.playSong(with: firstSong.id, from: playlist.songIDs)
    }
}

// MARK: - PlaylistInteractorError
enum PlaylistInteractorError: Error {
    case playlistNotFound
    case emptyPlaylist
}
