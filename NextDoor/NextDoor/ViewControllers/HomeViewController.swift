//
//  HomeViewController.swift
//  NextDoor
//
//  Created by Ilyes Djari on 19/10/2022.
//

import UIKit
import MusicKit
import MusadoraKit
import Kingfisher

class HomeViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var loadingView: UIView!

    var resultSearch: MusicCatalogSearchResponse? = nil


    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .fullScreen
        searchBar.delegate = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.allowsSelectionDuringEditing = true
        tableView.dataSource = self
        tableView.rowHeight = 90.0
        hideSpinner()
    }

    private func showSpinner() {
        loading.startAnimating()
        loadingView.isHidden = false
    }

    private func hideSpinner() {
        loading.stopAnimating()
        loadingView.isHidden = true
    }

    internal func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }

    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        showSpinner()
        Task {
            let recentlyPlayedItems = try await MusadoraKit.catalogSearch(for: searchBar.text!, types: [.songs, .artists, .albums, .stations], limit: 25, offset: 1)
            resultSearch = recentlyPlayedItems
            tableView.reloadData()
        }
        searchBar.endEditing(true)
    }
}



extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: cell.contentView.frame.width, y: cell.contentView.frame.height)
        UIView.animate(withDuration: 0.5, animations: {
            cell.transform = CGAffineTransform(translationX: cell.contentView.frame.width, y: cell.contentView.frame.height)
            cell.alpha = 1
        })
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearch?.songs.count == nil {
            return 0
        } else {
            return (resultSearch?.songs.count)! }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "PlayerSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let player = segue.destination as! PlayerViewController
        let row = tableView.indexPathForSelectedRow!.row
        player.songToPlay = (resultSearch!.songs[row])
        player.songsQueue = (resultSearch!.songs)
        player.rowState = (row)
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! searchCell
        cell.imageView!.kf.indicatorType = .activity
        DispatchQueue.main.async { [self] in
            let url = resultSearch?.songs[indexPath.row].artwork!.url(width: 70, height: 70)
            cell.imageView!.kf.setImage(with: url)
            cell.imageView!.layer.cornerRadius = 5
            cell.imageView!.clipsToBounds = true
            cell.artistLabel.text = self.resultSearch?.songs[indexPath.row].title
            cell.artistName.text = self.resultSearch?.songs[indexPath.row].artistName
        }
        hideSpinner()
        return cell
    }
}



class searchCell: UITableViewCell {
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var artistName: UILabel!
}
