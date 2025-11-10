import AVFoundation
import Foundation
import OSLog
import Combine

// MARK: - PlayerServiceProtocol
protocol PlayerServiceProtocol: AnyObject {
    var currentSong: Song? { get }
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    
    // Combine publishers
    var currentSongPublisher: Published<Song?>.Publisher { get }
    var isPlayingPublisher: Published<Bool>.Publisher { get }
    var currentTimePublisher: Published<TimeInterval>.Publisher { get }
    var durationPublisher: Published<TimeInterval>.Publisher { get }
    
    func load(_ song: Song)
    func play()
    func pause()
    func togglePlayPause()
    func seek(to time: TimeInterval)
}

// MARK: - PlayerService Implementation
class PlayerService: PlayerServiceProtocol, ObservableObject {
    // MARK: - Published Properties (ObservableObject State)
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    
    // MARK: - Publisher Properties (for protocol)
    var currentSongPublisher: Published<Song?>.Publisher { $currentSong }
    var isPlayingPublisher: Published<Bool>.Publisher { $isPlaying }
    var currentTimePublisher: Published<TimeInterval>.Publisher { $currentTime }
    var durationPublisher: Published<TimeInterval>.Publisher { $duration }

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var durationObserver: NSKeyValueObservation?
    private let logger = Logger(subsystem: "MusicPlayer", category: "PlayerService")

    // MARK: - Initialization
    init() {
        setupAudioSession()
    }

    deinit {
        cleanup()
    }

    // MARK: - PlayerServiceProtocol Implementation
    func load(_ song: Song) {
        // Останавливаем предыдущее воспроизведение если песня другая
        if currentSong?.id != song.id {
            cleanupPlayer()
        }

        guard let localFilePathString = song.localFilePath,
              let songURL = URL(string: localFilePathString, relativeTo: Config.apiBaseURL) else {
            logger.error("Невозможно создать URL для песни: \(song.title), localFilePath: \(String(describing: song.localFilePath))")
            return
        }

        let newPlayerItem = AVPlayerItem(url: songURL)
        let newPlayer = AVPlayer(playerItem: newPlayerItem)

        self.player = newPlayer
        self.currentSong = song
        self.currentTime = 0
        
        // Сначала устанавливаем duration из Song как временное значение
        self.duration = song.duration ?? 0

        setupDurationObserver(for: newPlayerItem)
        setupTimeObserver()
        setupPlayerItemObservers(for: newPlayerItem)

        logger.info("Песня загружена: \(song.title)")
    }

    func play() {
        player?.play()
        isPlaying = true
        logger.info("Воспроизведение запущено.")
    }

    func pause() {
        player?.pause()
        isPlaying = false
        logger.info("Воспроизведение приостановлено.")
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        guard let player = player else {
            logger.warning("Player недоступен для перемотки.")
            return
        }

        let seekTime = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            if completed {
                self?.logger.debug("Перемотка завершена: \(time) секунд")
            }
        }
    }

    // MARK: - Private Helper Methods
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Не удалось настроить AVAudioSession: \(error)")
        }
    }

    private func cleanup() {
        cleanupPlayer()
        logger.info("PlayerService очищен.")
    }

    private func cleanupPlayer() {
        removeTimeObserver()
        durationObserver?.invalidate()
        durationObserver = nil
        
        player?.pause()
        player = nil
        currentSong = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    // MARK: - Time Observer
    private func setupTimeObserver() {
        removeTimeObserver()
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = time.seconds
            if seconds.isFinite && !seconds.isNaN {
                self.currentTime = seconds
            }
        }
    }

    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    // MARK: - Duration Observer
    private func setupDurationObserver(for playerItem: AVPlayerItem) {
        // Наблюдаем за реальной длительностью от AVPlayerItem
        durationObserver = playerItem.observe(\.duration, options: [.new, .initial]) { [weak self] item, change in
            guard let self = self else { return }
            
            let newDuration = item.duration.seconds
            if newDuration.isFinite && newDuration > 0 {
                DispatchQueue.main.async {
                    self.duration = newDuration
                    self.logger.info("Реальная длительность установлена: \(newDuration) секунд")
                }
            }
        }
    }

    // MARK: - Player Item Observers
    private func setupPlayerItemObservers(for playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
    }

    // MARK: - Notification Handlers
    @objc private func playerItemDidPlayToEndTime(_ notification: Notification) {
        logger.info("Песня достигла конца.")
        isPlaying = false
        currentTime = duration // Устанавливаем время в конец
    }

    @objc private func playerItemFailedToPlay(_ notification: Notification) {
        logger.error("Ошибка воспроизведения песни.")
        isPlaying = false
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            logger.error("Ошибка AVPlayerItem: \(error)")
        }
    }
}
