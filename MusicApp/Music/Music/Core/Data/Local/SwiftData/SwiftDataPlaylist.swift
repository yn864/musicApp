import Foundation
import SwiftData

@Model
final class SwiftDataPlaylist {
    var id: String
    var name: String
    var createdAt: Date
    var songIDs: [String] = []
    
    @Relationship(deleteRule: .cascade)
    var songs: [SwiftDataSong] = []
    
    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date(), songs: [SwiftDataSong] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.songs = songs
        self.songIDs = songs.map { $0.id }
    }
}

extension SwiftDataPlaylist {
    func toDomainModel() -> Playlist {
        return Playlist(
            id: self.id,
            name: self.name,
            songIDs: self.songs.map { $0.id }
        )
    }
    
    static func fromDomainModel(_ playlist: Playlist) -> SwiftDataPlaylist {
        let sdPlaylist = SwiftDataPlaylist(
            id: playlist.id,
            name: playlist.name,
            createdAt: playlist.createdAt
        )
        sdPlaylist.songIDs = playlist.songIDs
        return sdPlaylist
    }
}
