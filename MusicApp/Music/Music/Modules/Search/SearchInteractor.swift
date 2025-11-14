import Foundation

// MARK: - SearchInteractorProtocol
protocol SearchInteractorProtocol {
    func searchSongs(query: String) async throws -> [Song]
    func searchAlbums(query: String) async throws -> [Album]
    func playSong(_ song: Song) async
}

// MARK: - SearchInteractor
final class SearchInteractor: SearchInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    private let playerInteractor: PlayerInteractorProtocol
    
    init(musicRepository: MusicRepositoryProtocol, playerInteractor: PlayerInteractorProtocol) {
        self.musicRepository = musicRepository
        self.playerInteractor = playerInteractor
    }
    
    func searchSongs(query: String) async throws -> [Song] {
        return try await musicRepository.searchSongs(query: query)
    }
    
    func searchAlbums(query: String) async throws -> [Album] {
        return try await musicRepository.searchAlbums(query: query)
    }
    
    func playSong(_ song: Song) async { 
        try? await playerInteractor.playSong(with: song.id, from: [song.id])
    }
}
