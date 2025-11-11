import SwiftUI

struct AlbumDetailView: View {
    // MARK: - Dependencies (передаём сюда, т.к. создаются в ContentView)
    let musicRepository: MusicRepository
    let playerInteractor: PlayerInteractor
    let albumID: String

    // MARK: - ViewModel (управляет собой, используя @StateObject)
    @StateObject private var viewModel: AlbumDetailViewModel

    // MARK: - Init
    init(musicRepository: MusicRepository, playerInteractor: PlayerInteractor, albumID: String) {
        self.musicRepository = musicRepository
        self.playerInteractor = playerInteractor
        self.albumID = albumID
        // Создаём Interactor и ViewModel внутри View
        let interactor = AlbumDetailInteractor(musicRepository: musicRepository, playerInteractor: playerInteractor)
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(interactor: interactor))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading album...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                content
            }
        }
        .onAppear {
            // Загружаем альбом при появлении View
            viewModel.loadAlbum(by: albumID)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Обложка, название, исполнитель
            albumHeader

            // Кнопка PLAY для всего альбома
            playAlbumButton

            // Разделитель "Songs"
            Text("Songs (\(viewModel.songs.count))") // <--- Показываем количество
                .font(.headline)

            // Список песен
            ForEach(viewModel.songs) { song in
                SongRowView(song: song) {
                    viewModel.playSong(song)
                }
            }
        }
        .padding()
    }

    private var albumHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Исправляем URL обложки
            let safeArtworkURLString = viewModel.album?.artworkURL?
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            AsyncImage(url: safeArtworkURLString.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.album?.title ?? "Unknown Album")
                    .font(.title2.bold())
                    .lineLimit(2)

                Text(artistName(for: viewModel.album?.artistID ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let releaseDate = viewModel.album?.parsedReleaseDate {
                    Text(releaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let releaseDateString = viewModel.album?.releaseDate {
                    Text(releaseDateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
        }
    }

    private var playAlbumButton: some View {
        Button(action: {
            if let firstSong = viewModel.songs.first {
                viewModel.playSong(firstSong)
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .foregroundColor(.black)
                Text("PLAY")
                    .font(.title2.bold())
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(30)
        }
        .disabled(viewModel.songs.isEmpty)
    }

    private func artistName(for artistID: String) -> String {
        let artistNames = [
            "artist-001": "Queen",
            "artist-002": "Led Zeppelin"
        ]
        return artistNames[artistID] ?? artistID
    }
}

// MARK: - SongRowView (вспомогательный View для строки песни)
struct SongRowView: View {
    let song: Song
    let onPlayTapped: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.body)
                Text(artistName(for: song.artistID))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onPlayTapped) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())

            Text(formatTime(song.duration ?? 0))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    private func artistName(for artistID: String) -> String {
        let artistNames = [
            "artist-001": "Queen",
            "artist-002": "Led Zeppelin"
        ]
        return artistNames[artistID] ?? artistID
    }

    private func formatTime(_ timeInterval: TimeInterval?) -> String {
        guard let time = timeInterval else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
