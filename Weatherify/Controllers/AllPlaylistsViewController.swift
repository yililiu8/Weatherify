//
//  AllPlaylistsViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/23/21.
//

import UIKit

class AllPlaylistsViewController: UIViewController {

    @IBOutlet weak var playlistTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        playlistTableView.dataSource = self
        playlistTableView.delegate = self
        getMyPlaylists()
    }
    
    func getMyPlaylists() {
        SpotifyService.shared.getCurrentUserPlaylists { [weak self] (playlists, error) in
            DispatchQueue.main.async {
                if let playlists = playlists, error == nil {
                    Constants.playlists = playlists
                    self?.playlistTableView.reloadData()
                } else {
                    print(error ?? "")
                }
            }
        }
    }

    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true)
    }
    
}

extension AllPlaylistsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.playlists?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "allPlaylistCell") as! AllPlaylistsTableViewCell
        let index = indexPath.row
        let playlist = Constants.playlists![index]
        cell.name.text = playlist.name
        cell.owner.text = playlist.owner.display_name
        
        let images = playlist.images
        if images.isEmpty{
            return cell
        }
        guard let url = URL(string: images[0].url) else {
            return cell
        }
        cell.cover.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    func openInSpotify(urlString: String) {
        let url = URL(string: urlString)
        if UIApplication.shared.canOpenURL(url!)
        {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            
        } else {
            //redirect to safari because the user doesn't have Spotify
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let playlist = Constants.playlists![index]
        guard let url = playlist.external_urls["spotify"] else {
            return
        }
        openInSpotify(urlString: url)
    }
    
}
