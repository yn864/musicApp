import SwiftUI

struct LibraryView: View {
    // MARK: - Dependencies
    @ObservedObject var viewModel: LibraryViewModel
    let playerViewModel: PlayerViewModel
    let playlistViewModel: PlaylistViewModel

    // MARK: - State
    @State private var showingEditPlaylist = false
    @State private var showingDeleteConfirmation = false
    @State private var editingPlaylist: Playlist?
    @State private var playlistToDelete: Playlist?
    @State private var editedName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading playlists...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.playlists) { playlist in
                            PlaylistRowView(
                                playlist: playlist,
                                playerViewModel: playerViewModel,
                                playlistViewModel: playlistViewModel,
                                onEdit: {
                                    editingPlaylist = playlist
                                    editedName = playlist.name
                                    showingEditPlaylist = true
                                },
                                onDelete: {
                                    playlistToDelete = playlist
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingCreatePlaylist = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreatePlaylist) {
                NavigationStack {
                    Form {
                        TextField("Playlist Name", text: $viewModel.newPlaylistName)
                    }
                    .navigationTitle("New Playlist")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                viewModel.showingCreatePlaylist = false
                                viewModel.newPlaylistName = ""
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Create") {
                                Task {
                                    await viewModel.createPlaylist()
                                }
                            }
                            .disabled(viewModel.newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditPlaylist) {
                NavigationStack {
                    Form {
                        TextField("Playlist Name", text: $editedName)
                    }
                    .navigationTitle("Edit Playlist")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingEditPlaylist = false
                                editedName = ""
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                guard let playlist = editingPlaylist else { return }
                                Task {
                                    await viewModel.updatePlaylistName(playlist.id, newName: editedName)
                                    showingEditPlaylist = false
                                }
                            }
                            .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .alert("Delete Playlist", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    playlistToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let playlist = playlistToDelete {
                        Task {
                            await viewModel.deletePlaylist(playlist)
                        }
                    }
                    playlistToDelete = nil
                }
            } message: {
                if let playlist = playlistToDelete {
                    Text("Are you sure you want to delete \"\(playlist.name)\"? This action cannot be undone.")
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadPlaylists()
                }
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack {
            Text("Error: \(message)")
                .foregroundColor(.red)
            Button("Retry") {
                Task {
                    await viewModel.loadPlaylists()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - PlaylistRowView
struct PlaylistRowView: View {
    let playlist: Playlist
    let playerViewModel: PlayerViewModel
    let playlistViewModel: PlaylistViewModel
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack {
            NavigationLink(destination: PlaylistView(
                viewModel: playlistViewModel,
                playlistID: playlist.id,
                playerViewModel: playerViewModel
            )) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(5)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("\(playlist.songIDs.count) songs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            Menu {
                Button("Edit Name") {
                    onEdit?()
                }
                
                Button("Delete Playlist", role: .destructive) {
                    onDelete?()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
    }
}
