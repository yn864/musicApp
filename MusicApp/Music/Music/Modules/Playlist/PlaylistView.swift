import SwiftUI

// MARK: - PlaylistView
struct PlaylistView: View {
    // MARK: - Dependencies
    @ObservedObject var viewModel: PlaylistViewModel
    let playlistID: String
    let playerViewModel: PlayerViewModel

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading playlist...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                content
            }
        }
        .navigationTitle(viewModel.playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadPlaylist(by: playlistID)
        }
    }

    // MARK: - Content
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            playlistHeader
            playPlaylistButton
            
            Text("Songs (\(viewModel.songs.count))")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.songs.isEmpty {
                emptySongsView
            } else {
                songsList
            }
        }
        .padding()
    }

    // MARK: - Playlist Header
    private var playlistHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Placeholder for playlist artwork
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.playlist?.name ?? "Unknown Playlist")
                    .font(.title2.bold())
                    .lineLimit(2)

                Text("\(viewModel.songs.count) songs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let createdAt = viewModel.playlist?.createdAt {
                    Text("Created \(createdAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
        }
    }

    // MARK: - Play Playlist Button
    private var playPlaylistButton: some View {
        Button(action: {
            viewModel.playPlaylist()
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

    // MARK: - Songs List
    private var songsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.songs) { song in
                NavigationLink(destination: PlayerView(playerViewModel: playerViewModel)) {
                    HStack {
                        SongRowView(
                            song: song,
                            artistName: song.artistID
                        )
                        
                        Spacer()
                        
                        Menu {
                            Button("Remove from Playlist", role: .destructive) {
                                viewModel.removeSongFromPlaylist(song)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.playSong(song)
                })
            }
        }
    }

    // MARK: - Empty Songs View
    private var emptySongsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Songs in Playlist")
                .font(.headline)
            
            Text("Add songs to this playlist from anywhere in the app")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Error Loading Playlist")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
