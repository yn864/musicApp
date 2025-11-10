import Foundation

// MARK: - Song
struct Song: Identifiable, Codable {
    let id: String
    let title: String
    let artistID: Artist.ID
    let albumID: Album.ID
    let duration: TimeInterval? // в секундах
    let artworkURL: String?
    var isLiked: Bool
    let localFilePath: String?
}
