import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - State
    @State private var playerViewModel: PlayerViewModel?
    // Убираем @State для AlbumDetailViewModel
    @State private var showingAlbumView = true // Теперь по умолчанию true

    // MARK: - Dependencies (хранятся как обычные переменные, создаются в task)
    @State private var musicRepository: MusicRepository?
    @State private var playerInteractor: PlayerInteractor?
    @State private var playerService: PlayerService?

    var body: some View {
        ZStack {
            if showingAlbumView {
                // Передаём зависимости в AlbumDetailView
                // AlbumDetailView сам создаст и управляется своим ViewModel
                if let repo = musicRepository, let pInteractor = playerInteractor {
                    AlbumDetailView(musicRepository: repo, playerInteractor: pInteractor, albumID: "album-002")
                } else {
                    ProgressView("Загрузка зависимостей...")
                }
            } else if let playerVM = playerViewModel {
                PlayerView(playerViewModel: playerVM)
            } else {
                ProgressView("Загрузка...")
            }

            // Постоянно отображаемая кнопка переключения
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAlbumView.toggle()
                    }) {
                        Text(showingAlbumView ? "К плееру" : "К альбому")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                }
                .padding(.bottom)
            }
        }
        .task {
            await createDependencies()
        }
        .task {
            await runTestScenarios()
        }
    }

    // MARK: - Dependency Creation
    private func createDependencies() async {
        print("Создаём зависимости для PlayerViewModel и AlbumDetailViewModel...")

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

            await MainActor.run {
                self.musicRepository = musicRepo
                self.playerInteractor = playerInteract
                self.playerService = playerServ
                self.playerViewModel = playerVM
            }

            print("Все зависимости созданы успешно.")

        } catch {
            print("Ошибка при создании зависимостей: \(error)")
        }
    }

    // MARK: - Combined Test Scenarios
    private func runTestScenarios() async {
        print("Запускаем тестовые сценарии...")

        var attempts = 0
        while playerViewModel == nil || musicRepository == nil {
            if attempts > 20 {
                print("Таймаут ожидания зависимостей")
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        print("Запускаем сценарий плеера...")
        if !showingAlbumView {
            await setupTestScenario(viewModel: playerViewModel!)
        } else {
            print("Пропускаем сценарий плеера, так как начинаем с альбома.")
        }

        print("Запускаем сценарий альбома...")
        // AlbumDetailViewModel создаётся и управляет загрузкой ВНУТРИ AlbumDetailView
        // Мы НЕ можем вызвать setupAlbumTestScenario(viewModel:) здесь, т.к. нет доступа к viewModel
        print("Пропускаем сценарий альбома в ContentView. Он запускается в AlbumDetailView.onAppear.")
    }

    // MARK: - Player Test Scenario
    private func setupTestScenario(viewModel: PlayerViewModel) async {
        print("Начинаем тестовый сценарий через PlayerViewModel...")
        print("Загружаем и проигрываем песню song-001...")
        await viewModel.playSong(id: "song-001")
        try? await Task.sleep(for: .seconds(2))
        print("Состояние в PlayerViewModel:")
        print("  - currentSongTitle: \(viewModel.currentSongTitle)")
        print("  - isPlaying: \(viewModel.isPlaying)")
        print("  - currentTime: \(viewModel.currentTime)")
        print("  - duration: \(viewModel.duration)")
        print("Тестовый сценарий плеера завершён.")
    }
}

#Preview {
    ContentView()
}
