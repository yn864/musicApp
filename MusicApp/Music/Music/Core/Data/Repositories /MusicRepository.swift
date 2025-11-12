import Foundation

// MARK: - MusicRepositoryProtocol
protocol MusicRepositoryProtocol {
    // MARK: - Fetch from API only (without storing)
    func fetchSongsFromAPI() async throws -> [Song]
    func fetchSongFromAPI(by id: Song.ID) async throws -> Song?
    func fetchAlbumsFromAPI() async throws -> [Album]
    func fetchAlbumFromAPI(by id: Album.ID) async throws -> Album?
    func fetchArtistsFromAPI() async throws -> [Artist]
    func fetchArtistFromAPI(by id: Artist.ID) async throws -> Artist?

    // MARK: - Store/Update in SwiftData only (user actions or sync)
    func storeSong(_ song: Song) async throws
    func storeAlbum(_ album: Album) async throws
    func storeArtist(_ artist: Artist) async throws
    func updateSongLikeStatus(id: Song.ID, isLiked: Bool) throws

    // MARK: - Get from SwiftData only (API independent)
    func getSongsFromLocal() async throws -> [Song]
    func getAlbumsFromLocal() async throws -> [Album]
    func getArtistsFromLocal() async throws -> [Artist]
    func getSongFromLocal(by id: Song.ID) async throws -> Song?
    func getAlbumFromLocal(by id: Album.ID) async throws -> Album?
    func getArtistFromLocal(by id: Artist.ID) async throws -> Artist?
    func getLikedSongsFromLocal() async throws -> [Song]
    
    func fetchImage(from urlString: String) async throws -> Data?

}

// MARK: - MusicRepository Implementation
final class MusicRepository: MusicRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let storageService: SwiftDataStorageServiceProtocol

    init(networkService: NetworkServiceProtocol, storageService: SwiftDataStorageServiceProtocol) {
        self.networkService = networkService
        self.storageService = storageService
    }

    // MARK: - Fetch from API only (Implementation)
    func fetchSongsFromAPI() async throws -> [Song] {
        return try await networkService.fetchSongs()
    }

    func fetchSongFromAPI(by id: Song.ID) async throws -> Song? {
        return try await networkService.fetchSong(by: id)
    }

    func fetchAlbumsFromAPI() async throws -> [Album] {
        return try await networkService.fetchAlbums()
    }

    func fetchAlbumFromAPI(by id: Album.ID) async throws -> Album? {
        return try await networkService.fetchAlbum(by: id)
    }

    func fetchArtistsFromAPI() async throws -> [Artist] {
        return try await networkService.fetchArtists()
    }

    func fetchArtistFromAPI(by id: Artist.ID) async throws -> Artist? {
        return try await networkService.fetchArtist(by: id)
    }

    // MARK: - Store/Update in SwiftData only (Implementation)
    func storeSong(_ song: Song) async throws {
        try storageService.addSong(song)
    }

    func storeAlbum(_ album: Album) async throws {
        try storageService.addAlbum(album)
    }

    func storeArtist(_ artist: Artist) async throws {
        try storageService.addArtist(artist)
    }

    func updateSongLikeStatus(id: Song.ID, isLiked: Bool) throws {
        try storageService.updateSongLikeStatus(id: id, isLiked: isLiked)
    }

    // MARK: - Get from SwiftData only (Implementation)
    func getSongsFromLocal() async throws -> [Song] {
        return try storageService.getAllSongs()
    }

    func getAlbumsFromLocal() async throws -> [Album] {
        return try storageService.getAllAlbums()
    }

    func getArtistsFromLocal() async throws -> [Artist] {
        return try storageService.getAllArtists()
    }

    func getSongFromLocal(by id: Song.ID) async throws -> Song? {
        return try storageService.getSong(by: id)
    }

    func getAlbumFromLocal(by id: Album.ID) async throws -> Album? {
        return try storageService.getAlbum(by: id)
    }

    func getArtistFromLocal(by id: Artist.ID) async throws -> Artist? {
        return try storageService.getArtist(by: id)
    }

    func getLikedSongsFromLocal() async throws -> [Song] {
        return try storageService.getLikedSongs()
    }
    
    func fetchImage(from urlString: String) async throws -> Data? {
        return try await networkService.fetchImage(from: urlString)
    }

}
