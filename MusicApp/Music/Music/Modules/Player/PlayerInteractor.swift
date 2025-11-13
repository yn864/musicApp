import Foundation

// MARK: - PlayerInteractorProtocol
protocol PlayerInteractorProtocol {
    // MARK: - Playback Control
    func playSong(with id: String, from songIDs: [String]) async throws
    func togglePlayPause()
    func seek(to time: TimeInterval)
    func playNextSong() async throws
    func playPreviousSong() async throws
    func fetchArtist(by id: Artist.ID) async throws -> Artist?

    // MARK: - Like Management (example)
    func toggleLike(for songID: String) async throws
}

// MARK: - PlayerInteractor Implementation
class PlayerInteractor: PlayerInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    private let playerService: PlayerServiceProtocol

    private var currentPlaylist: [String] = []
    private var currentIndex: Int? = nil

    // MARK: - Initialization
    init(musicRepository: MusicRepositoryProtocol, playerService: PlayerServiceProtocol) {
        self.musicRepository = musicRepository
        self.playerService = playerService
    }

    // MARK: - PlayerInteractorProtocol Implementation

    // MARK: - Playback Control
    func playSong(with id: String, from songIDs: [String]) async throws {
        guard let song = try await musicRepository.fetchSongFromAPI(by: id) else {
            throw PlayerInteractorError.songNotFound(id: id)
        }

        self.currentPlaylist = songIDs
        if let index = songIDs.firstIndex(of: id) {
            self.currentIndex = index
        } else {
            self.currentIndex = nil
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

    func playNextSong() async throws {
        guard let currentIndex = currentIndex else {
            throw PlayerInteractorError.noPlaylistOrIndex
        }

        let nextIndex = currentIndex + 1
        if nextIndex < currentPlaylist.count {
            self.currentIndex = nextIndex
            let nextSongID = currentPlaylist[nextIndex]
            try await loadAndPlaySong(by: nextSongID)
        } else {
            throw PlayerInteractorError.endOfPlaylist
        }
    }

    func playPreviousSong() async throws {
        guard let currentIndex = currentIndex else {
            throw PlayerInteractorError.noPlaylistOrIndex
        }

        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            self.currentIndex = previousIndex
            let previousSongID = currentPlaylist[previousIndex]
            try await loadAndPlaySong(by: previousSongID)
        } else {
            throw PlayerInteractorError.beginningOfPlaylist
        }
    }

    func fetchArtist(by id: Artist.ID) async throws -> Artist? {
        return try await musicRepository.fetchArtistFromAPI(by: id)
    }

    private func loadAndPlaySong(by id: String) async throws {
        guard let song = try await musicRepository.fetchSongFromAPI(by: id) else {
            throw PlayerInteractorError.songNotFound(id: id)
        }
        playerService.load(song)
        playerService.play()
    }

    // MARK: - Like Management
    func toggleLike(for songID: String) async throws {
        guard let currentSong = try await musicRepository.getSongFromLocal(by: songID) else {
            throw PlayerInteractorError.songNotFoundLocally(id: songID)
        }
        let newLikeStatus = !currentSong.isLiked
        try musicRepository.updateSongLikeStatus(id: songID, isLiked: newLikeStatus)
    }
}

// MARK: - PlayerInteractorError Enum
enum PlayerInteractorError: Error, LocalizedError {
    case songNotFound(id: String)
    case songNotFoundLocally(id: String)
    case noPlaylistOrIndex
    case endOfPlaylist
    case beginningOfPlaylist

    var errorDescription: String? {
        switch self {
        case .songNotFound(let id):
            return "Song with ID \(id) not found."
        case .songNotFoundLocally(let id):
            return "Song with ID \(id) not found in local storage."
        case .noPlaylistOrIndex:
            return "No playlist or current index available."
        case .endOfPlaylist:
            return "Reached the end of the playlist."
        case .beginningOfPlaylist:
            return "Reached the beginning of the playlist."
        }
    }
}
