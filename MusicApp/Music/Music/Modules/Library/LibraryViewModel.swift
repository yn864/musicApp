import Foundation
import Combine

// MARK: - LibraryViewModel
class LibraryViewModel: ObservableObject {
    // MARK: - Dependencies
    private let interactor: LibraryInteractorProtocol
    
    // MARK: - State Properties
    @Published var playlists: [Playlist] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingCreatePlaylist = false
    @Published var newPlaylistName = ""
    
    // MARK: - Initialization
    init(interactor: LibraryInteractorProtocol) {
        self.interactor = interactor
    }
    
    // MARK: - Public Methods
    func loadPlaylists() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let playlists = try await interactor.fetchAllPlaylists()
            
            await MainActor.run {
                self.playlists = playlists
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func createPlaylist() async {
        guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        do {
            let playlist = try await interactor.createNewPlaylist(name: newPlaylistName)
            
            await MainActor.run {
                self.playlists.append(playlist)
                self.newPlaylistName = ""
                self.showingCreatePlaylist = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePlaylist(_ playlist: Playlist) async {
        do {
            try await interactor.deletePlaylist(playlist)
            
            await MainActor.run {
                self.playlists.removeAll { $0.id == playlist.id }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func updatePlaylistName(_ id: String, newName: String) async {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        do {
            let updatedPlaylist = try await interactor.updatePlaylistName(id, newName: newName)
            
            await MainActor.run {
                if let index = self.playlists.firstIndex(where: { $0.id == id }) {
                    self.playlists[index] = updatedPlaylist
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}
