import Foundation

// MARK: - AlbumDetailInteractorProtocol
protocol AlbumDetailInteractorProtocol {
    func loadAlbum(by id: String) async throws -> (album: Album, songs: [Song])?
    func playSong(with id: String) async
    func fetchArtist(by id: Artist.ID) async throws -> Artist?
    func fetchImageData(from urlString: String) async throws -> Data?
}

// MARK: - AlbumDetailInteractor
class AlbumDetailInteractor: AlbumDetailInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    private let playerInteractor: PlayerInteractorProtocol

    init(musicRepository: MusicRepositoryProtocol, playerInteractor: PlayerInteractorProtocol) {
        self.musicRepository = musicRepository
        self.playerInteractor = playerInteractor
    }
    
    func loadAlbum(by id: String) async throws -> (album: Album, songs: [Song])? {
        print("DEBUG: AlbumDetailInteractor: Загружаем альбом \(id) с API.")
        guard let album = try await musicRepository.fetchAlbumFromAPI(by: id) else {
            print("DEBUG: AlbumDetailInteractor: Не удалось загрузить альбом \(id) с API.")
            return nil
        }

        print("DEBUG: AlbumDetailInteractor: Загружен альбом \(id) с \(album.songIDs.count) песнями. Начинаем параллельную загрузку песен с сохранением порядка.")
        
        let songsWithIndex = await withTaskGroup(of: (index: Int, song: Song?)?.self) { group in
            for (index, songID) in album.songIDs.enumerated() {
                group.addTask {
                    let song = try? await self.musicRepository.fetchSongFromAPI(by: songID)
                    return (index: index, song: song)
                }
            }
            var results: [(index: Int, song: Song?)] = []
            for await result in group {
                if let unwrapped = result {
                    results.append(unwrapped)
                }
            }
            return results
        }
        
        let sortedSongs = songsWithIndex
            .sorted { $0.index < $1.index }
            .compactMap { $0.song }

        print("DEBUG: AlbumDetailInteractor: Загружено \(sortedSongs.count) песен для альбома \(id) в правильном порядке.")
        return (album: album, songs: sortedSongs)
    }

    func playSong(with id: String) async {
        try? await playerInteractor.playSong(with: id)
    }
    
    func fetchArtist(by id: Artist.ID) async throws -> Artist? {
        return try await musicRepository.fetchArtistFromAPI(by: id)
    }
    
    func fetchImageData(from urlString: String) async throws -> Data? {
        return try await musicRepository.fetchImage(from: urlString)
    }
}
