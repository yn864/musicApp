import Foundation
import SwiftData

@Model
final class SwiftDataAlbum {
    var id: String
    var title: String
    var releaseDate: Date?
    var artworkURL: String?
    var trackCount: Int

    // Связи
    @Relationship(inverse: \SwiftDataArtist.albums)
    var artist: SwiftDataArtist?

    @Relationship(deleteRule: .cascade)
    var songs: [SwiftDataSong] = []

    init(id: String = UUID().uuidString, title: String, releaseDate: Date? = nil, artworkURL: String? = nil, trackCount: Int = 0, artist: SwiftDataArtist? = nil) {
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.artworkURL = artworkURL
        self.trackCount = trackCount
        self.artist = artist
    }
}

extension SwiftDataAlbum {
    func toDomainModel() -> Album {
        return Album(
            id: self.id,
            title: self.title,
            artistID: self.artist?.id ?? "unknown_artist_id",
            releaseDate: self.releaseDate,
            artworkURL: self.artworkURL,
            trackCount: self.trackCount,
            songIDs: self.songs.map { $0.id }
        )
    }

    static func fromDomainModel(_ album: Album) -> SwiftDataAlbum {
        let sdAlbum = SwiftDataAlbum(
            id: album.id,
            title: album.title,
            releaseDate: album.releaseDate,
            artworkURL: album.artworkURL,
            trackCount: album.trackCount
        )
        return sdAlbum
    }
}
