import SwiftUI
import AVKit

struct VideoViewerView: View {
    let videoURL: URL
    @ObservedObject var progressManager: ProgressManager
    let materialID: UUID
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if isLoading {
                    loadingView
                } else {
                    videoPlayerView
                }
            }
            .navigationTitle("Video Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save progress and dismiss
                        if let currentTime = player?.currentTime().seconds {
                            progressManager.saveProgress(materialID: materialID, videoTime: currentTime)
                        }
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private var videoPlayerView: some View {
        VStack(spacing: 0) {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                        isLoading = status == .waitingToPlayAtSpecifiedRate
                    }
                    .onReceive(player.publisher(for: \.currentItem?.duration)) { duration in
                        if let duration = duration {
                            self.duration = CMTimeGetSeconds(duration)
                        }
                    }
                    .onReceive(player.publisher(for: \.currentTime)) { time in
                        currentTime = CMTimeGetSeconds(time)
                    }
            }
            
            // Custom controls
            VStack(spacing: 12) {
                // Progress slider
                if duration > 0 {
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: Binding(
                                get: { currentTime },
                                set: { newValue in
                                    let time = CMTime(seconds: newValue, preferredTimescale: 1)
                                    player?.seek(to: time)
                                }
                            ),
                            in: 0...duration
                        )
                        
                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Playback controls
                HStack(spacing: 20) {
                    Button(action: {
                        if let player = player {
                            let newTime = max(0, currentTime - 10)
                            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
                        }
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                    }
                    
                    Button(action: {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                    }
                    
                    Button(action: {
                        if let player = player {
                            let newTime = min(duration, currentTime + 10)
                            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
                        }
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                    }
                }
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading video...")
                .font(.headline)
                .padding(.top)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Video Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                setupPlayer()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func setupPlayer() {
        isLoading = true
        errorMessage = nil
        
        // Create AVPlayer
        let avPlayer = AVPlayer(url: videoURL)
        
        // Set up time observer for progress tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = CMTimeGetSeconds(time)
        }
        
        // Load saved progress
        if progressManager.lastMaterialID == materialID {
            let savedTime = progressManager.lastVideoTime
            avPlayer.seek(to: CMTime(seconds: savedTime, preferredTimescale: 1))
        }
        
        // Check if video can be played
        avPlayer.currentItem?.addObserver(avPlayer, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Handle video loading errors
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            errorMessage = "Failed to load video. Please check your internet connection."
            isLoading = false
        }
        
        self.player = avPlayer
        
        // Start playing
        avPlayer.play()
        isPlaying = true
        isLoading = false
    }
    
    private func cleanupPlayer() {
        // Save current progress
        if let currentTime = player?.currentTime().seconds {
            progressManager.saveProgress(materialID: materialID, videoTime: currentTime)
        }
        
        // Clean up observers
        player?.currentItem?.removeObserver(player!, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        
        player?.pause()
        player = nil
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}