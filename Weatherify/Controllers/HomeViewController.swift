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
    
    @IBOutlet weak var scrollView: UIScrollView!
    
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
    
    var spotifyAPISuccess = false
    var currentlyRefreshing = false
    
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
    @IBOutlet var loadScreen: UIView!
    @IBOutlet weak var loadScreenSun: UIImageView!
    
    @IBOutlet var slideOutView: UIView!
    @IBOutlet var slideOutBlackView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    var slideOutBarCollapsed = true
    
    @IBOutlet var playlistLoadingView: UIView!
    @IBOutlet weak var playlistProgressBar: UIProgressView!
    @IBOutlet weak var viewPlaylistBtn: UIButton!
    @IBOutlet weak var customProgressBar: DesignableProgessView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
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
        
        playlistTableView.frame.size.height = 300
        
        Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { timer in
            if self.spotifyAPISuccess {
                timer.invalidate()
            } else {
                self.getRecommendedSongsByGenre()
            }
        }
        
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: 1175)
        
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
        
        setUpLoadScreen()
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
        
        scrollView.refreshControl = UIRefreshControl()
        
        scrollView.refreshControl!.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        scrollView.addSubview(scrollView.refreshControl!)
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
                    self?.profileImage.sd_setImage(with: URL(string: image[0].url ?? "https://media-exp1.licdn.com/dms/image/C560BAQFkDzx_7dqq3A/company-logo_200_200/0/1519902995023?e=2159024400&v=beta&t=i5ZK3TSEVda9sbJ8o23SYYI11X7cUKPL6zW_TJhwLFw"), completed: nil)
                } else {
                    print(error ?? "")
                }
            }
        }
    }
    
    //MARK: update/refresh functions
    @objc func refresh(_ sender: AnyObject) {
        currentlyRefreshing = true
        updateView()
        scrollView.refreshControl!.endRefreshing()
    }
    
    @objc func updateView() {
        print("update weather")
        refreshingWeatherData = true
        setUpLoadScreen()
        requestWeatherForLocation()
    }
    
    func updateViews() {
        guard weatherResult != nil else {
            return
        }
        updateTemps()
        updateLocationLabel()
        updateWeatherImage()
        self.removeSpinner()
        if !refreshingWeatherData || shouldUpdateSpotifyTracks || currentlyRefreshing {
            getRecommendedSongsByGenre()
        } else {
            print("dont need to update spotify data")
            loadScreen.isHidden = true
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
    
    //MARK: weather functions
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
        case "overcast clouds":
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
        let tempText = "\(Int(round(weatherResult!.current.temp)))??"
        weatherTemp.text = tempText
        
        let highLowText = "H: \(Int(round(weatherResult!.daily[0].temp.max)))?? L: \(Int(round(weatherResult!.daily[0].temp.min)))??"
        highAndLowTemp.text = highLowText
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
    
    //MARK: API call functions
    func queryByGenre(genres: Set<String>) {
        SpotifyService.shared.getRecommendations(genres: genres) { [weak self] (tracks, error) in
            DispatchQueue.main.async {
                if let tracks = tracks, error == nil {
                    self?.recommendedTracks = tracks.tracks ?? [AudioTrack]()
                    print(self?.recommendedTracks ?? "")
                    print(self?.recommendedTracks.count ?? -1)
                    self?.songsCollectionView.reloadData()
                    self?.songsCollectionView2.reloadData()
                } else {
                    print(error ?? "")
                    self?.spotifyAPISuccess = false
                }
            }
        }
    }
    
    func queryByPlaylist(query: [String]) {
        loadScreen.isHidden = true
        recommendedPlaylists = [Playlist]()
        for key in query {
            SpotifyService.shared.searchPlaylists(key: key) { [weak self] (playlists, error) in
                DispatchQueue.main.async {
                    if let playlists = playlists, error == nil {
                        self?.recommendedPlaylists.append(contentsOf: playlists.playlists?.items ?? [Playlist]())
                        if self?.recommendedPlaylists.count == 6 {
                            self?.recommendedPlaylists.shuffle()
                            self?.playlistTableView.reloadData()
                            self?.loadScreen.isHidden = true
                            self?.spotifyAPISuccess = true
                        }
                    } else {
                        print(error ?? "")
                        self?.spotifyAPISuccess = false
                    }
                }
            }
        }
    }
    
    //MARK: select songs based on weather
    func getRecommendedSongsByGenre() {
        guard weatherResult != nil else {
            return
        }
        let description = weatherResult!.current.weather[0].description
        print(description)
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
        case "overcast clouds":
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
            queryByGenre(genres: ["chill", "pop", "party", "jazz", "classical"])
            queryByPlaylist(query: ["top", "top", "top"])
        }
    }
    
    //MARK: location manager
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
    
    func setUpLoadScreen() {
        if currentlyRefreshing {
            return
        }
        loadScreen.frame = CGRect(x: 0, y:0, width: self.view.bounds.width, height: self.view.bounds.height)
        loadScreen.isHidden = false
        self.view.addSubview(loadScreen)
        UIView.animate(withDuration: 4.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.loadScreenSun.transform = self.loadScreenSun.transform.rotated(by: .pi * -1.3)
        }, completion: { completed in
            
        })
        var count = 0
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { timer in
            if self.loadScreen.isHidden {
                self.spotifyAPISuccess = true
                timer.invalidate()
            }
            else if count == 1 {
                timer.invalidate()
                let alert = UIAlertController(title: "Error", message: "An unexpected error occured while signing you in, please try again.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { (action) in
                    DispatchQueue.main.async {
                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .coverVertical
                        self.present(vc, animated:true, completion: {
                            self.loadScreen.isHidden = true
                            self.spotifyAPISuccess = true
                            self.navigationController?.popToRootViewController(animated: false)
                        })
                    }
                }))
                self.present(alert, animated: true)
            } else {
                count += 1
                UIView.animate(withDuration: 4.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                    self.loadScreenSun.transform = self.loadScreenSun.transform.rotated(by: .pi * -1.3)
                }, completion: { completed in

                })
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    //MARK: playlist generator functions
    let nextViewController = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "playlistView") as! PlaylistViewController
    var blackview = UIView()
    func generatePlaylist(genres: Set<String>, weather: String) -> Bool {
        
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yy hh:mm:ss"
        let day = df.string(from: Date())
        var success = true
        
        let name = weather + " " + day
        SpotifyService.shared.createPlaylist(with: name) { [weak self] (id, error) in
            DispatchQueue.main.async {
                if let id = id, error == nil {
                    self?.playlistProgressBar?.setProgress(1.0/3.0, animated: true)
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut , animations: {
                        self?.customProgressBar.progress = 1.0/3.0
                    }, completion: nil)
                    SpotifyService.shared.getRecommendations(genres: genres) { [weak self] (tracks, error) in
                        if let tracks = tracks, error == nil {
                            self?.customPlaylistTracks = tracks.tracks ?? [AudioTrack]()
                            guard let m_tracks = tracks.tracks else {
                                success = false
                                return
                            }
                            DispatchQueue.main.async {
                                self?.playlistProgressBar?.setProgress(2.0/3.0, animated: true)
                                self?.customProgressBar.progress = 2.0/3.0
                                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut , animations: {
                                    self?.customProgressBar.progress = 2.0/3.0
                                }, completion: nil)
                            }
                            SpotifyService.shared.addTrackToPlaylist(tracks: m_tracks, playlistID: id) { (result) in
                                if result {
                                    
                                    print("successfully added item to playlist")
                                    DispatchQueue.main.async {
//                                        self?.playlistProgressBar?.setProgress(1.0, animated: true)
                                        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut , animations: {
                                            self?.playlistProgressBar?.setProgress(1.0, animated: true)
                                            self?.customProgressBar.progress = 1.0
                                        }, completion: { (complete) in
                                            if complete {
                                                self?.viewPlaylistBtn.isEnabled = true
                                                self?.viewPlaylistBtn.isHidden = false
                                                self?.playlistLoadingView.bringSubviewToFront((self?.viewPlaylistBtn)!)
                                            }
                                        })
                                        self?.nextViewController.modalPresentationStyle = .fullScreen
                                        self?.nextViewController.modalTransitionStyle = .coverVertical
                                        self?.nextViewController.playlist = m_tracks
                                        self?.nextViewController.playlist_name = name
                                        self?.nextViewController.playlist_id = id
                                        
                                        success = true
                                    }
                                } else {
                                    print("failed to add item to playlist")
                                    success = false
                                    return
                                }
                            }
                        } else {
                            print(error ?? "")
                            success = false
                            return
                        }
                    }
                } else {
                    print(error ?? "")
                    success = false
                    return
                }
            }
        }
        return success
    }
    
    public func updateProgress() {
        if playlistProgressBar.isHidden == false {
            playlistProgressBar?.setProgress(Constants.playlistProgress, animated: true)
        }
    }
    
    func setUpPlaylistPopup() {
        blackview.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        blackview.backgroundColor = .black
        blackview.alpha = 0.3
        self.view.addSubview(blackview)
        
        playlistProgressBar.transform = playlistProgressBar.transform.scaledBy(x: 1, y: 10)
        playlistProgressBar.progress = 0.0
        playlistProgressBar.layer.cornerRadius = 0.1
        self.playlistProgressBar.clipsToBounds = true
        playlistProgressBar.isHidden = true
        
        customProgressBar.progress = 0.0
        
        self.view.addSubview(playlistLoadingView)
        viewPlaylistBtn.isHidden = true
        playlistLoadingView.isHidden = false
        playlistLoadingView.frame.size.width = 335
        playlistLoadingView.frame.size.height = 315
        playlistLoadingView.center.x = self.view.center.x
        playlistLoadingView.center.y = self.view.frame.height * 3 / 4
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.playlistLoadingView.center = self.view.center
        }, completion: nil)
    }
    
    @IBAction func viewPlaylistBtn(_ sender: Any) {
        self.playlistLoadingView.removeFromSuperview()
        self.blackview.removeFromSuperview()
        self.playlistLoadingView.isHidden = true
        self.present(nextViewController, animated:true)
    }
    
    @IBAction func generatePlaylist(_ sender: Any) {
        guard weatherResult != nil else {
            return
        }
        setUpPlaylistPopup()
        let description = weatherResult!.current.weather[0].description
        var res = true
        switch description {
        case "clear sky":
            res = generatePlaylist(genres: ["pop", "hip-hop", "summer", "happy"], weather: "Sunny")
        case "few clouds":
            res = generatePlaylist(genres: ["pop", "hip-hop", "soul", "party"], weather: "Partly Cloudy")
        case "mist":
            res = generatePlaylist(genres: ["jazz", "chill", "blues"], weather: "Cloudy")
        case "scattered clouds":
            fallthrough
        case "overcast clouds":
            fallthrough
        case "broken clouds":
            res = generatePlaylist(genres: ["chill", "pop", "indie", "indie-pop"], weather: "Cloudy")
        case "shower rain":
            res = generatePlaylist(genres: ["rainy-day", "chill", "acoustic", "soul"], weather: "Rainy")
        case "rain":
            res = generatePlaylist(genres: ["rainy-day", "chill", "acoustic"], weather: "Rainy")
        case "thunderstorm":
            res = generatePlaylist(genres: ["rock", "sleep", "metal"], weather: "Thundering")
        case "snow":
            res = generatePlaylist(genres: ["chill", "classical", "metal", "jazz"], weather: "Snowy")
        default:
            res = generatePlaylist(genres: ["chill", "pop", "party", "jazz", "indie"], weather: "WEATHER")
        }
        if !res {
            let alert = UIAlertController(title: "Error", message: "An unexpected error occured while creating your playlist. Try again.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: redirect to spotify app functions
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

//MARK: song recommender collection views
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
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
        
        guard let images = track.album.images else {
            return cell
        }
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
        if scrollView.isEqual(self.scrollView) {
            if scrollView.contentOffset.x != 0 {
                scrollView.contentOffset.x = 0
            }
        }
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

//MARK: playlist recommender table view
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendedPlaylists.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistCell") as! AllPlaylistsTableViewCell
        let index = indexPath.row
        let playlist = recommendedPlaylists[index]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let playlist = recommendedPlaylists[index]
        guard let url = playlist.external_urls["spotify"] else {
            return
        }
        openInSpotify(urlString: url)
    }
    
}
