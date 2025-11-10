import Foundation
import SwiftData

@Model
final class SwiftDataArtist {
    var id: String
    var name: String
    var bio: String?
    var artworkURL: String?

    // Связи
    @Relationship(deleteRule: .cascade)
    var albums: [SwiftDataAlbum] = []

    @Relationship(deleteRule: .cascade)
    var songs: [SwiftDataSong] = []

    init(id: String = UUID().uuidString, name: String, bio: String? = nil, artworkURL: String? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.artworkURL = artworkURL
    }
}

extension SwiftDataArtist {
    func toDomainModel() -> Artist {
        return Artist(
            id: self.id,
            name: self.name,
            bio: self.bio,
            artworkURL: self.artworkURL
        )
    }

    static func fromDomainModel(_ artist: Artist) -> SwiftDataArtist {
        let sdArtist = SwiftDataArtist(
            id: artist.id,
            name: artist.name,
            bio: artist.bio,
            artworkURL: artist.artworkURL
        )
        return sdArtist
    }
}
