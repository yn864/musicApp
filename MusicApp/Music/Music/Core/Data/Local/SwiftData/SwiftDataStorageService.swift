import Foundation
import SwiftData
// MARK: - SwiftDataStorageServiceProtocol
protocol SwiftDataStorageServiceProtocol {
    // MARK: - Save/Update Methods (Store or Update in SwiftData)
    func addSong(_ song: Song) throws
    func addAlbum(_ album: Album) throws
    func addArtist(_ artist: Artist) throws

    // MARK: - Get All Methods (Read from SwiftData)
    func getAllSongs() throws -> [Song]
    func getAllAlbums() throws -> [Album]
    func getAllArtists() throws -> [Artist]

    // MARK: - Get Multiple Methods (Read from SwiftData)
    func getSongs(by ids: [Song.ID]) throws -> [Song]
    func getAlbums(by ids: [Album.ID]) throws -> [Album]
    func getArtists(by ids: [Artist.ID]) throws -> [Artist]

    // MARK: - Get Single Methods (Read from SwiftData)
    func getSong(by id: Song.ID) throws -> Song?
    func getAlbum(by id: Album.ID) throws -> Album?
    func getArtist(by id: Artist.ID) throws -> Artist?

    // MARK: - Specific Local Data Methods (e.g., song like status)
    func updateSongLikeStatus(id: Song.ID, isLiked: Bool) throws
    func getLikedSongs() throws -> [Song]

    // MARK: - Update Full Entity (Alternative way to update)
    func updateSong(_ song: Song) throws
    func updateAlbum(_ album: Album) throws
    func updateArtist(_ artist: Artist) throws

    // MARK: - Delete Methods (Remove from SwiftData)
    func deleteSong(by id: Song.ID) throws
    func deleteAlbum(by id: Album.ID) throws
    func deleteArtist(by id: Artist.ID) throws
    
    
    // MARK: - Playlist Methods
    func createPlaylist(_ playlist: Playlist) throws
    func getAllPlaylists() throws -> [Playlist]
    func getPlaylist(by id: Playlist.ID) throws -> Playlist?
    func updatePlaylist(_ playlist: Playlist) throws
    func deletePlaylist(by id: Playlist.ID) throws
    func addSongToPlaylist(songID: Song.ID, playlistID: Playlist.ID) throws
    func removeSongFromPlaylist(songID: Song.ID, playlistID: Playlist.ID) throws
}

// MARK: - Storage Error
enum StorageError: Error {
    case entityNotFound
    case unknownError
}

// MARK: - SwiftDataStorageService Implementation
class SwiftDataStorageService: SwiftDataStorageServiceProtocol {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Song Operations
    @MainActor
    func addSong(_ domainSong: Song) throws {
        let context = ModelContext(container)
        let sdArtist = try getOrCreateArtist(by: domainSong.artistID, in: context)
        let sdAlbum = try getOrCreateAlbum(by: domainSong.albumID, in: context)

        let sdSong = SwiftDataSong.fromDomainModel(domainSong)
        sdSong.artist = sdArtist
        sdSong.album = sdAlbum

        context.insert(sdSong)
        try context.save()
    }

    @MainActor
    func getAllSongs() throws -> [Song] {
        let descriptor = FetchDescriptor<SwiftDataSong>()
        let sdSongs = try container.mainContext.fetch(descriptor)
        return sdSongs.map { $0.toDomainModel() }
    }

    @MainActor
    func getSongs(by ids: [Song.ID]) throws -> [Song] {
        let predicate = #Predicate<SwiftDataSong> { song in
            ids.contains(song.id)
        }
        let descriptor = FetchDescriptor<SwiftDataSong>(predicate: predicate)
        let sdSongs = try container.mainContext.fetch(descriptor)
        return sdSongs.map { $0.toDomainModel() }
    }

    @MainActor
    func getSong(by id: Song.ID) throws -> Song? {
        let predicate = #Predicate<SwiftDataSong> { song in
            song.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataSong>(predicate: predicate)
        let sdSongs = try container.mainContext.fetch(descriptor)
        return sdSongs.first?.toDomainModel()
    }

    @MainActor
    func updateSong(_ domainSong: Song) throws {
        guard let sdSong = try getSongSD(by: domainSong.id) else {
            throw StorageError.entityNotFound
        }
        sdSong.title = domainSong.title
        sdSong.isLiked = domainSong.isLiked
        sdSong.duration = domainSong.duration
        sdSong.artworkURL = domainSong.artworkURL
        try container.mainContext.save()
    }

    @MainActor
    func deleteSong(by id: Song.ID) throws {
        guard let sdSong = try getSongSD(by: id) else {
            throw StorageError.entityNotFound
        }
        container.mainContext.delete(sdSong)
        try container.mainContext.save()
    }

    // MARK: - Album Operations
    @MainActor
    func addAlbum(_ domainAlbum: Album) throws {
        let context = ModelContext(container)
        let sdArtist = try getOrCreateArtist(by: domainAlbum.artistID, in: context)

        let sdAlbum = SwiftDataAlbum.fromDomainModel(domainAlbum)
        sdAlbum.artist = sdArtist
        sdAlbum.songIDs = domainAlbum.songIDs

        if !domainAlbum.songIDs.isEmpty {
            let sdSongs = try getSongsSD(by: domainAlbum.songIDs, in: context)
            sdAlbum.songs = sdSongs
        }

        context.insert(sdAlbum)
        try context.save()
    }

    @MainActor
    func getAllAlbums() throws -> [Album] {
        let descriptor = FetchDescriptor<SwiftDataAlbum>()
        let sdAlbums = try container.mainContext.fetch(descriptor)
        return sdAlbums.map { $0.toDomainModel() }
    }

    @MainActor
    func getAlbums(by ids: [Album.ID]) throws -> [Album] {
        let predicate = #Predicate<SwiftDataAlbum> { album in
            ids.contains(album.id)
        }
        let descriptor = FetchDescriptor<SwiftDataAlbum>(predicate: predicate)
        let sdAlbums = try container.mainContext.fetch(descriptor)
        return sdAlbums.map { $0.toDomainModel() }
    }

    @MainActor
    func getAlbum(by id: Album.ID) throws -> Album? {
        let predicate = #Predicate<SwiftDataAlbum> { album in
            album.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataAlbum>(predicate: predicate)
        let sdAlbums = try container.mainContext.fetch(descriptor)
        return sdAlbums.first?.toDomainModel()
    }

    @MainActor
    func updateAlbum(_ domainAlbum: Album) throws {
        guard let sdAlbum = try getAlbumSD(by: domainAlbum.id) else {
            throw StorageError.entityNotFound
        }
        sdAlbum.title = domainAlbum.title
        sdAlbum.trackCount = domainAlbum.trackCount
        sdAlbum.releaseDate = domainAlbum.releaseDate
        sdAlbum.artworkURL = domainAlbum.artworkURL
         sdAlbum.songIDs = domainAlbum.songIDs
        if !domainAlbum.songIDs.isEmpty {
            let sdSongs = try getSongsSD(by: domainAlbum.songIDs, in: container.mainContext)
            sdAlbum.songs = sdSongs
        }
        try container.mainContext.save()
    }

    @MainActor
    func deleteAlbum(by id: Album.ID) throws {
        guard let sdAlbum = try getAlbumSD(by: id) else {
            throw StorageError.entityNotFound
        }
        container.mainContext.delete(sdAlbum)
        try container.mainContext.save()
    }

    // MARK: - Artist Operations
    @MainActor
    func addArtist(_ domainArtist: Artist) throws {
        let context = ModelContext(container)
        let sdArtist = SwiftDataArtist.fromDomainModel(domainArtist)
        context.insert(sdArtist)
        try context.save()
    }

    @MainActor
    func getAllArtists() throws -> [Artist] {
        let descriptor = FetchDescriptor<SwiftDataArtist>()
        let sdArtists = try container.mainContext.fetch(descriptor)
        return sdArtists.map { $0.toDomainModel() }
    }

    @MainActor
    func getArtists(by ids: [Artist.ID]) throws -> [Artist] {
        let predicate = #Predicate<SwiftDataArtist> { artist in
            ids.contains(artist.id)
        }
        let descriptor = FetchDescriptor<SwiftDataArtist>(predicate: predicate)
        let sdArtists = try container.mainContext.fetch(descriptor)
        return sdArtists.map { $0.toDomainModel() }
    }

    @MainActor
    func getArtist(by id: Artist.ID) throws -> Artist? {
        let predicate = #Predicate<SwiftDataArtist> { artist in
            artist.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataArtist>(predicate: predicate)
        let sdArtists = try container.mainContext.fetch(descriptor)
        return sdArtists.first?.toDomainModel()
    }

    @MainActor
    func updateArtist(_ domainArtist: Artist) throws {
        guard let sdArtist = try getArtistSD(by: domainArtist.id) else {
            throw StorageError.entityNotFound
        }
        sdArtist.name = domainArtist.name
        sdArtist.bio = domainArtist.bio
        sdArtist.artworkURL = domainArtist.artworkURL
        try container.mainContext.save()
    }

    @MainActor
    func deleteArtist(by id: Artist.ID) throws {
        guard let sdArtist = try getArtistSD(by: id) else {
            throw StorageError.entityNotFound
        }
        container.mainContext.delete(sdArtist)
        try container.mainContext.save()
    }

    //MARK: - Specific Local Data Methods (e.g., song like status)
    @MainActor
    func updateSongLikeStatus(id: Song.ID, isLiked: Bool) throws {
        guard let sdSong = try getSongSD(by: id) else {
            throw StorageError.entityNotFound
        }
        sdSong.isLiked = isLiked
        try container.mainContext.save()
    }
    
    @MainActor
    func getLikedSongs() throws -> [Song] {
        let predicate = #Predicate<SwiftDataSong> { song in
            song.isLiked == true
        }
        let descriptor = FetchDescriptor<SwiftDataSong>(predicate: predicate)
        let sdSongs = try container.mainContext.fetch(descriptor)
        return sdSongs.map { $0.toDomainModel() }
    }
        

    // MARK: - Private Helper Methods
    @MainActor
    private func getOrCreateArtist(by id: Artist.ID, in context: ModelContext) throws -> SwiftDataArtist {
        let predicate = #Predicate<SwiftDataArtist> { artist in
            artist.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataArtist>(predicate: predicate)
        if let existing = try context.fetch(descriptor).first {
            return existing
        } else {
            let newArtist = SwiftDataArtist(id: id, name: "Unknown Artist")
            context.insert(newArtist)
            return newArtist
        }
    }

    @MainActor
    private func getOrCreateAlbum(by id: Album.ID, in context: ModelContext) throws -> SwiftDataAlbum {
        let predicate = #Predicate<SwiftDataAlbum> { album in
            album.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataAlbum>(predicate: predicate)
        if let existing = try context.fetch(descriptor).first {
            return existing
        } else {
            let newAlbum = SwiftDataAlbum(id: id, title: "Unknown Album")
            context.insert(newAlbum)
            return newAlbum
        }
    }

    @MainActor
    private func getSongSD(by id: Song.ID) throws -> SwiftDataSong? {
        let predicate = #Predicate<SwiftDataSong> { song in
            song.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataSong>(predicate: predicate)
        let results = try container.mainContext.fetch(descriptor)
        return results.first
    }

    @MainActor
    private func getSongsSD(by ids: [Song.ID], in context: ModelContext) throws -> [SwiftDataSong] {
        let predicate = #Predicate<SwiftDataSong> { song in
            ids.contains(song.id)
        }
        let descriptor = FetchDescriptor<SwiftDataSong>(predicate: predicate)
        return try context.fetch(descriptor)
    }

    @MainActor
    private func getAlbumSD(by id: Album.ID) throws -> SwiftDataAlbum? {
        let predicate = #Predicate<SwiftDataAlbum> { album in
            album.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataAlbum>(predicate: predicate)
        let results = try container.mainContext.fetch(descriptor)
        return results.first
    }

    @MainActor
    private func getArtistSD(by id: Artist.ID) throws -> SwiftDataArtist? {
        let predicate = #Predicate<SwiftDataArtist> { artist in
            artist.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataArtist>(predicate: predicate)
        let results = try container.mainContext.fetch(descriptor)
        return results.first
    }
    
    
    @MainActor
    func createPlaylist(_ domainPlaylist: Playlist) throws {
        let context = ModelContext(container)
        let sdPlaylist = SwiftDataPlaylist.fromDomainModel(domainPlaylist)
        
        if !domainPlaylist.songIDs.isEmpty {
            let sdSongs = try getSongsSD(by: domainPlaylist.songIDs, in: context)
            sdPlaylist.songs = sdSongs
        }
        
        context.insert(sdPlaylist)
        try context.save()
    }
    
    @MainActor
    func getAllPlaylists() throws -> [Playlist] {
        let descriptor = FetchDescriptor<SwiftDataPlaylist>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sdPlaylists = try container.mainContext.fetch(descriptor)
        return sdPlaylists.map { $0.toDomainModel() }
    }
    
    @MainActor
    func getPlaylist(by id: Playlist.ID) throws -> Playlist? {
        let predicate = #Predicate<SwiftDataPlaylist> { playlist in
            playlist.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataPlaylist>(predicate: predicate)
        let sdPlaylists = try container.mainContext.fetch(descriptor)
        return sdPlaylists.first?.toDomainModel()
    }
    
    @MainActor
    func updatePlaylist(_ domainPlaylist: Playlist) throws {
        guard let sdPlaylist = try getPlaylistSD(by: domainPlaylist.id) else {
            throw StorageError.entityNotFound
        }
        
        sdPlaylist.name = domainPlaylist.name
        sdPlaylist.songIDs = domainPlaylist.songIDs
        
        if !domainPlaylist.songIDs.isEmpty {
            let sdSongs = try getSongsSD(by: domainPlaylist.songIDs, in: container.mainContext)
            sdPlaylist.songs = sdSongs
        } else {
            sdPlaylist.songs = []
        }
        
        try container.mainContext.save()
    }
    
    @MainActor
    func deletePlaylist(by id: Playlist.ID) throws {
        guard let sdPlaylist = try getPlaylistSD(by: id) else {
            throw StorageError.entityNotFound
        }
        container.mainContext.delete(sdPlaylist)
        try container.mainContext.save()
    }
    
    @MainActor
    func addSongToPlaylist(songID: Song.ID, playlistID: Playlist.ID) throws {
        guard let sdPlaylist = try getPlaylistSD(by: playlistID),
              let sdSong = try getSongSD(by: songID) else {
            throw StorageError.entityNotFound
        }
        
        if !sdPlaylist.songs.contains(where: { $0.id == songID }) {
            sdPlaylist.songs.append(sdSong)
            sdPlaylist.songIDs.append(songID)
            try container.mainContext.save()
        }
    }
    
    @MainActor
    func removeSongFromPlaylist(songID: Song.ID, playlistID: Playlist.ID) throws {
        guard let sdPlaylist = try getPlaylistSD(by: playlistID) else {
            throw StorageError.entityNotFound
        }
        
        sdPlaylist.songs.removeAll { $0.id == songID }
        sdPlaylist.songIDs.removeAll { $0 == songID }
        
        try container.mainContext.save()
    }
    
    // MARK: - Private Helper Methods for Playlists
    @MainActor
    private func getPlaylistSD(by id: Playlist.ID) throws -> SwiftDataPlaylist? {
        let predicate = #Predicate<SwiftDataPlaylist> { playlist in
            playlist.id == id
        }
        let descriptor = FetchDescriptor<SwiftDataPlaylist>(predicate: predicate)
        let results = try container.mainContext.fetch(descriptor)
        return results.first
    }
    
}
