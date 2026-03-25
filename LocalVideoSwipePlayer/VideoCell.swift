import UIKit
import AVFoundation

class VideoCell: UICollectionViewCell {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var videoURL: URL?
    private var fileName: String = ""
    
    private let playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 30
        btn.isHidden = true
        return btn
    }()
    
    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.tintColor = .white
        slider.thumbTintColor = .white
        slider.isHidden = true
        return slider
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupControls()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupControls() {
        contentView.addSubview(playPauseButton)
        contentView.addSubview(progressSlider)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderDragEnded), for: [.touchUpInside, .touchUpOutside])
        
        // 布局
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 60),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),
            
            progressSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            progressSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            progressSlider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50),
            progressSlider.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with url: URL, fileName: String) {
        self.videoURL = url
        self.fileName = fileName
        setupPlayer()
        showControlsTemporarily()
    }
    
    private func setupPlayer() {
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        player = AVPlayer(url: videoURL!)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = contentView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        contentView.layer.insertSublayer(playerLayer!, at: 0)
        
        // 恢复进度
        let savedTime = VideoDataManager.shared.loadProgress(for: fileName)
        if savedTime > 0 {
            player?.seek(to: CMTime(seconds: savedTime, preferredTimescale: 600))
        }
        
        // 添加进度观察
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = self.player?.currentItem?.duration.seconds, duration.isFinite else { return }
            self.progressSlider.value = Float(time.seconds / duration)
            // 保存进度
            VideoDataManager.shared.saveProgress(for: self.fileName, time: time.seconds)
        }
        
        // 播放结束通知
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // 添加点击显示控制层
        let tap = UITapGestureRecognizer(target: self, action: #selector(showControlsTemporarily))
        contentView.addGestureRecognizer(tap)
    }
    
    @objc private func playerDidFinishPlaying() {
        // 播放结束，重置进度
        VideoDataManager.shared.resetProgress(for: fileName)
        player?.seek(to: .zero)
        player?.play()
    }
    
    func play() {
        player?.play()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        hideControlsAfterDelay()
    }
    
    func pause() {
        player?.pause()
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        showControlsTemporarily()
    }
    
    @objc private func togglePlayPause() {
        if player?.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        guard let duration = player?.currentItem?.duration.seconds, duration.isFinite else { return }
        let targetTime = Double(slider.value) * duration
        player?.seek(to: CMTime(seconds: targetTime, preferredTimescale: 600))
        VideoDataManager.shared.saveProgress(for: fileName, time: targetTime)
    }
    
    @objc private func sliderDragEnded() {
        // 拖动结束后继续播放
        if player?.timeControlStatus != .playing {
            play()
        }
    }
    
    @objc private func showControlsTemporarily() {
        playPauseButton.isHidden = false
        progressSlider.isHidden = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
        perform(#selector(hideControls), with: nil, afterDelay: 3.0)
    }
    
    @objc private func hideControls() {
        playPauseButton.isHidden = true
        progressSlider.isHidden = true
    }
    
    private func hideControlsAfterDelay() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
        perform(#selector(hideControls), with: nil, afterDelay: 3.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }
}
