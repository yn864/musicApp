import Foundation

// MARK: - AlbumDetailCache
class AlbumDetailCache: ObservableObject {
    static let shared = AlbumDetailCache() // Синглтон

    private var cachedAlbums: [String: Album] = [:]
    private var cachedSongs: [String: [Song]] = [:]

    // Опционально: защищаем доступ к кэшу, если возможна работа из разных потоков
    private let queue = DispatchQueue(label: "AlbumDetailCache", attributes: .concurrent)

    private init() {}

    func cacheAlbum(_ album: Album, songs: [Song], for id: String) {
        queue.async(flags: .barrier) { // Пишем асинхронно в barrier-блоке
            self.cachedAlbums[id] = album
            self.cachedSongs[id] = songs
        }
    }

    func getCachedAlbum(for id: String) -> Album? {
        return queue.sync { // Читаем синхронно
            cachedAlbums[id]
        }
    }

    func getCachedSongs(for id: String) -> [Song]? {
        return queue.sync { // Читаем синхронно
            cachedSongs[id]
        }
    }

    // Опционально: метод для очистки устаревшего кэша или ограничения размера
    func clearCache(for id: String? = nil) {
        queue.async(flags: .barrier) {
            if let id = id {
                self.cachedAlbums[id] = nil
                self.cachedSongs[id] = nil
            } else {
                self.cachedAlbums.removeAll()
                self.cachedSongs.removeAll()
            }
        }
    }
}
