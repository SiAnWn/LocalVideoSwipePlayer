import Foundation
import UIKit

class VideoDataManager {
    static let shared = VideoDataManager()
    private let userDefaults = UserDefaults.standard
    
    private(set) var videoFiles: [URL] = []
    
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var videosDirectory: URL {
        documentsURL.appendingPathComponent("Videos")
    }
    
    private init() {
        createVideosDirectoryIfNeeded()
        copySampleVideosIfNeeded()
        reloadVideoList()
    }
    
    func reloadVideoList() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: videosDirectory, includingPropertiesForKeys: nil)
            videoFiles = files.filter { isValidVideoFile($0) }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        } catch {
            print("Failed to load videos: \(error)")
            videoFiles = []
        }
    }
    
    private func isValidVideoFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v"].contains(ext)
    }
    
    private func createVideosDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: videosDirectory.path) {
            try? FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func copySampleVideosIfNeeded() {
        // 首次启动时复制示例视频（这里不再内置示例视频，仅创建空目录，让用户自己添加）
        // 如果需要示例，请自行在Bundle中添加
        let didCopy = UserDefaults.standard.bool(forKey: "didCreateVideosFolder")
        if !didCopy {
            UserDefaults.standard.set(true, forKey: "didCreateVideosFolder")
        }
    }
    
    // MARK: - 进度记忆
    func saveProgress(for fileName: String, time: TimeInterval) {
        userDefaults.set(time, forKey: "progress_\(fileName)")
    }
    
    func loadProgress(for fileName: String) -> TimeInterval {
        return userDefaults.double(forKey: "progress_\(fileName)")
    }
    
    func resetProgress(for fileName: String) {
        userDefaults.removeObject(forKey: "progress_\(fileName)")
    }
    
    // MARK: - 播放顺序逻辑
    func nextIndex(current: Int) -> Int? {
        let newIndex = current + 1
        guard newIndex < videoFiles.count else { return 0 } // 循环顺序
        return newIndex
    }
    
    func randomIndex(excluding current: Int) -> Int {
        guard videoFiles.count > 1 else { return 0 }
        var newIndex = Int.random(in: 0..<videoFiles.count)
        while newIndex == current {
            newIndex = Int.random(in: 0..<videoFiles.count)
        }
        return newIndex
    }
}
