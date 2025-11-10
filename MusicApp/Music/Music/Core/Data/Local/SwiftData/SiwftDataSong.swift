import Foundation
import SwiftData

@Model
final class SwiftDataSong {
    
    var id: String
    var title: String
    var duration: TimeInterval?
    var artworkURL: String?
    var isLiked: Bool
    var localFilePath: String? // Путь к файлу, если хранится локально

    // Связи
    @Relationship(inverse: \SwiftDataAlbum.songs)
    var album: SwiftDataAlbum?

    @Relationship(inverse: \SwiftDataArtist.songs)
    var artist: SwiftDataArtist?

    
    init(id: String = UUID().uuidString, title: String, duration: TimeInterval? = nil, artworkURL: String? = nil, isLiked: Bool = false, localFilePath: String? = nil, artist: SwiftDataArtist? = nil, album: SwiftDataAlbum? = nil) {
        self.id = id
        self.title = title
        self.duration = duration
        self.artworkURL = artworkURL
        self.isLiked = isLiked
        self.localFilePath = localFilePath
        self.artist = artist
        self.album = album
    }
}

// MARK: - Extensions для преобразования из/в доменную модель
extension SwiftDataSong {
    
    func toDomainModel() -> Song {
        return Song(
            id: self.id,
            title: self.title,
            artistID: self.artist?.id ?? "unknown_artist_id",
            albumID: self.album?.id ?? "unknown_album_id",
            duration: self.duration,
            artworkURL: self.artworkURL,
            isLiked: self.isLiked,
            localFilePath: self.localFilePath
        )
    }

    
    static func fromDomainModel(_ song: Song) -> SwiftDataSong {
        let sdSong = SwiftDataSong(
            id: song.id,
            title: song.title,
            duration: song.duration,
            artworkURL: song.artworkURL,
            isLiked: song.isLiked,
            localFilePath: song.localFilePath
        )
        return sdSong
    }
}
