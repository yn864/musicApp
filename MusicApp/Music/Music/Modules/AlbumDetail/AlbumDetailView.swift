import SwiftUI
import UIKit

// MARK: - AlbumDetailView
struct AlbumDetailView: View {
    // MARK: - Dependencies
    let musicRepository: MusicRepository
    let playerInteractor: PlayerInteractor
    let albumID: String

    // MARK: - ViewModel
    @StateObject private var viewModel: AlbumDetailViewModel

    // MARK: - State для UIImage
    @State private var albumArtworkImage: UIImage? = nil

    // MARK: - Init
    init(musicRepository: MusicRepository, playerInteractor: PlayerInteractor, albumID: String) {
        self.musicRepository = musicRepository
        self.playerInteractor = playerInteractor
        self.albumID = albumID
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
            viewModel.loadAlbum(by: albumID)
        }
        .onChange(of: viewModel.albumArtworkData) { _, newData in
            if let data = newData {
                self.albumArtworkImage = UIImage(data: data)
            } else {
                self.albumArtworkImage = nil
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            albumHeader
            playAlbumButton

            Text("Songs (\(viewModel.songs.count))")
                .font(.headline)

            ForEach(viewModel.songs) { song in
                SongRowView(
                    song: song,
                    artistName: viewModel.albumArtist?.name ?? song.artistID
                ) {
                    viewModel.playSong(song)
                }
            }
        }
        .padding()
    }

    private var albumHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Group {
                if let image = albumArtworkImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.album?.title ?? "Unknown Album")
                    .font(.title2.bold())
                    .lineLimit(2)

                Text(viewModel.albumArtist?.name ?? "Unknown Artist")
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
}

// MARK: - SongRowView (вспомогательный View для строки песни)
struct SongRowView: View {
    let song: Song
    let artistName: String
    let onPlayTapped: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.body)
                Text(artistName)
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

    private func formatTime(_ timeInterval: TimeInterval?) -> String {
        guard let time = timeInterval else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
