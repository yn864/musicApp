import SwiftUI

struct PlayerView: View {
    // MARK: - Dependencies
    @ObservedObject var playerViewModel: PlayerViewModel

    @State private var sliderValue: Double = 0.0
    @State private var isSliderBeingDragged = false
    @State private var lastSeekTime: Date = Date()
    @State private var ignoreUpdatesUntil: Date = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Player View")
                .font(.title)

            if let currentSong = playerViewModel.currentSong {
                VStack {
                    Text(currentSong.title)
                        .font(.headline)
                    Text(currentSong.artistID)
                        .font(.subheadline)
                }
            } else {
                Text("No song loaded")
            }

            // --- Слайдер для перемотки ---
            VStack {
                Slider(
                    value: Binding(
                        get: {
                            isSliderBeingDragged ? sliderValue : playerViewModel.currentTime
                        },
                        set: { newValue in
                            sliderValue = newValue
                            
                            if isSliderBeingDragged {
                                playerViewModel.seek(to: newValue)
                                // УВЕЛИЧИВАЕМ время игнорирования до 0.8 секунд
                                let ignoreUntil = Date().addingTimeInterval(0.8)
                                ignoreUpdatesUntil = ignoreUntil
                                lastSeekTime = Date()
                            }
                        }
                    ),
                    in: 0...max(playerViewModel.duration, 1),
                    onEditingChanged: { isEditing in
                        isSliderBeingDragged = isEditing
                        if isEditing {
                            sliderValue = playerViewModel.currentTime
                        } else {
                            playerViewModel.seek(to: sliderValue)
                            let ignoreUntil = Date().addingTimeInterval(0.8)
                            ignoreUpdatesUntil = ignoreUntil
                            lastSeekTime = Date()
                        }
                    }
                )
                Text("\(formatTime(isSliderBeingDragged ? sliderValue : playerViewModel.currentTime)) / \(formatTime(playerViewModel.duration))")
                    .font(.caption)
            }

            HStack {
                Button(action: {
                    // playerViewModel.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .disabled(true)

                Button(action: {
                    playerViewModel.togglePlayPause()
                }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                }

                Button(action: {
                    // playerViewModel.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .disabled(true)
            }

            Button("Play Song (song-001)") {
                Task {
                    await playerViewModel.playSong(id: "song-001")
                }
            }
        }
        .padding()
        .onChange(of: playerViewModel.currentTime) { oldTime, newTime in
            let now = Date()
            // ОБНОВЛЯЕМ СЛАЙДЕР ТОЛЬКО ЕСЛИ:
            // 1. Не перетаскиваем
            // 2. И текущее время ПОСЛЕ времени до которого игнорируем
            if !isSliderBeingDragged && now > ignoreUpdatesUntil {
                sliderValue = newTime
            }
        }
        .onAppear {
            sliderValue = playerViewModel.currentTime
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
