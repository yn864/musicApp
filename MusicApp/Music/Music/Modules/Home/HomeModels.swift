import Foundation

// MARK: - Request
struct HomeRequest {
    let userId: String
}

// MARK: - Response
struct HomeResponse {
    let recentlyPlayedIDs: [Song.ID]
    let recommendedIDs: [Album.ID]
    let jumpBackInIDs: [Album.ID]
}

// MARK: - ViewModel
struct HomeViewModel {
    let recentlyPlayed: [SongViewModel]
    let recommended: [AlbumViewModel]
    let jumpBackIn: [AlbumViewModel]
}

// MARK: - ViewModels для отдельных элементов
struct SongViewModel: Identifiable {
    let id: String
    let title: String
    let artistName: String
    let albumArtURL: String?
}

struct AlbumViewModel: Identifiable {
    let id: String
    let title: String
    let artistName: String
    let albumArtURL: String?
}

// MARK: - Extensions для преобразования из доменных моделей в ViewModel
extension SongViewModel {
    init(from song: Song, artist: Artist, album: Album) {
        self.id = song.id
        self.title = song.title
        self.artistName = artist.name
        self.albumArtURL = album.artworkURL
    }
}

extension AlbumViewModel {
    init(from album: Album, artist: Artist) {
        self.id = album.id
        self.title = album.title
        self.artistName = artist.name
        self.albumArtURL = album.artworkURL
    }
}
