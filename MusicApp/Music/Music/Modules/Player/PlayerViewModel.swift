import Foundation
import SwiftUI
import Combine

// MARK: - PlayerViewModel
class PlayerViewModel: ObservableObject {
    // MARK: - Dependencies
    private let playerInteractor: PlayerInteractorProtocol
    private let playerService: PlayerServiceProtocol

    // MARK: - Combine Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State Properties (для UI)
    @Published var currentSong: Song? = nil
    @Published var currentSongTitle: String = "No song"
    @Published var currentSongArtistID: String = ""
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    // MARK: - Initialization
    init(playerInteractor: PlayerInteractorProtocol, playerService: PlayerServiceProtocol) {
        self.playerInteractor = playerInteractor
        self.playerService = playerService

        setupPlayerServiceObservers()
    }

    // MARK: - Setup Observers (Combine Publishers)
    private func setupPlayerServiceObservers() {
        playerService.currentSongPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSong in
                guard let self = self else { return }
                self.currentSong = newSong
                self.currentSongTitle = newSong?.title ?? "No song"
                self.currentSongArtistID = newSong?.artistID ?? ""
            }
            .store(in: &cancellables)

        playerService.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsPlaying in
                self?.isPlaying = newIsPlaying
            }
            .store(in: &cancellables)

        playerService.currentTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTime in
                self?.currentTime = newTime
            }
            .store(in: &cancellables)

        playerService.durationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDuration in
                self?.duration = newDuration
            }
            .store(in: &cancellables)
    }

    // MARK: - Commands (Actions from UI)
    func playSong(id: String) async {
        do {
            try await playerInteractor.playSong(with: id)
        } catch {
            print("Error playing song: \(error)")
        }
    }

    func togglePlayPause() {
        playerService.togglePlayPause()
    }

    func seek(to time: TimeInterval) {
        playerService.seek(to: time)
    }

    // MARK: - Cleanup
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
