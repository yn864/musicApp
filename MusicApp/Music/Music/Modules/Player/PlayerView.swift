import SwiftUI

struct PlayerView: View {
    // MARK: - Dependencies
    @ObservedObject var playerViewModel: PlayerViewModel

    @State private var sliderValue: Double = 0.0
    @State private var isSliderBeingDragged = false

    var body: some View {
        VStack(spacing: 20) {
            if let artworkURLString = playerViewModel.currentSong?.artworkURL,
               let artworkURL = URL(string: artworkURLString, relativeTo: Config.apiBaseURL) {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                }
                .frame(width: 200, height: 200)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .frame(width: 200, height: 200)
            }

            Text("Player View")
                .font(.title)

            if let currentSong = playerViewModel.currentSong {
                VStack {
                    Text(currentSong.title)
                        .font(.headline)
                    Text(playerViewModel.currentArtist?.name ?? currentSong.artistID)
                        .font(.subheadline)
                }
            } else {
                Text("No song loaded")
            }

            VStack {
                Slider(
                    value: $sliderValue,
                    in: 0...max(playerViewModel.duration, 1),
                    onEditingChanged: { isEditing in
                        isSliderBeingDragged = isEditing
                        if isEditing {
                            sliderValue = playerViewModel.currentTime
                        } else {
                            playerViewModel.seek(to: sliderValue)
                        }
                    }
                )
                Text("\(formatTime(isSliderBeingDragged ? sliderValue : playerViewModel.currentTime)) / \(formatTime(playerViewModel.duration))")
                    .font(.caption)
            }

            HStack {
                Button(action: {
                    playerViewModel.playPreviousSong()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }

                Button(action: {
                    playerViewModel.togglePlayPause()
                }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                }

                Button(action: {
                    playerViewModel.playNextSong()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
            }
        }
        .padding()
        .onReceive(playerViewModel.$currentTime) { newTime in
            if !isSliderBeingDragged {
                sliderValue = newTime
            }
        }
        .onAppear {
            sliderValue = playerViewModel.currentTime
        }
        .onDisappear {
           if playerViewModel.isPlaying {
               playerViewModel.togglePlayPause()
           }
       }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
