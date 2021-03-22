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

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var weatherTemp: UILabel!
    @IBOutlet weak var weatherView: UIView!
    @IBOutlet weak var highAndLowTemp: UILabel!
    @IBOutlet weak var playlistBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistBtn.imageView?.contentMode = .scaleAspectFit
        weatherTemp.text = " "
        locationLabel.text = " "
        weatherImage.image = .none
        highAndLowTemp.text = " "
        setupLocation()
        
        //welcome label
        let hi = "Hi, "
        let hi_attrs = [NSAttributedString.Key.font :  UIFont.init(name: "Roboto-Bold", size: 35)]
        let welcome = NSMutableAttributedString(string: hi, attributes: hi_attrs as [NSAttributedString.Key : Any])

        let name = "John"
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
