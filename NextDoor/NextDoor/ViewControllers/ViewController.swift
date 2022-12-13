//
//  ViewController.swift
//  NextDoor
//
//  Created by Ilyes Djari on 18/10/2022.
//

import UIKit
import MusicKit
import Lottie


class ViewController: UIViewController {
    
    private var animationView: LottieAnimationView?
    override func viewDidLoad() {
        super.viewDidLoad()
        addAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkStatus()
    }
    
    @IBAction func LoginButton(_ sender: Any) {
        Task {
            _ = await MusicAuthorization.request()
            checkStatus()
        }
    }
    
    private func addAnimation() {
        animationView = .init(name: "login")
        animationView!.frame = CGRect(x: 7.5, y: 110, width: 400, height: 400)
        animationView!.contentMode = .scaleAspectFit
        animationView!.loopMode = .loop
        animationView!.animationSpeed = 0.5
        view.addSubview(animationView!)
        animationView!.play()
    }
    
    private func checkStatus() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "HomeView") as! HomeViewController
        switch MusicAuthorization.currentStatus {
        case .notDetermined:
            print("User needs to connect")
        case .denied:
            print("User has been denied")
        case .restricted:
            print("User is restricted")
        case .authorized:
            print("User is connected to Apple Music")
            nextViewController.modalPresentationStyle = .fullScreen
            self.present(nextViewController, animated:true, completion:nil)
        @unknown default:
            print("Waiting for user input")
        }
    }
}

