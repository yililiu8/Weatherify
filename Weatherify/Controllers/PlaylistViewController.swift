//
//  PlaylistViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/23/21.
//

import UIKit
import SDWebImage

class PlaylistViewController: UIViewController {

    @IBOutlet weak var mainPlaylistCover: UIImageView!
    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet weak var playlistDetails: UILabel!
    @IBOutlet weak var spotifyBtn: UIButton!

    var playlist = [AudioTrack]()
    var playlist_name: String?
    var playlist_id: String?
    
    var playlist_obj: Playlist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        playlistTableView.dataSource = self
        playlistTableView.delegate = self
        playlistTitle.text = String(playlist_name!.dropLast(9))
        mainPlaylistCover.contentMode = .scaleAspectFill
        
        SpotifyService.shared.getPlaylist(with: playlist_id ?? "") { [weak self] (list, error) in
            DispatchQueue.main.async {
                if let list = list, error == nil {
                    print(list)
                    Constants.playlists?.append(list)
                    self?.playlist_obj = list
                    self?.mainPlaylistCover.sd_setImage(with: URL(string: list.images[0].url), completed: nil)
                } else {
                    print(error ?? "")
                }
            }
        }
        var ms = 0
        for track in playlist {
            ms += track.duration_ms
        }
        let totalTime = TimeInterval(Double(ms)/1000.0)
        if totalTime.hour == 0 {
            playlistDetails.text = "\(totalTime.minute)m \(totalTime.second)s - \( Constants.user!.display_name)"
        } else {
            playlistDetails.text = "\(totalTime.hour)h \(totalTime.minute)m - \( Constants.user!.display_name)"
        }
    }
    
    //MARK: spotify redirection functions
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
    
    @IBAction func goToSpotify(_ sender: Any) {
        guard let url = playlist_obj!.external_urls["spotify"] else {
            return
        }
        openInSpotify(urlString: url)
    }
    
    //MARK: Buttons
    @IBAction func shareBtn(_ sender: Any) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let url = playlist_obj!.external_urls["spotify"] else {
            return
        }
        let textToShare = url
        if let myWebsite = URL(string: url) {
            let objectsToShare = [textToShare, myWebsite, image ?? #imageLiteral(resourceName: "app-logo")] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
            activityVC.popoverPresentationController?.sourceView = (sender as! UIView)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func backBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension PlaylistViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myPlaylistCell") as! CustomPlaylistTableViewCell
        let index = indexPath.row
        
        let track = playlist[index]
        var nameText = track.name
        if track.artists.count > 1 {
            nameText += "(feat. "
            for i in 1...track.artists.count-1 {
                nameText += track.artists[i].name + ", "
            }
            nameText = String(nameText.dropLast(2))
            nameText += ")"
        }
        cell.name.text = track.name
        
        var artistText = ""
        for artist in track.artists {
            artistText += artist.name + ", "
        }
        cell.artist.text = String(artistText.dropLast(2))
        
        guard let images = track.album.images else {
            return cell
        }
        if images.isEmpty{
            return cell
        }
        guard let url = URL(string: images[0].url) else {
            return cell
        }
        cell.cover.contentMode = .scaleAspectFill
        cell.cover.sd_setImage(with: url, completed: nil)
        
        return cell
    }
    
    
}

