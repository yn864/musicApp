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
    @Published var currentArtist: Artist? = nil
    @Published var currentSongTitle: String = "No song"
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
                if let artistID = newSong?.artistID {
                    self.loadArtist(by: artistID)
                } else {
                    self.currentArtist = nil
                }
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

    private func loadArtist(by id: Artist.ID) {
        Task {
            do {
                let artist = try await playerInteractor.fetchArtist(by: id)
                await MainActor.run {
                    self.currentArtist = artist
                }
            } catch {
                await MainActor.run {
                    self.currentArtist = nil
                }
            }
        }
    }

    // MARK: - Commands (Actions from UI)
    func togglePlayPause() {
        playerInteractor.togglePlayPause()
    }

    func seek(to time: TimeInterval) {
        playerInteractor.seek(to: time)
    }

    func playNextSong() {
        Task {
            do {
                try await playerInteractor.playNextSong()
            } catch {
                print("Error playing next song: \(error)")
            }
        }
    }

    func playPreviousSong() {
        Task {
            do {
                try await playerInteractor.playPreviousSong()
            } catch {
                print("Error playing previous song: \(error)")
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
