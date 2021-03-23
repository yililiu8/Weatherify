//
//  HomeViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import UIKit
import CoreLocation


class HomeViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var userCoordinates: CLLocation?
    
    var weatherResult: Result?
    var city: String?
    var country: String?
    
    var recommendedTracks = [AudioTrack]()

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var weatherTemp: UILabel!
    @IBOutlet weak var weatherView: UIView!
    @IBOutlet weak var highAndLowTemp: UILabel!
    @IBOutlet weak var playlistBtn: UIButton!
    @IBOutlet weak var songsCollectionView: UICollectionView!
    @IBOutlet weak var songsCollectionView2: UICollectionView!
    
    let dummyData: [AudioTrackTemp] = [AudioTrackTemp.init(albumCover: nil, title: "See You Again (feat. Kali Uchis)", artist: "Tyler, The Creator, Kail Uchis"), AudioTrackTemp.init(albumCover: nil, title: "What a time (feat. Niall Horan)", artist: "Julia Michaels, Niall Horan"), AudioTrackTemp.init(albumCover: nil, title: "Song Title", artist: "Artist Name"), AudioTrackTemp.init(albumCover: nil, title: "Song Title2", artist: "Artist Name2")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistBtn.imageView?.contentMode = .scaleAspectFit
        weatherTemp.text = " "
        locationLabel.text = " "
        weatherImage.image = .none
        highAndLowTemp.text = " "
        setupLocation()
        
        SpotifyService.shared.getCurrentUserProfile { [weak self] (userProfile, error) in
            DispatchQueue.main.async {
                if let userProfile = userProfile, error == nil {
                    self?.updateName(with: userProfile)
                } else {
                    print(error ?? "")
                }
            }
        }
        
//        SpotifyService.shared.searchSongs(key: "chill", genre: "pop") { [weak self] (songs, error) in
//            print(songs ?? error)
//        }
        
//        SpotifyService.shared.getRecommendations(genres: ["pop", "edm"]) { (albums, error) in
//            print(albums)
//        }
        
        songsCollectionView.delegate = self
        songsCollectionView.dataSource = self
        songsCollectionView.allowsSelection = false
        songsCollectionView.tag = 1
        songsCollectionView2.delegate = self
        songsCollectionView2.dataSource = self
        songsCollectionView2.allowsSelection = false
        songsCollectionView2.tag = 2
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateView), name: UIApplication.didBecomeActiveNotification, object: nil)
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
    
    func getRecommendedSongsByGenre() {
        /* winter jazz music */
        guard weatherResult != nil else {
            return
        }
        let description = weatherResult!.current.weather[0].description
        switch description {
        case "clear sky":
            queryByGenre(genres: ["pop", "hip-hop", "summer", "happy"])
        case "few clouds":
            queryByGenre(genres: ["pop", "hip-hop", "soul", "party"])
        case "mist":
            queryByGenre(genres: ["jazz", "chill", "blues"])
        case "scattered clouds":
            fallthrough
        case "broken clouds":
            queryByGenre(genres: ["chill", "pop", "indie", "indie-pop"])
        case "shower rain":
            queryByGenre(genres: ["rainy-day", "chill", "acoustic", "soul"])
        case "rain":
            queryByGenre(genres: ["rainy-day", "chill", "acoustic"])
        case "thunderstorm":
            queryByGenre(genres: ["rock", "sleep", "metal"])
        case "snow":
            queryByGenre(genres: ["chill", "classical", "metal", "jazz"])
        default:
            queryByGenre(genres: ["chill", "pop", "party", "jazz", "classical", "indie"])
        }
    }
    
    func updateWeatherImage() {
        guard weatherResult != nil else {
            return
        }
        let description = weatherResult!.current.weather[0].description
        print(description)
        switch description {
        case "clear sky":
            weatherImage.image = UIImage(named: "sunny")
        case "few clouds":
            weatherImage.image = UIImage(named: "partly-cloudy")
        case "mist":
            fallthrough
        case "scattered clouds":
            fallthrough
        case "broken clouds":
            weatherImage.image = UIImage(named: "cloudy")
        case "shower rain":
            weatherImage.image = UIImage(named: "sun-rain")
        case "rain":
            weatherImage.image = UIImage(named: "rainy")
        case "thunderstorm":
            weatherImage.image = UIImage(named: "thunderstorms")
        case "snow":
            weatherImage.image = UIImage(named: "snowy")
        default:
            weatherImage.image = UIImage(named: "sun-rain")
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
        getRecommendedSongsByGenre()
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
    
    @IBAction func generatePlaylist(_ sender: Any) {
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 129)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return dummyData.count/2
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
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "songCell", for: indexPath) as! SongCollectionViewCell
            let index = indexPath.row
            
            return setUpCell(track: recommendedTracks[index*2], cell: cell)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "songCell2", for: indexPath) as! SongCollectionViewCell
            let index = indexPath.row
            
            return setUpCell(track: recommendedTracks[(index*2)+1], cell: cell)
        }
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
