import UIKit
import AVFoundation

class VideoFeedViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var currentIndex = 0
    private var isScrolling = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        // 随机初始视频
        let randomStart = Int.random(in: 0..<VideoDataManager.shared.videoFiles.count)
        currentIndex = randomStart
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.scrollToItem(at: IndexPath(item: randomStart, section: 0), at: .centeredVertically, animated: false)
            self?.playVideoAtCurrentIndex()
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = view.bounds.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: "VideoCell")
        view.addSubview(collectionView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = view.bounds.size
    }
    
    private func playVideoAtCurrentIndex() {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? VideoCell else { return }
        cell.play()
    }
    
    private func pauseAllVideosExcept(_ index: Int) {
        for i in 0..<VideoDataManager.shared.videoFiles.count {
            if i != index, let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? VideoCell {
                cell.pause()
            }
        }
    }
}

extension VideoFeedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VideoDataManager.shared.videoFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
        let videoURL = VideoDataManager.shared.videoFiles[indexPath.item]
        cell.configure(with: videoURL, fileName: videoURL.lastPathComponent)
        return cell
    }
}

extension VideoFeedViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(collectionView.contentOffset.y / collectionView.frame.height)
        guard pageIndex != currentIndex else { return }
        
        let oldIndex = currentIndex
        currentIndex = pageIndex
        pauseAllVideosExcept(currentIndex)
        playVideoAtCurrentIndex()
        isScrolling = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let pageIndex = Int(collectionView.contentOffset.y / collectionView.frame.height)
            if pageIndex != currentIndex {
                currentIndex = pageIndex
                pauseAllVideosExcept(currentIndex)
                playVideoAtCurrentIndex()
            }
            isScrolling = false
        }
    }
}

// 滑动手势处理（随机/顺序）
extension VideoFeedViewController {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        let velocity = touch.location(in: view).y - location.y
        
        if velocity > 0 { // 上滑 -> 随机
            let newIndex = VideoDataManager.shared.randomIndex(excluding: currentIndex)
            if newIndex != currentIndex {
                currentIndex = newIndex
                collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredVertically, animated: true)
                pauseAllVideosExcept(currentIndex)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.playVideoAtCurrentIndex()
                }
            }
        } else if velocity < 0 { // 下滑 -> 顺序
            if let newIndex = VideoDataManager.shared.nextIndex(current: currentIndex) {
                currentIndex = newIndex
                collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredVertically, animated: true)
                pauseAllVideosExcept(currentIndex)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.playVideoAtCurrentIndex()
                }
            }
        }
    }
}
