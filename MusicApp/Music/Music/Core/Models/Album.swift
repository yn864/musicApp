import Foundation

// MARK: - Album
struct Album: Identifiable, Codable {
    let id: String
    let title: String
    let artistID: Artist.ID
    let releaseDate: Date?
    let artworkURL: String?
    let trackCount: Int
    let songIDs: [Song.ID]
}
