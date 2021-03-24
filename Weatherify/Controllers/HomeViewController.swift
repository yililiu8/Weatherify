//
//  HomeViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import UIKit
import CoreLocation
import SDWebImage

class HomeViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var userCoordinates: CLLocation?
    
    var weatherResult: Result?
    var city: String?
    var country: String?
    
    var recommendedTracks = [AudioTrack]()
    var customPlaylistTracks = [AudioTrack]()
    var recommendedPlaylists = [Playlist]()
    var refreshingWeatherData = false
    var shouldUpdateSpotifyTracks = false
    var previousWeather: String?
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var weatherTemp: UILabel!
    @IBOutlet weak var weatherView: UIView!
    @IBOutlet weak var highAndLowTemp: UILabel!
    @IBOutlet weak var playlistBtn: UIButton!
    @IBOutlet weak var songsCollectionView: UICollectionView!
    @IBOutlet weak var songRecommendationsTitle: UILabel!
    @IBOutlet weak var songsCollectionView2: UICollectionView!
    @IBOutlet weak var playlistTableView: UITableView!
    
    @IBOutlet var slideOutView: UIView!
    @IBOutlet var slideOutBlackView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    var slideOutBarCollapsed = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let redViewController = mainStoryBoard .instantiateViewController(withIdentifier: "HomeVC")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = redViewController
        
        playlistBtn.imageView?.contentMode = .scaleAspectFit
        weatherTemp.text = " "
        locationLabel.text = " "
        weatherImage.image = .none
        highAndLowTemp.text = " "
        songRecommendationsTitle.text = " "
        setupLocation()
        
        self.view.addSubview(slideOutBlackView)
        slideOutBlackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedBlackView(_:))))
        slideOutBlackView.alpha = 0
        slideOutBlackView.backgroundColor = .black
        slideOutBlackView.isHidden = true
        slideOutBlackView.frame = CGRect(x: 0, y:0, width: self.view.bounds.width, height: self.view.bounds.height)
        self.view.addSubview(slideOutView)
        slideOutView.frame = CGRect(x: -self.view.bounds.width/2, y:0, width: self.view.bounds.width/2, height: self.view.bounds.height)
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(sender:)))
        gesture.direction = .left
        self.view.addGestureRecognizer(gesture)
        
        getUserProfile()
        
        songsCollectionView.delegate = self
        songsCollectionView.dataSource = self
        songsCollectionView.allowsSelection = false
        songsCollectionView.tag = 1
        songsCollectionView2.delegate = self
        songsCollectionView2.dataSource = self
        songsCollectionView2.allowsSelection = false
        songsCollectionView2.tag = 2
        
        playlistTableView.dataSource = self
        playlistTableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateView), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func getUserProfile() {
        SpotifyService.shared.getCurrentUserProfile { [weak self] (userProfile, error) in
            DispatchQueue.main.async {
                if let userProfile = userProfile, error == nil {
                    self?.updateName(with: userProfile)
                    self?.nameLabel.text = userProfile.display_name
                    self?.emailLabel.text = userProfile.email
                    
                    guard let image = userProfile.images, !image.isEmpty else {
                        return
                    }
                    self?.profileImage.sd_setImage(with: URL(string: image[0].url), completed: nil)
                } else {
                    print(error ?? "")
                }
            }
        }
    }
    
    func updateName(with model: UserProfile) {
        Constants.user = model
        //welcome label
        let hi = "Hi, "
        let hi_attrs = [NSAttributedString.Key.font :  UIFont.init(name: "Roboto-Bold", size: 35)]
        let welcome = NSMutableAttributedString(string: hi, attributes: hi_attrs as [NSAttributedString.Key : Any])

        let name = model.display_name
        let name_attrs = [NSAttributedString.Key.font : UIFont.init(name: "Roboto-Bold", size: 35), NSAttributedString.Key.foregroundColor : UIColor.init(red: 30.0/255.0, green: 215.0/255.0, blue: 96.0/255.0, alpha: 1.0)]
        let name_string = NSMutableAttributedString(string:name, attributes:name_attrs as [NSAttributedString.Key : Any])
        welcome.append(name_string)
        welcomeLabel.attributedText = welcome
    }
    
    @objc func updateView() {
        print("update weather")
        refreshingWeatherData = true
        requestWeatherForLocation()
    }
    
    func updateLocationLabel() {
        let weath = "WEATHER IN "
        let weath_attrs = [NSAttributedString.Key.font :  UIFont.init(name: "Roboto-Medium", size: 13)]
        let location = NSMutableAttributedString(string: weath, attributes: weath_attrs as [NSAttributedString.Key : Any])
        
        let addr = (city ?? "") + ", " + (country ?? "")
        let city_attrs = [NSAttributedString.Key.font : UIFont.init(name: "Roboto-Bold", size: 13), NSAttributedString.Key.foregroundColor : UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)]
        let city_string = NSMutableAttributedString(string: addr.uppercased(), attributes: city_attrs as [NSAttributedString.Key : Any])
        location.append(city_string)
        locationLabel.attributedText = location
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func setupLocation() {
        self.showSpinner(onView: weatherView)
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, userCoordinates == nil {
            userCoordinates = locations.first
            locationManager.stopUpdatingLocation()
            requestWeatherForLocation()
        }
    }
    
    
    func queryByGenre(genres: Set<String>) {
        SpotifyService.shared.getRecommendations(genres: genres) { [weak self] (tracks, error) in
            DispatchQueue.main.async {
                if let tracks = tracks, error == nil {
                    self?.recommendedTracks = tracks.tracks
                    print(self?.recommendedTracks ?? "")
                    print(self?.recommendedTracks.count ?? -1)
                    self?.songsCollectionView.reloadData()
                    self?.songsCollectionView2.reloadData()
                } else {
                    print(error ?? "")
                }
            }
        }
    }
    
    func queryByPlaylist(query: [String]) {
        for key in query {
            SpotifyService.shared.searchPlaylists(key: key) { [weak self] (playlists, error) in
                DispatchQueue.main.async {
                    if let playlists = playlists, error == nil {
                        self?.recommendedPlaylists.append(contentsOf: playlists.playlists?.items ?? [Playlist]())
                        if self?.recommendedPlaylists.count == 6 {
                            self?.recommendedPlaylists.shuffle()
                            self?.playlistTableView.reloadData()
                        }
                    } else {
                        print(error ?? "")
                    }
                }
            }
        }
    }
    
    func getRecommendedSongsByGenre() {
        guard weatherResult != nil else {
            return
        }
        let description = weatherResult!.current.weather[0].description
        switch description {
        case "clear sky":
            queryByGenre(genres: ["pop", "hip-hop", "summer", "happy"])
            queryByPlaylist(query: ["sunny day", "happy", "party"])
        case "few clouds":
            queryByGenre(genres: ["pop", "hip-hop", "soul", "party"])
            queryByPlaylist(query: ["lofi", "pop", "hip-hop"])
        case "mist":
            queryByGenre(genres: ["jazz", "chill", "blues"])
            queryByPlaylist(query: ["lofi", "chill", "jazz"])
        case "scattered clouds":
            fallthrough
        case "broken clouds":
            queryByGenre(genres: ["chill", "pop", "indie", "indie-pop"])
            queryByPlaylist(query: ["indie", "lofi", "chill"])
        case "shower rain":
            queryByGenre(genres: ["rainy-day", "chill", "acoustic", "soul"])
            queryByPlaylist(query: ["rainy", "chill", "acoustic"])
        case "rain":
            queryByGenre(genres: ["rainy-day", "chill", "acoustic"])
            queryByPlaylist(query: ["rainy", "chill", "acoustic"])
        case "thunderstorm":
            queryByGenre(genres: ["rock", "sleep", "metal"])
            queryByPlaylist(query: ["nightstorms", "dark soundtrack", "sleep"])
        case "snow":
            queryByGenre(genres: ["chill", "classical", "metal", "jazz"])
            queryByPlaylist(query: ["wintery", "winter jazz", "classical"])
        default:
            queryByGenre(genres: ["chill", "pop", "party", "jazz", "classical", "indie"])
            queryByPlaylist(query: ["top"])
        }
    }
    
    func updateWeatherImage() {
        guard weatherResult != nil else {
            return
        }
        let description = weatherResult!.current.weather[0].description
        if previousWeather == description {
            shouldUpdateSpotifyTracks = false
            return
        }
        shouldUpdateSpotifyTracks = true
        print(description)
        switch description {
        case "clear sky":
            weatherImage.image = UIImage(named: "sunny")
            songRecommendationsTitle.text = "Songs for a sunny day"
        case "few clouds":
            weatherImage.image = UIImage(named: "partly-cloudy")
            songRecommendationsTitle.text = "Songs for a partly cloudy day"
        case "mist":
            fallthrough
        case "scattered clouds":
            fallthrough
        case "broken clouds":
            weatherImage.image = UIImage(named: "cloudy")
            songRecommendationsTitle.text = "Songs for a cloudy day"
        case "shower rain":
            weatherImage.image = UIImage(named: "sun-rain")
            songRecommendationsTitle.text = "Songs for a rainy day"
        case "rain":
            weatherImage.image = UIImage(named: "rainy")
            songRecommendationsTitle.text = "Songs for a rainy day"
        case "thunderstorm":
            weatherImage.image = UIImage(named: "thunderstorms")
            songRecommendationsTitle.text = "Songs for the thunderstom weather"
        case "snow":
            weatherImage.image = UIImage(named: "snowy")
            songRecommendationsTitle.text = "Songs for a snowy day"
        default:
            weatherImage.image = UIImage(named: "sun-rain")
            songRecommendationsTitle.text = "Recommended songs"
        }
    }
    
    func updateTemps() {
        let tempText = "\(Int(round(weatherResult!.current.temp)))°"
        weatherTemp.text = tempText
        
        let highLowText = "H: \(Int(round(weatherResult!.daily[0].temp.max)))° L: \(Int(round(weatherResult!.daily[0].temp.min)))°"
        highAndLowTemp.text = highLowText
    }
    
    func updateViews() {
        guard weatherResult != nil else {
            return
        }
        updateTemps()
        updateLocationLabel()
        updateWeatherImage()
        self.removeSpinner()
        if !refreshingWeatherData || shouldUpdateSpotifyTracks {
            getRecommendedSongsByGenre()
        } else {
            print("dont need to update spotify data")
        }
    }
    
    func getWeather() {
        DispatchQueue.main.async {
            WeatherService.shared.getWeather(onSuccess: { (result) in
                self.weatherResult = result
                
                self.weatherResult?.sortDailyArray()
                self.weatherResult?.sortHourlyArray()
                
                self.updateViews()
                
            }) { (errorMessage) in
                debugPrint(errorMessage)
            }
        }
    }
    
    func requestWeatherForLocation() {
        guard let currentLocation = userCoordinates else {
            return
        }
        if weatherResult != nil {
            previousWeather = weatherResult!.current.weather[0].description
        }
        
        let long = currentLocation.coordinate.longitude
        let lat = currentLocation.coordinate.latitude
        print("coordinates: \(long),\(lat)")
        WeatherService.shared.setLatitude(lat)
        WeatherService.shared.setLongitude(long)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    let placemark = placemarks[0]
                    if let city = placemark.locality {
                        self.city = city
                    }
                    if let country = placemark.country {
                        self.country = country
                    }
                }
            }
        }
        getWeather()
    }
    
    func generatePlaylist(genres: Set<String>, weather: String) {
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yy hh:mm:ss"
        let day = df.string(from: Date())
        
        let name = weather + " " + day
        SpotifyService.shared.createPlaylist(with: name) { [weak self] (id, error) in
            DispatchQueue.main.async {
                if let id = id, error == nil {
                    SpotifyService.shared.getRecommendations(genres: genres) { [weak self] (tracks, error) in
                        if let tracks = tracks, error == nil {
                            self?.customPlaylistTracks = tracks.tracks
                            SpotifyService.shared.addTrackToPlaylist(tracks: tracks.tracks, playlistID: id) { (result) in
                                if result {
                                    print("successfully added item to playlist")
                                    DispatchQueue.main.async {
                                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                                        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "playlistView") as! PlaylistViewController
                                        nextViewController.modalPresentationStyle = .fullScreen
                                        nextViewController.modalTransitionStyle = .coverVertical
                                        nextViewController.playlist = tracks.tracks
                                        nextViewController.playlist_name = name
                                        nextViewController.playlist_id = id
                                        
                                        self?.present(nextViewController, animated:true)
                                    }
                                } else {
                                    print("failed to add item to playlist")
                                }
                            }
                        } else {
                            print(error ?? "")
                        }
                    }
                } else {
                    print(error ?? "")
                }
            }
        }
//        SpotifyService.shared.getRecommendations(genres: genres) { [weak self] (tracks, error) in
//            if let tracks = tracks, error == nil {
//                self?.customPlaylistTracks = tracks.tracks
//
//            } else {
//                print(error ?? "")
//            }
//        }
    }
    
    @IBAction func generatePlaylist(_ sender: Any) {
        guard weatherResult != nil else {
            return
        }
        let description = weatherResult!.current.weather[0].description
        switch description {
        case "clear sky":
            generatePlaylist(genres: ["pop", "hip-hop", "summer", "happy"], weather: "Sunny")
        case "few clouds":
            generatePlaylist(genres: ["pop", "hip-hop", "soul", "party"], weather: "Partly Cloudy")
        case "mist":
            generatePlaylist(genres: ["jazz", "chill", "blues"], weather: "Cloudy")
        case "scattered clouds":
            fallthrough
        case "broken clouds":
            generatePlaylist(genres: ["chill", "pop", "indie", "indie-pop"], weather: "Cloudy")
        case "shower rain":
            generatePlaylist(genres: ["rainy-day", "chill", "acoustic", "soul"], weather: "Rainy")
        case "rain":
            generatePlaylist(genres: ["rainy-day", "chill", "acoustic"], weather: "Rainy")
        case "thunderstorm":
            generatePlaylist(genres: ["rock", "sleep", "metal"], weather: "Thundering")
        case "snow":
            generatePlaylist(genres: ["chill", "classical", "metal", "jazz"], weather: "Snowy")
        default:
            generatePlaylist(genres: ["chill", "pop", "party", "jazz", "classical", "indie"], weather: "WEATHER")
        }
    }
    
    @IBAction func openSpotify(_ sender: Any) {
        print("open")
        
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
    
    //MARK: Slide out Menu
    @IBAction func menuBtnTapped(_ sender: Any) {
        toggleMenu()
    }
    
    @objc func tappedBlackView(_ sender: UITapGestureRecognizer) {
       toggleMenu()
    }
    
    func toggleMenu() {
        print("Toggle Menu")
        if(slideOutBarCollapsed) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.slideOutView.frame.origin.x = 0
                self.slideOutBlackView.isHidden = false
                self.slideOutBlackView.alpha = 0.2
                self.slideOutView.frame.origin.x = 0
            }, completion: { completed in
                self.slideOutBarCollapsed = false
            })
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.slideOutView.frame.origin.x = -self.view.bounds.width/2
                self.slideOutBlackView.isHidden = true
                self.slideOutBlackView.alpha = 0
            }, completion: { completed in
                self.slideOutBarCollapsed = true
            })
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        toggleMenu()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination
        navigationController.modalPresentationStyle = .fullScreen
    }
    
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 129)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendedTracks.count/2
    }
    
    func setUpCell(track: AudioTrack, cell: SongCollectionViewCell) -> UICollectionViewCell{
        var nameText = track.name
        if track.artists.count > 1 {
            nameText += "(feat. "
            for i in 1...track.artists.count-1 {
                nameText += track.artists[i].name + ", "
            }
            nameText = String(nameText.dropLast(2))
            nameText += ")"
        }
        cell.title.text = track.name
        
        var artistText = ""
        for artist in track.artists {
            artistText += artist.name + ", "
        }
        cell.artist.text = String(artistText.dropLast(2))
        
        let images = track.album.images
        if images.isEmpty{
            return cell
        }
//        let urlString = images[0].url
        guard let url = URL(string: images[0].url) else {
            return cell
        }
        cell.albumCover.contentMode = .scaleAspectFill
        cell.albumCover.sd_setImage(with: url, completed: nil)
        
        return cell
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.songsCollectionView)
        let indexPath = self.songsCollectionView.indexPathForItem(at: location)
        
        if let index = indexPath?.row {
            print("Got clicked on index: \(index)!")
            print(recommendedTracks[index*2].external_urls)
            guard let url = recommendedTracks[index*2].external_urls["spotify"] else {
                return
            }
            openInSpotify(urlString: url)
        }
    }
    
    @objc func tap2(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.songsCollectionView2)
        let indexPath = self.songsCollectionView2.indexPathForItem(at: location)
        
        if let index = indexPath?.row {
            print("Got clicked on index: \(index)!")
            print(recommendedTracks[(index*2)+1].external_urls)
            guard let url = recommendedTracks[(index*2)+1].external_urls["spotify"] else {
                return
            }
            openInSpotify(urlString: url)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "songCell", for: indexPath) as! SongCollectionViewCell
            let index = indexPath.row
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            cell.openSpotifyBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            return setUpCell(track: recommendedTracks[index*2], cell: cell)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "songCell2", for: indexPath) as! SongCollectionViewCell
            let index = indexPath.row
            
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap2(_:))))
            cell.openSpotifyBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap2(_:))))
            return setUpCell(track: recommendedTracks[(index*2)+1], cell: cell)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Got clicked!")
    }


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isEqual(songsCollectionView), scrollView.isDragging {
            self.synchronizeScrollView(songsCollectionView2, toScrollView: songsCollectionView)
        }
        else if scrollView.isEqual(songsCollectionView2), scrollView.isDragging {
            self.synchronizeScrollView(songsCollectionView, toScrollView: songsCollectionView2)
        }
    }
    
    func synchronizeScrollView(_ scrollViewToScroll: UIScrollView, toScrollView scrolledView: UIScrollView) {
        var offset = scrollViewToScroll.contentOffset
        offset.x = scrolledView.contentOffset.x
        scrollViewToScroll.setContentOffset(offset, animated: false)
    }
    
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendedPlaylists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistCell") as! PlaylistTableViewCell
        let index = indexPath.row
        let playlist = recommendedPlaylists[index]
        cell.name.text = playlist.name
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let playlist = recommendedPlaylists[index]
        guard let url = playlist.external_urls["spotify"] else {
            return
        }
        openInSpotify(urlString: url)
    }
    
}
