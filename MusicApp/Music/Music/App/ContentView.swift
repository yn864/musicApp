//
//  ContentView.swift
//  Music
//
//  Created by yananderson on 27.10.2025.
//

import SwiftUI
import SwiftData // Для ModelContainer

struct ContentView: View {
    // Создаём зависимости в View (для MVP/тестирования)
    @State private var playerViewModel: PlayerViewModel?

    var body: some View {
        VStack {
            if let viewModel = playerViewModel {
                // Передаём созданный ViewModel в PlayerView
                PlayerView(playerViewModel: viewModel) // <-- Раскомментировано
                    .task {
                        // Выполняем тестовую логику после появления View
                        await setupTestScenario(viewModel: viewModel)
                    }
            } else {
                // Показываем индикатор загрузки или сообщение, пока создаются зависимости
                ProgressView("Загрузка...")
                    .task {
                        await createDependencies()
                    }
            }
        }
    }

    // Функция для создания всех зависимостей
    private func createDependencies() async {
        print("Создаём зависимости для PlayerViewModel...")

        do {
            // 1. Создаём ModelContainer для SwiftData
            let schema = Schema([SwiftDataSong.self, SwiftDataAlbum.self, SwiftDataArtist.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) // isStoredInMemoryOnly: true для теста
            let container = try ModelContainer(for: schema, configurations: [configuration])

            // 2. Создаём зависимости
            let networkService = NetworkService(baseURL: Config.apiBaseURL) // Требует Config.apiBaseURL
            let storageService = SwiftDataStorageService(container: container)
            let musicRepository = MusicRepository(networkService: networkService, storageService: storageService)
            let playerService = PlayerService() // PlayerService сам реализует ObservableObject
            // Обновлённый PlayerInteractor (с seek и setVolume)
            let playerInteractor = PlayerInteractor(musicRepository: musicRepository, playerService: playerService)

            // 3. Создаём PlayerViewModel (с currentTime, duration, seek)
            let viewModel = PlayerViewModel(playerInteractor: playerInteractor, playerService: playerService)

            // 4. Сохраняем ViewModel в состоянии View
            await MainActor.run {
                self.playerViewModel = viewModel
            }

            print("Все зависимости созданы успешно.")

        } catch {
            print("Ошибка при создании зависимостей: \(error)")
            // Обработка ошибки (например, показать alert)
        }
    }

    // Функция для выполнения тестового сценария
    // Принимает viewModel как параметр
    private func setupTestScenario(viewModel: PlayerViewModel) async {
        print("Начинаем тестовый сценарий через PlayerViewModel...")

        // do {
            // 1. Загружаем и начинаем воспроизведение песни через PlayerViewModel
            // (PlayerViewModel -> PlayerInteractor -> MusicRepository -> NetworkService -> PlayerService)
            print("Загружаем и проигрываем песню song-001...")
            await viewModel.playSong(id: "song-001") // Используем метод ViewModel

            // Небольшая задержка, чтобы песня успела загрузиться и начать воспроизводиться
            try? await Task.sleep(for: .seconds(2))

            // 2. Проверяем состояние в ViewModel (оно синхронизировано с PlayerService)
            print("Состояние в PlayerViewModel (отражает состояние PlayerService):")
            print("  - currentSongTitle: \(viewModel.currentSongTitle)")
            print("  - currentSongArtistID: \(viewModel.currentSongArtistID)")
            print("  - isPlaying: \(viewModel.isPlaying)")
            print("  - currentTime: \(viewModel.currentTime)")
            print("  - duration: \(viewModel.duration)")
            // isLiked убрано

            // 3. Пытаемся переключить воспроизведение
            print("Переключаем воспроизведение (play/pause)...")
            viewModel.togglePlayPause()

            // Небольшая задержка
            try? await Task.sleep(for: .seconds(1))

            print("Состояние после togglePlayPause:")
            print("  - isPlaying (ViewModel): \(viewModel.isPlaying)")

            print("Тестовый сценарий завершён.")

        // } catch {
        //     print("Ошибка в тестовом сценарии: \(error)")
        // }
    }
}

#Preview {
    ContentView()
}
