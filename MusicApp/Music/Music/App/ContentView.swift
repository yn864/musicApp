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

    init() {
        do {
            let schema = Schema([SwiftDataSong.self, SwiftDataAlbum.self, SwiftDataArtist.self])
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

            self.musicRepository = musicRepo
            self.playerService = playerServ
            self.playerInteractor = playerInteract
            self.playerViewModel = playerVM
            self.albumDetailInteractor = albumDetailInteract
            self.albumDetailViewModel = albumDetailVM
            self.homeViewModel = homeVM

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
                Text("Search Tab - Coming Soon")
                    .navigationTitle("Search")
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .tag(1)

            // MARK: - Library Tab
            NavigationStack {
                Text("Library Tab - Coming Soon")
                    .navigationTitle("Library")
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
