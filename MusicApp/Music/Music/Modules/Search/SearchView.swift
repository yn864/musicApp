import SwiftUI

struct SearchView: View {
    // MARK: - Dependencies
    @ObservedObject var viewModel: SearchViewModel
    let albumDetailViewModel: AlbumDetailViewModel
    let playerViewModel: PlayerViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    emptyResultsView
                } else {
                    searchResults
                }
                
                Spacer()
            }
            .navigationTitle("Search")
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search songs, albums...", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
    }
    
    // MARK: - Search Results
    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Albums Section
                if !viewModel.searchResults.albums.isEmpty {
                    sectionHeader(title: "Albums")
                    
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.searchResults.albums) { album in
                            SearchAlbumRow(
                                album: album,
                                albumDetailViewModel: albumDetailViewModel,
                                playerViewModel: playerViewModel
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Songs Section
                if !viewModel.searchResults.songs.isEmpty {
                    sectionHeader(title: "Songs")
                    
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.searchResults.songs) { song in
                            SearchSongRow(
                                song: song,
                                playerViewModel: playerViewModel,
                                searchViewModel: viewModel
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
    
    // MARK: - Empty Results
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Search Error")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.performSearch()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Search Album Row
struct SearchAlbumRow: View {
    let album: Album
    let albumDetailViewModel: AlbumDetailViewModel
    let playerViewModel: PlayerViewModel
    
    @State private var artworkImage: UIImage? = nil

    var body: some View {
        NavigationLink(destination: AlbumDetailView(
            viewModel: albumDetailViewModel,
            albumID: album.id,
            playerViewModel: playerViewModel
        )) {
            HStack(spacing: 12) {
                Group {
                    if let image = artworkImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text("Album")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            loadArtwork()
        }
    }
    
    private func loadArtwork() {
        guard let artworkURLString = album.artworkURL,
              let artworkURL = URL(string: artworkURLString, relativeTo: Config.apiBaseURL) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: artworkURL)
                await MainActor.run {
                    artworkImage = UIImage(data: data)
                }
            } catch {
                print("Failed to load artwork: \(error)")
            }
        }
    }
}

// MARK: - Search Song Row (ОБНОВЛЯЕМ - добавляем обложки)
struct SearchSongRow: View {
    let song: Song
    let playerViewModel: PlayerViewModel
    let searchViewModel: SearchViewModel
    
    @State private var artworkImage: UIImage? = nil

    var body: some View {
        NavigationLink(destination: PlayerView(playerViewModel: playerViewModel)) {
            HStack(spacing: 12) {
                Group {
                    if let image = artworkImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(song.artistID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatTime(song.duration ?? 0))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
        .simultaneousGesture(TapGesture().onEnded {
            searchViewModel.playSong(song)
        })
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadArtwork()
        }
    }
    
    private func loadArtwork() {
        guard let artworkURLString = song.artworkURL,
              let artworkURL = URL(string: artworkURLString, relativeTo: Config.apiBaseURL) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: artworkURL)
                await MainActor.run {
                    artworkImage = UIImage(data: data)
                }
            } catch {
                print("Failed to load song artwork: \(error)")
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval?) -> String {
        guard let time = timeInterval else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
