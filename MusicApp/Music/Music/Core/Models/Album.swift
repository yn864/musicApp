import Foundation

// MARK: - Album
struct Album: Identifiable, Codable {
    let id: String
    let title: String
    let artistID: Artist.ID
    let releaseDate: String?
    let artworkURL: String?
    let trackCount: Int
    let songIDs: [Song.ID]

    var parsedReleaseDate: Date? {
        guard let dateString = releaseDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: dateString)
    }
}
