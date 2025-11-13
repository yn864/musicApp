import Foundation

// MARK: - Playlist
struct Playlist: Identifiable, Codable {
    let id: String
    var name: String
    var songIDs: [Song.ID]
    var createdAt: Date
    
    var songCount: Int {
        return songIDs.count
    }
    
    init(id: String = UUID().uuidString, name: String, songIDs: [Song.ID] = []) {
        self.id = id
        self.name = name
        self.songIDs = songIDs
        self.createdAt = Date()
    }
}
