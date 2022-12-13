//
//  SuggestionViewController.swift
//  NextDoor
//
//  Created by Ilyes Djari on 14/11/2022.
//

import UIKit
import MusadoraKit
import MusicKit

class SuggestionViewController: UIViewController {

    
    
    @IBOutlet weak var stackView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        getLibrary()

    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    func getLibrary() {
        Task {
            let request = MusicRecentlyPlayedRequest<Song>()
            let response = try await request.response()
            let song = response.items
            for (_, element) in song.enumerated() {
                print(element.artistName)
                print(element.title)
                print((element.artwork?.url(width: 100, height: 100))! as URL)
            }
        }
    }
}
