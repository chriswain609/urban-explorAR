//
//  MapViewController.swift
//  urban explorAR
//
//  Created by Christopher Wainwright on 11/02/2019.
//  Copyright © 2019 Christopher Wainwright. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, GMSMapViewDelegate {
    
    // variables used for keeping timer and score info
    var timer: Timer?
    var seconds: Int?
    var score: Int?
    
    // declare buttons and views
    var pauseBtn: UIButton?
    var timerView: UIImageView?
    var scoreView: UIImageView?
    var timerLbl: UILabel?
    var scoreLbl: UILabel?
    
    var nicknameTxt: UITextField?
    
    // variable for checking if first time view loaded
    var first: Bool?
    
    // array storing info for all markers on map
    var allMarkers = [customMarker]()
    
    // variable for retaining id of treasure hunt being played
    var treasureHuntID: String?
    
    // variables for location and map info
    var locationManager = CLLocationManager()
    var userMarker = GMSMarker()
    let userIcon = UIImage(named: "userIcon")
    var selectedMarker: String?
    var userLocation: CLLocation?
    var mapView: GMSMapView!
    var zoom: Float = 18.0
    
    // stores abjects and objects collected
    var allObjects = [object]()
    var usedObjects = [object]()
    
    var profanities = [String]()
    
    // create outlets for ui elements
    
    @IBOutlet var hudView: UIView!
    
    @IBOutlet var pauseMenuView: UIView!
    
    @IBOutlet weak var pauseScoreLbl: UILabel!
    
    @IBOutlet var enterScoreView: UIView!
    
    @IBOutlet weak var completeScoreLbl: UILabel!
    
    
    @IBOutlet weak var resumeBtn: UIButton!
    
    @IBOutlet weak var quitBtn: UIButton!
    
    @IBOutlet weak var submitBtn: UIButton!
    
    @IBOutlet weak var declineBtn: UIButton!
    
    
    // function to handle resume being clicked
    @IBAction func resumeClicked(_ sender: Any) {
        UIView.transition(with: self.view, duration: 0.2, options: [.transitionCrossDissolve], animations: { self.pauseMenuView.removeFromSuperview() }, completion: nil)
    }
    
    // function to handle quit being clicked
    @IBAction func quitClicked(_ sender: Any) {
        endGame()
    }
    
    // function to handle decline being clicked
    @IBAction func declineClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // function to handle submit being clicked
    @IBAction func submitClicked(_ sender: Any) {
        createAlert(false)
    }
    
    // function to handle pause being clicked
    @objc func pauseBtnClicked(_ : UIButton) {
        UIView.transition(with: self.view, duration: 0.2, options: [.transitionCrossDissolve], animations: { self.view.addSubview(self.pauseMenuView) }, completion: nil)
        pauseMenuView.center = self.view.center
        resumeBtn.setTitleColor(.darkGray, for: .normal)
        quitBtn.setTitleColor(.darkGray, for: .normal)
    }


    // function to prepare for new view being displayed
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapToCamera" {
            let arViewController = segue.destination as! ARViewController
            arViewController.label = selectedMarker
            arViewController.treasureHuntID = treasureHuntID!
        }
    }
    
    // function to handle user tapping a marker on the map
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        // check if the marker is an object (custom marker) or user icon
        if marker is customMarker {
            // selected the marker that has been tapped
            let objectMarker = marker as! customMarker
            for marker in allMarkers {
                print("CHECKING")
                if marker.position.latitude == objectMarker.position.latitude && marker.position.longitude == objectMarker.position.longitude {
                    // check if the distance between marker and user is within boundary distance
                    if checkDistance(user: userLocation!, marker: marker) {
                        //set object as collected and launch ar view
                        marker.collected = true
                        print("COLLECTED")
                        selectedMarker = objectMarker.label
                        performSegue(withIdentifier: "mapToCamera", sender: self)
                    } else {
                        // display move closer message for 1 second
                        UIView.transition(with: self.view, duration: 0.2, options: [.transitionCrossDissolve], animations: { self.view.addSubview(self.hudView) }, completion: nil)

                        let wait: Double = 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                            UIView.transition(with: self.view, duration: 0.2, options: [.transitionCrossDissolve], animations: { self.hudView.removeFromSuperview() }, completion: nil)
                        }
                    }
                }
            }
        }
        return true
    }
    
    // function to handle ending of game
    func endGame() {
        
        // destroy timer
        timer?.invalidate()
        timer = Timer()
        
        // disable pause button
        pauseBtn?.isUserInteractionEnabled = false
        
        // show enter score overlay and remove pause overlay
        UIView.transition(with: self.view, duration: 0.2, options: [.transitionCrossDissolve], animations: { self.pauseMenuView.removeFromSuperview() }, completion: nil)
        
        UIView.transition(with: self.view, duration: 0.2, options: [.transitionCrossDissolve], animations: { self.view.addSubview(self.enterScoreView) }, completion: nil)
        
        enterScoreView.center = self.view.center
        
        submitBtn.setTitleColor(.darkGray, for: .normal)
        declineBtn.setTitleColor(.darkGray, for: .normal)
    }
    
    // function to submit score to database, can be expanded to add profanities check
    func submitScore(alert: UIAlertAction) {
        submitScoreToDB()
    }
    
    func nicknameTxt(textField: UITextField) {
        nicknameTxt = textField
        nicknameTxt?.placeholder = "Enter Nickname"
    }
    
    // function for creating score submission alert
    func createAlert(_ retry: Bool) {
        // create basic alert wiyh text field and buttons
        let subAlert = UIAlertController(title: "Submit Score", message: "Enter nickname", preferredStyle: .alert)
        subAlert.addTextField(configurationHandler: nicknameTxt)
        let submit = UIAlertAction(title: "Submit", style: .default, handler: self.submitScore)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        subAlert.addAction(submit)
        subAlert.addAction(cancel)
        /*
         can be used for profanities check in future
        if retry {
            nicknameTxt?.placeholder = "Name not allowed"
        }
        */
        
        self.present(subAlert, animated: true, completion: nil)
    }
    
    // create pause button
    func drawButton() {
        let buttonImage = UIImage(named: "pauseBtn")
        pauseBtn = UIButton.init(type: .custom)
        let height = Int(UIScreen.main.bounds.height) - 70
        pauseBtn?.frame = CGRect(x: 7, y: height, width: 150, height: 50)
        pauseBtn?.setTitle("Pause", for: .normal)
        pauseBtn?.setTitleColor(.darkGray, for: .normal)
        pauseBtn?.titleLabel?.font = UIFont(name: "Bit-Darling10-sRB", size: 17.0)
        pauseBtn?.setBackgroundImage(buttonImage, for: .normal)
        pauseBtn?.addTarget(self, action: #selector(pauseBtnClicked(_ :)), for: .touchUpInside)
    }
    
    // create timer appearance
    func drawTimer() {
        let timerImage = UIImage(named: "pauseBtn")
        let width = Int(UIScreen.main.bounds.width) - 155
        timerLbl = UILabel.init()
        timerLbl?.text = "00 : 00"
        timerLbl?.textColor = .darkGray
        timerLbl?.font = UIFont(name: "Bit-Darling10-sRB", size: 17.0)
        timerLbl?.frame = CGRect(x: width, y: 50, width: 150, height: 50)
        timerLbl?.textAlignment = .center
        
        timerView = UIImageView.init(image: timerImage)
        timerView?.contentMode = UIView.ContentMode.scaleAspectFill
        timerView?.frame = CGRect(x: width, y: 50, width: 150, height: 50)
    }
    
    // function to update the timer text
    // formats the time into minutes and seconds from only seconds
    @objc func updateTimer() {
        seconds! += 1
        let mins = seconds! / 60
        let secs = seconds! % 60
        let displayMins = String(format: "%02d", mins)
        let displaySecs = String(format: "%02d", secs)
        timerLbl?.text = displayMins + " : " + displaySecs
    }
    
    // function to create score appearance
    func drawScore () {
        let scoreImage = UIImage(named: "pauseBtn")
        
        scoreLbl = UILabel.init()
        scoreLbl?.textColor = .darkGray
        scoreLbl?.text = "Score: 0"
        scoreLbl?.font = UIFont(name: "Bit-Darling10-sRB", size: 17.0)
        scoreLbl?.frame = CGRect(x: 7, y: 50, width: 150, height: 50)
        scoreLbl?.textAlignment = .center
        
        scoreView = UIImageView.init(image: scoreImage)
        scoreView?.contentMode = UIView.ContentMode.scaleAspectFill
        scoreView?.frame = CGRect(x: 7, y: 50, width: 150, height: 50)
    }
    
    // function to check distance between a user and a marker
    func checkDistance(user: CLLocation,  marker: customMarker) -> (Bool) {
        let objectLat = Double(marker.position.latitude)
        let objectLong = Double(marker.position.longitude)
        let objectLocation = CLLocation(latitude: objectLat, longitude: objectLong)
        
        let distanceInMeters = objectLocation.distance(from: user)
        if distanceInMeters <= 20 {
            return true
        } else {
            return false
        }
    }
    
    // function to handle the view apperaning on screen
    override func viewDidAppear(_ animated: Bool) {
        var numCollected = 0
        
        // check to see if first time view has appeared
        // if not the first time increase score as object collected and remove collected object markers
        if first != nil && !first! {
            score! += 10
            for marker in allMarkers {
                if marker.collected! {
                    numCollected += 1
                    marker.map = nil
                    print("MARKER REMOVED!!")
                }
            }
        }
        
        // update score label and score on pause menu and end game menu
        scoreLbl?.text = "Score: " + String(score!)
        pauseScoreLbl.text = "Score: " + String(score!)
        completeScoreLbl.text = "Score: " + String(score!)
        
        // check if all markers collected to end game
        if !first!  && numCollected == allMarkers.count {
            endGame()
        }
        
        // after first time view appears set first to false for first time appearance check
        first = false
    }
    
    // function to handle the view loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // edit heads up display appearance
        hudView.layer.cornerRadius = 30
        hudView.center = self.view.center
    
        // set first variable to true used to check for first time appearance of view
        first = true
        
        // initialise score and time
        seconds = 0
        score = 0
        pauseScoreLbl.text = "Score: " + String(score!)
        completeScoreLbl.text = "Score: " + String(score!)

        // add ui elements
        drawButton()
        drawTimer()
        drawScore()
        
        // start timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        // set up location manager to handle user location
        locationManager = CLLocationManager()
        locationManager.distanceFilter = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        locationManager.delegate = self
        
        // initialise map view setting area viewed to random initial location to prevent errors
        let camera = GMSCameraPosition.camera(withLatitude: 53.406566, longitude: -2.966531, zoom: zoom)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = self
        mapView.settings.scrollGestures = false
        mapView.settings.zoomGestures = true
        mapView.isIndoorEnabled = false
        mapView.isMyLocationEnabled = false
        view.addSubview(mapView)
        mapView.isHidden = true
        mapView.setMinZoom(16, maxZoom: 20)
        userMarker.icon = userIcon
        userMarker.map = mapView

        // set the theming of the map using included json file
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        self.view = mapView
        
        // store url for php web service with json output of objects database table
        let urlString = "https://urban-explorar-php.000webhostapp.com/object-positions.php"
        guard let url = URL(string: urlString) else {return}
        
        // create url session for reading json output
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!)
            } else {
                if let urlContent = data {
                    do {
                        
                        // use json decoder to retrieve the information in the file as type treasureHunt
                        let data = Data(urlContent)
                        let decoder = JSONDecoder()
                        self.allObjects = try decoder.decode([object].self, from: data)
                        
                        // print statements for testing
                        print(self.allObjects[0].object_id)
                        print(self.allObjects[1].object_id)
                        
                        // check if object is from selected treasure hunt then add to array of relevant objects
                        for object in self.allObjects {
                            if object.treasure_hunt_id == self.treasureHuntID {
                                self.usedObjects.append(object)
                            }
                        }
                        
                        // wait for background task to be complete before running following lines
                        DispatchQueue.main.async {
                            // for each object in array, create custom marker using coordinates from database
                            // set marker label from database, used for deciding which image to display in AR
                            // set marker image to image from assets called "object"
                            // add marker to map
                            for object in self.usedObjects {
                                let marker = customMarker()
                                marker.position = CLLocationCoordinate2D(latitude: Double(object.latitude)!, longitude: Double(object.longitude)!)
                                
                                let treasureChest = UIImage(named: "object")
                                
                                marker.label = object.label
                                
                                marker.icon = treasureChest
                                
                                marker.collected = false
                                
                                marker.map = self.mapView
                                
                                self.allMarkers.append(marker)
                            }
                        }
                        
                    } catch {
                        print("error")
                    }
                }
            }
        }
        task.resume()
        
        // add other ui elements to view
        mapView.addSubview(pauseBtn!)
        mapView.addSubview(timerView!)
        mapView.addSubview(timerLbl!)
        print("1")
        mapView.addSubview(scoreView!)
        print("1.1")
        mapView.addSubview(scoreLbl!)
        mapView.bringSubviewToFront(pauseBtn!)
        mapView.bringSubviewToFront(timerView!)
        mapView.bringSubviewToFront(timerLbl!)
        print("2")
        mapView.bringSubviewToFront(scoreView!)
        print("2.2")
        mapView.bringSubviewToFront(scoreLbl!)
        
    }
    
    // score submission function
    func submitScoreToDB() {
        
        // set url of php web service for adding records to database
        let urlString = "https://urban-explorar-php.000webhostapp.com/submit.php"
        guard let url = URL(string: urlString) else {return}
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // format text to what is required in php script for query
        var dataString = "nickname=\(nicknameTxt!.text!)"
        dataString = dataString + "&time=\(String(seconds!))"
        dataString = dataString + "&score=\(score!)"
        dataString = dataString + "&treasure_hunt_id=\(treasureHuntID!)"
        
        // format string using utf8
        let uploadData = dataString.data(using: .utf8) // convert to utf8 string
        
        do {
            // create task to upload information to url
            let uploadJob = URLSession.shared.uploadTask(with: request, from: uploadData) {
                data, response, error in
                
                // check for no internet connection and display error message
                if error != nil {
                    DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Unable to submit score.", message: "Make sure you are connected to the internet and try again.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            uploadJob.resume()
        }
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

// extension of map view class to handle user loacation
extension MapViewController: CLLocationManagerDelegate {
    
    // changes map orientation when device orientation changes
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.animate(toBearing: newHeading.trueHeading)
    }
    
    // updates location to last known location and adjusts camera to center the user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation? = locations.last
        userLocation = location!
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: zoom)
        
        let userPosition = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        
        // only show map if user location is known
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
            userMarker.position = userPosition
        } else {
            userMarker.position = userPosition
            mapView.animate(to: camera)
        }
        
        
        
    }
}

// class to extend marker class
class customMarker: GMSMarker {
    var label: String? // used to store information about image to be displayer in AR
    var collected: Bool? // used to store whether object has been collected
}
