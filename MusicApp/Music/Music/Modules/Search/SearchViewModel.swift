import Foundation
import SwiftUI
import Combine

// MARK: - SearchViewModel
class SearchViewModel: ObservableObject {
    // MARK: - Dependencies
    private let interactor: SearchInteractorProtocol

    // MARK: - State Properties
    @Published var searchQuery: String = ""
    @Published var searchResults: SearchResults = SearchResults()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Search Results Structure
    struct SearchResults {
        var songs: [Song] = []
        var albums: [Album] = []
        
        var isEmpty: Bool {
            songs.isEmpty && albums.isEmpty
        }
    }

    // MARK: - Initialization
    init(interactor: SearchInteractorProtocol) {
        self.interactor = interactor
        setupSearchDebounce()
    }

    // MARK: - Commands
    func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = SearchResults()
            isLoading = false
            return
        }
        
        searchTask?.cancel()
        
        isLoading = true
        errorMessage = nil
        
        searchTask = Task {
            await performSearchAsync()
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = SearchResults()
        searchTask?.cancel()
        isLoading = false
        errorMessage = nil
    }
    
    func playSong(_ song: Song) {
        Task {
            await interactor.playSong(song)
        }
    }

    // MARK: - Private Methods
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }
    
    private func performSearchAsync() async {
        do {
            async let songsTask = interactor.searchSongs(query: searchQuery)
            async let albumsTask = interactor.searchAlbums(query: searchQuery)
            
            let (songs, albums) = try await (songsTask, albumsTask)
            
            await MainActor.run {
                self.searchResults = SearchResults(songs: songs, albums: albums)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
