import SwiftUI
import UIKit

// MARK: - HomeView
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let albumDetailViewModel: AlbumDetailViewModel
    let playerViewModel: PlayerViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading recommendations...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            viewModel.loadRecommendations()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.albums) { album in
                            AlbumRowView(
                                album: album,
                                viewModel: viewModel,
                                albumDetailViewModel: albumDetailViewModel,
                                playerViewModel: playerViewModel
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Home")
            .onAppear {
                if viewModel.albums.isEmpty {
                    viewModel.loadRecommendations()
                }
            }
        }
    }
}

// MARK: - AlbumRowView
struct AlbumRowView: View {
    let album: Album
    let viewModel: HomeViewModel
    let albumDetailViewModel: AlbumDetailViewModel
    let playerViewModel: PlayerViewModel

    var body: some View {
        NavigationLink(destination: AlbumDetailView(
            viewModel: albumDetailViewModel,
            albumID: album.id,
            playerViewModel: playerViewModel
        )) {
            HStack {
                if let cachedData = viewModel.artworkCache[album.id],
                   let image = UIImage(data: cachedData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(5)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(viewModel.artistNames[album.artistID] ?? album.artistID)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}
