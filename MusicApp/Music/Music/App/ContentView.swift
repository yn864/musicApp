import SwiftUI
import SwiftData

// MARK: - Coordinator for shared dependencies
class AppCoordinator: ObservableObject {
    @Published var playerService: PlayerService
    @Published var musicRepository: MusicRepository
    @Published var playerInteractor: PlayerInteractor
    @Published var playerViewModel: PlayerViewModel
    @Published var albumDetailInteractor: AlbumDetailInteractor
    @Published var albumDetailViewModel: AlbumDetailViewModel
    @Published var homeViewModel: HomeViewModel
    @Published var searchViewModel: SearchViewModel
    @Published var playlistService: PlaylistService
    @Published var playlistInteractor: PlaylistInteractor
    @Published var playlistViewModel: PlaylistViewModel
    @Published var libraryInteractor: LibraryInteractor
    @Published var libraryViewModel: LibraryViewModel

    init() {
        do {
            let schema = Schema([SwiftDataSong.self, SwiftDataAlbum.self, SwiftDataArtist.self, SwiftDataPlaylist.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])

            let networkService = NetworkService(baseURL: Config.apiBaseURL)
            let storageService = SwiftDataStorageService(container: container)
            let musicRepo = MusicRepository(networkService: networkService, storageService: storageService)
            let playerServ = PlayerService()
            let playerInteract = PlayerInteractor(musicRepository: musicRepo, playerService: playerServ)
            let playerVM = PlayerViewModel(playerInteractor: playerInteract, playerService: playerServ)
            let albumDetailInteract = AlbumDetailInteractor(musicRepository: musicRepo, playerInteractor: playerInteract)
            let albumDetailVM = AlbumDetailViewModel(interactor: albumDetailInteract)
            let homeInteractor = HomeInteractor(musicRepository: musicRepo)
            let homeVM = HomeViewModel(interactor: homeInteractor)
            let searchInteractor = SearchInteractor(
                musicRepository: musicRepo,
                playerInteractor: playerInteract
            )
            let searchVM = SearchViewModel(interactor: searchInteractor)
            let playlistServ = PlaylistService(musicRepository: musicRepo)
            let playlistInteract = PlaylistInteractor(
                playlistService: playlistServ,
                playerInteractor: playerInteract,
                musicRepository: musicRepo
            )
            let playlistVM = PlaylistViewModel(interactor: playlistInteract)
            let libraryInteract = LibraryInteractor(musicRepository: musicRepo)
            let libraryVM = LibraryViewModel(interactor: libraryInteract)

            self.musicRepository = musicRepo
            self.playerService = playerServ
            self.playerInteractor = playerInteract
            self.playerViewModel = playerVM
            self.albumDetailInteractor = albumDetailInteract
            self.albumDetailViewModel = albumDetailVM
            self.homeViewModel = homeVM
            self.searchViewModel = searchVM
            self.playlistService = playlistServ
            self.playlistInteractor = playlistInteract
            self.playlistViewModel = playlistVM
            self.libraryInteractor = libraryInteract
            self.libraryViewModel = libraryVM
            

        } catch {
            fatalError("Failed to create AppCoordinator: \(error)")
        }
    }
}

struct ContentView: View {
    // MARK: - Shared Dependencies & ViewModels
    @StateObject private var appCoordinator = AppCoordinator()

    // MARK: - Tab Selection
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Home Tab
            NavigationStack {
                HomeView(
                    viewModel: appCoordinator.homeViewModel,
                    albumDetailViewModel: appCoordinator.albumDetailViewModel,
                    playerViewModel: appCoordinator.playerViewModel
                )
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)

            // MARK: - Search Tab
            NavigationStack {
                SearchView(
                    viewModel: appCoordinator.searchViewModel,
                    albumDetailViewModel: appCoordinator.albumDetailViewModel,
                    playerViewModel: appCoordinator.playerViewModel
                )
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .tag(1)

            // MARK: - Library Tab
            NavigationStack {
                LibraryView(
                    viewModel: appCoordinator.libraryViewModel,
                    playerViewModel: appCoordinator.playerViewModel,
                    playlistViewModel: appCoordinator.playlistViewModel
                )
            }
            .tabItem {
                Image(systemName: "music.note.list")
                Text("Library")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
