//
//  MakerViewModel.swift
//  LipersFree
//

import AVFoundation
import Observation
import SwiftUI

@MainActor
@Observable
final class MakerViewModel {

    enum Step {
        case landing
        case frameSelection(videoURL: URL)
        case preview(videoURL: URL, frameTime: CMTime, still: UIImage, ratio: AspectRatio)

        var index: Int {
            switch self {
            case .landing:        0
            case .frameSelection: 1
            case .preview:        2
            }
        }
    }

    var step: Step = .landing
    var isSaving = false
    var toast: Toast?

    // MARK: - Navigation

    func videoSelected(_ url: URL) {
        withAnimation(.easeInOut(duration: 0.25)) {
            step = .frameSelection(videoURL: url)
        }
    }

    func framePicked(videoURL: URL, at time: CMTime, still: UIImage, ratio: AspectRatio) {
        withAnimation(.easeInOut(duration: 0.25)) {
            step = .preview(videoURL: videoURL, frameTime: time, still: still, ratio: ratio)
        }
    }

    func goBack() {
        withAnimation(.easeInOut(duration: 0.25)) {
            switch step {
            case .frameSelection:             step = .landing
            case .preview(let url, _, _, _):  step = .frameSelection(videoURL: url)
            default: break
            }
        }
    }

    // MARK: - Save

    func save(videoURL: URL, frameTime: CMTime, ratio: AspectRatio, trimStart: Double, trimEnd: Double) async {
        isSaving = true
        defer { isSaving = false }
        let trimRange = CMTimeRange(
            start: CMTime(seconds: trimStart, preferredTimescale: 600),
            end:   CMTime(seconds: trimEnd,   preferredTimescale: 600)
        )
        do {
            try await LivePhotoCreator.shared.createAndSave(
                videoURL: videoURL,
                frameTime: frameTime,
                ratio: ratio,
                trimRange: trimRange
            )
            showToast("Live Photo saved to Camera Roll")
            withAnimation(.easeInOut(duration: 0.25)) { step = .landing }
        } catch {
            showToast(error.localizedDescription, isError: true)
        }
    }

    // MARK: - Toast

    func showToast(_ message: String, isError: Bool = false) {
        withAnimation { toast = Toast(message: message, isError: isError) }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { toast = nil }
        }
    }
}
