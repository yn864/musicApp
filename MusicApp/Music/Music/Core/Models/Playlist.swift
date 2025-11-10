import Foundation

// MARK: - Playlist
struct Playlist: Identifiable {
    let id: String
    let name: String
    let ownerID: User.ID
    let artworkURL: String?
    let songCount: Int
    let songIDs: [Song.ID]
    let isPublic: Bool
}
