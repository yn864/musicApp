import Foundation

// MARK: - PlayerInteractorProtocol
protocol PlayerInteractorProtocol {
    // MARK: - Playback Control
    func playSong(with id: String) async throws
    func togglePlayPause()
    func seek(to time: TimeInterval)
    // func playNext() async throws // <-- Пока убираем
    // func playPrevious() async throws // <-- Пока убираем

    // MARK: - Like Management (example)
    func toggleLike(for songID: String) async throws
}

// MARK: - PlayerInteractor Implementation
class PlayerInteractor: PlayerInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    private let playerService: PlayerServiceProtocol

    // MARK: - Initialization
    init(musicRepository: MusicRepositoryProtocol, playerService: PlayerServiceProtocol) {
        self.musicRepository = musicRepository
        self.playerService = playerService
    }

    // MARK: - PlayerInteractorProtocol Implementation

    // MARK: - Playback Control
    func playSong(with id: String) async throws {
        guard let song = try await musicRepository.fetchSongFromAPI(by: id) else {
            throw PlayerInteractorError.songNotFound(id: id)
        }
        playerService.load(song)
        playerService.play()
    }

    func togglePlayPause() {
        playerService.togglePlayPause()
    }

    func seek(to time: TimeInterval) {
        playerService.seek(to: time)
    }

    // MARK: - Like Management
    func toggleLike(for songID: String) async throws {
        guard let currentSong = try await musicRepository.getSongFromLocal(by: songID) else {
            throw PlayerInteractorError.songNotFoundLocally(id: songID)
        }
        let newLikeStatus = !currentSong.isLiked
        try musicRepository.updateSongLikeStatus(id: songID, isLiked: newLikeStatus)
    }

    // MARK: - Playlist Management (example - not implemented for now)
    // func playNext() async throws { ... }
    // func playPrevious() async throws { ... }
}

// MARK: - PlayerInteractorError Enum
enum PlayerInteractorError: Error, LocalizedError {
    case songNotFound(id: String)
    case songNotFoundLocally(id: String)
    // case endOfPlaylist // <-- Пока не нужно
    // case beginningOfPlaylist // <-- Пока не нужно

    var errorDescription: String? {
        switch self {
        case .songNotFound(let id):
            return "Song with ID \(id) not found."
        case .songNotFoundLocally(let id):
            return "Song with ID \(id) not found in local storage."
        // case .endOfPlaylist:
        //     return "Reached the end of the playlist."
        // case .beginningOfPlaylist:
        //     return "Reached the beginning of the playlist."
        }
    }
}
