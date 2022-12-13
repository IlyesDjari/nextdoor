//
//  PlayerViewController.swift
//  NextDoor
//
//  Created by Ilyes Djari on 25/10/2022.
//

import UIKit
import MusicKit
import MusadoraKit
import Kingfisher
import Foundation
import AVFoundation
import MediaPlayer
import MarqueeLabel
import UIImageColors


class PlayerViewController: UIViewController {


    @IBOutlet weak var playerViewGroup: UIView!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var sliderView: UISlider!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var playerBackground: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextSongButton: UIButton!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var songLength: UILabel!
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var previousSongButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!

    private let formatter = DateComponentsFormatter()
    private let mpVolumeView = MPVolumeView()
    private var volumeSlider: MPVolumeView!
    private var playbackStatus: Double!
    private var dragging: Bool = false
    public var playing: Bool = false
    private var state = ApplicationMusicPlayer.shared.state
    private var timer = Timer()
    public var songToPlay: Song!
    private var songTime: Int!
    public var songsQueue: MusicItemCollection<Song>!
    public var rowState: Int!
    private var isPlaybackQueueSet = false
    var isPlaying: Bool {
        return (playerState.playbackStatus == .playing)
    }
    var playerState = ApplicationMusicPlayer.shared.state
    var playbackQueueState = false
    let player = ApplicationMusicPlayer.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        volumeSlider = MPVolumeView(frame: volumeView.bounds)
        volumeView.addSubview(volumeSlider)
        playSong()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        sliderView.isContinuous = false
        state.playbackStatus == .playing ? playButton.setBackgroundImage(UIImage(named: "pause.png"), for: UIControl.State.normal) : playButton.setBackgroundImage(UIImage(named: "play.png"), for: UIControl.State.normal)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)

    }


    @IBAction func nextSong(_ sender: Any) {
        if (rowState < 24) {
            rowState = rowState + 1
            songToPlay = songsQueue[rowState]
            playSong()
            UIView.transition(with: self.coverImage,
                              duration: 0.75,
                              options: .transitionFlipFromRight,
                              animations: { () -> Void in
                                  self.coverImage?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85) }
                              , completion: { (_ finished: Bool) -> Void in
                                  UIView.animate(withDuration: 0.75, animations: { () -> Void in
                                                     self.coverImage?.transform = CGAffineTransform(scaleX: 1, y: 1)
                                                 })
                              })
        } else {
            rowState = 0
        }
    }

    @IBAction func previousSong(_ sender: Any) {
        if (rowState > 0) {
            rowState = rowState - 1
            songToPlay = songsQueue[rowState]
            playSong()
            UIView.transition(with: self.coverImage,
                              duration: 0.75,
                              options: .transitionFlipFromLeft,
                              animations: { () -> Void in
                                  self.coverImage?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85) }
                              , completion: { (_ finished: Bool) -> Void in
                                  UIView.animate(withDuration: 0.75, animations: { () -> Void in
                                                     self.coverImage?.transform = CGAffineTransform(scaleX: 1, y: 1)
                                                 })
                              })
        } else {
            rowState = 24
        }
    }

    @IBAction func playButtonAction(_ sender: Any) {
        state.playbackStatus == .playing ? player.pause() : play()
        state.playbackStatus == .playing ? playButton.setBackgroundImage(UIImage(named: "pause.png"), for: UIControl.State.normal) : playButton.setBackgroundImage(UIImage(named: "play.png"), for: UIControl.State.normal)
        state.playbackStatus == .playing ? UIView.animate(withDuration: 0.5, animations: { () -> Void in self.playerViewGroup.transform = CGAffineTransform(scaleX: 0.85, y: 0.85) }) : UIView.animate(withDuration: 0.5, animations: { [self] () -> Void in playerViewGroup.transform = CGAffineTransform(scaleX: 1, y: 1) })

    }


    @IBAction func sliderDragging(_ sender: Any) {
        dragging = true
        UIView.transition(with: self.sliderView,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { () -> Void in
                              self.sliderView?.transform = CGAffineTransform(scaleX: 1, y: 2.1) })
    }



    @IBAction func sliderActions(_ sender: Any) {
        player.playbackTime = TimeInterval(sliderView.value)
        dragging = false
        UIView.transition(with: self.sliderView,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { () -> Void in
                              self.sliderView?.transform = CGAffineTransform(scaleX: 1, y: 1) })
    }

    @IBAction func muteAction(_ sender: Any) {
        let slider = mpVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) { [self] in
            if (slider!.value > 0) {
                MPVolumeView.setVolume(0.0)
                mute()
            } else {
                MPVolumeView.setVolume(0.3)
                unmute()
            }
        }
    }

    func mute() {
        let image = UIImage(named: "mute.png")
        self.volumeButton.setBackgroundImage(image, for: UIControl.State.normal)
    }

    func unmute() {
        let image = UIImage(named: "volume.png")
        self.volumeButton.setBackgroundImage(image, for: UIControl.State.normal)
    }

    func playSong() {
        playerStyle()
        if !isPlaying {
            playNewSong()
        }
        else {
            player.pause()
            timer.invalidate()
            playNewSong()
        }
    }

    func checkPlayback() {
        playbackStatus = ApplicationMusicPlayer.shared.playbackTime
        state.playbackStatus == .playing ? playButton.setBackgroundImage(UIImage(named: "pause.png"), for: UIControl.State.normal) : playButton.setBackgroundImage(UIImage(named: "play.png"), for: UIControl.State.normal)
        if (dragging == false) {
            sliderView.value = Float(playbackStatus)
        }
        if (sliderView.value.rounded() == Float(((songToPlay.duration?.rounded())!)) && sliderView.value < Float(songToPlay.duration!)) {
            nextSong((Any).self)
        }
        currentTime.text = formatter.string(from: Double(sliderView.value))!

        let slider = mpVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) { [self] in
            if (slider!.value > 0) {
                unmute()
            } else {
                mute()
            }
        }

    }

    func playNewSong() {
        player.queue = [songToPlay]
        isPlaybackQueueSet = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
            self.checkPlayback()
        })
        play()
    }

    func play() {
        Task {
            do {
                try await player.play()
                playing = true
            } catch {
                print("Failed to prepare to play with error: \(error).")
            }
        }
    }


    func playerStyle() {
        let imgURL = songToPlay.artwork?.url(width: 500, height: 500)
        sliderView.maximumValue = Float(songToPlay.duration!)
        coverImage.kf.indicatorType = .activity
        coverImage.kf.setImage(with: imgURL) { [self] result in
            switch result {
            case .success(let value):
                let colors = value.image.getColors()
                UIView.animate(withDuration: 1.0) { [self] in
                    self.playerBackground.backgroundColor = colors?.background
                    sliderView.tintColor = colors?.detail
                    volumeSlider.tintColor = colors?.secondary
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
        songLength.text = formatter.string(from: songToPlay.duration!)
        songName.text = songToPlay.title
        artistName.text = songToPlay.artistName
        UIView.transition(with: self.sliderView,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { () -> Void in
                              self.volumeView?.transform = CGAffineTransform(scaleX: 1, y: 1) })
        coverImage.layer.shadowOffset = CGSize(width: 50, height: 50)
        coverImage.layer.shadowRadius = 10
        coverImage.layer.shadowOpacity = 1
    }

    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .right:
                previousSong((Any).self)
            case .left:
                nextSong((Any).self).self
            default:
                break
            }
        }
    }

}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let mpVolumeView = MPVolumeView()
        let slider = mpVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
