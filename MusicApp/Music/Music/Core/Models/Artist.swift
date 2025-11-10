import Foundation

// MARK: - Artist
struct Artist: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String?
    let artworkURL: String? // изображение исполнителя
}
