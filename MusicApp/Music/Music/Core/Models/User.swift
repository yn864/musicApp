import Foundation

// MARK: - User
struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    let profilePictureURL: String?
    let likedSongIDs: [Song.ID]
    let playlistIDs: [Playlist.ID]
}
