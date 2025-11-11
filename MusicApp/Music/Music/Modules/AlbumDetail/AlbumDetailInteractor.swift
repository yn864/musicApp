import Foundation

// MARK: - AlbumDetailInteractorProtocol
protocol AlbumDetailInteractorProtocol {
    func loadAlbum(by id: String) async throws -> (album: Album, songs: [Song])? // <--- Меняем возвращаемый тип
    func playSong(with id: String) async
}

// MARK: - AlbumDetailInteractor
class AlbumDetailInteractor: AlbumDetailInteractorProtocol {
    private let musicRepository: MusicRepositoryProtocol
    private let playerInteractor: PlayerInteractorProtocol

    init(musicRepository: MusicRepositoryProtocol, playerInteractor: PlayerInteractorProtocol) {
        self.musicRepository = musicRepository
        self.playerInteractor = playerInteractor
    }

    // func loadSongs(by ids: [String]) async throws -> [Song] { // <--- Убираем, если не используется где-то ещё
    //     var songs: [Song] = []
    //     for songID in ids {
    //         if let song = try await musicRepository.fetchSongFromAPI(by: songID) {
    //             songs.append(song)
    //         } else {
    //             print("DEBUG: Не удалось загрузить песню с ID: \(songID)")
    //         }
    //     }
    //     print("DEBUG: AlbumDetailInteractor.loadSongs вернул \(songs.count) песен.")
    //     return songs
    // }

    // Изменяем loadAlbum: всегда загружаем с API, возвращаем и альбом, и песни
    func loadAlbum(by id: String) async throws -> (album: Album, songs: [Song])? {
        print("DEBUG: AlbumDetailInteractor: Загружаем альбом \(id) с API.")
        // 1. Загружаем альбом с API
        guard let album = try await musicRepository.fetchAlbumFromAPI(by: id) else {
            print("DEBUG: AlbumDetailInteractor: Не удалось загрузить альбом \(id) с API.")
            return nil
        }

        print("DEBUG: AlbumDetailInteractor: Загружен альбом \(id) с \(album.songIDs.count) песнями. Начинаем загружать песни.")
        // 2. Загружаем песни по ID
        var songs: [Song] = []
        for songID in album.songIDs {
            if let song = try await musicRepository.fetchSongFromAPI(by: songID) {
                songs.append(song)
            } else {
                print("DEBUG: AlbumDetailInteractor: Не удалось загрузить песню \(songID) для альбома \(id).")
            }
        }

        print("DEBUG: AlbumDetailInteractor: Загружено \(songs.count) песен для альбома \(id).")
        // 3. Возвращаем и альбом, и песни
        return (album: album, songs: songs)
    }

    func playSong(with id: String) async {
        // Просто делегируем PlayerInteractor
        try? await playerInteractor.playSong(with: id)
    }
}
