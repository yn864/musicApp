import SwiftUI
import UIKit

// MARK: - AlbumDetailView
struct AlbumDetailView: View {
    // MARK: - Dependencies
    @ObservedObject var viewModel: AlbumDetailViewModel
    let albumID: String
    let playerViewModel: PlayerViewModel
    
    // MARK: - Init
    init(viewModel: AlbumDetailViewModel, albumID: String, playerViewModel: PlayerViewModel) {
        self.viewModel = viewModel
        self.albumID = albumID
        self.playerViewModel = playerViewModel
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
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            albumHeader
            playAlbumButton

            Text("Songs (\(viewModel.songs.count))")
                .font(.headline)

            ForEach(viewModel.songs) { song in
                NavigationLink(destination: PlayerView(playerViewModel: playerViewModel)) {
                    SongRowView(
                        song: song,
                        artistName: viewModel.albumArtist?.name ?? song.artistID
                    )
                }
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.playSong(song)
                })
            }
        }
        .padding()
    }

    private var albumHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Group {
                if let artworkData = viewModel.albumArtworkData,
                   let image = UIImage(data: artworkData) {
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


            Text(formatTime(song.duration ?? 0))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func formatTime(_ timeInterval: TimeInterval?) -> String {
        guard let time = timeInterval else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
