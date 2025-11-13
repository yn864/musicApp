import Foundation

// MARK: - HomeInteractorProtocol
protocol HomeInteractorProtocol {
    func loadRecommendations() async throws -> [Album]
    func loadAlbumArtwork(for album: Album) async -> Data?
    func loadArtistName(for artistID: String) async -> String?
}

// MARK: - HomeInteractor
final class HomeInteractor: HomeInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    
    init(musicRepository: MusicRepositoryProtocol) {
        self.musicRepository = musicRepository
    }
    
    func loadRecommendations() async throws -> [Album] {
        return try await musicRepository.fetchAlbumsFromAPI()
    }
    
    func loadAlbumArtwork(for album: Album) async -> Data? {
        guard let artworkURL = album.artworkURL else {
            return nil
        }
        
        do {
            let data = try await musicRepository.fetchImage(from: artworkURL)
            return data
        } catch {
            return nil
        }
    }
    
    func loadArtistName(for artistID: String) async -> String? {
        do {
            let artist = try await musicRepository.fetchArtistFromAPI(by: artistID)
            return artist?.name
        } catch {
            return nil
        }
    }
}
