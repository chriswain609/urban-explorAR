//
//  ViewController.swift
//  urban explorAR
//
//  Created by Christopher Wainwright on 06/02/2019.
//  Copyright © 2019 Christopher Wainwright. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    // initialise variables and constants
    var locationManager = CLLocationManager()
    
    var firstLocation = true
    
    var userLocation: CLLocation?
    
    var treasureHunts = [treasureHunt]()
    var localTreasureHunts = [treasureHunt]()
    var selectedTreasureHunt: String = "0"
    
    // outlet for text field
    @IBOutlet weak var treasureHuntText: UITextField!
    
    // when treasure hunt textbox begins editing set the selected treasure hunt to the first in the list
    @IBAction func treasureHuntTextDidBeginEditing(_ sender: Any) {
        if localTreasureHunts.count > 0 {
            treasureHuntText.text = localTreasureHunts[0].name
            selectedTreasureHunt = localTreasureHunts[0].treasure_hunt_id
        }
    }
    
    // outlet for play button
    @IBOutlet weak var playBtn: UIButton!
    
    // when play button is clicked, if treasure hunt selected go to map, else present message
    @IBAction func playBtnClicked(_ sender: Any) {
        if selectedTreasureHunt != "0" {
            performSegue(withIdentifier: "homeToMap", sender: self)
        } else {
            treasureHuntText.text = "Must Select a Treasure Hunt"
        }
    }
    
    // function to set up moving to new view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if going to map, pass selected treasure hunt
        // if to leader board, pass array of nearby treasure hunts
        if segue.identifier == "homeToMap" {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.treasureHuntID = selectedTreasureHunt // place holder
        } else if segue.identifier == "homeToScores" {
            let leaderboardViewController = segue.destination as! LeaderboardViewController
            leaderboardViewController.localTreasureHunts = localTreasureHunts
        }
    }
    
    // function to handle dismissal of text box
    @objc func treasureHuntTextDidEndEditing() {
        treasureHuntText.resignFirstResponder()
    }
    
    // function to set up drop down
    func initPicker() {
        let picker = UIPickerView()
        picker.delegate = self
        
        // set the input of the text box to the picker
        treasureHuntText.inputView = picker
        
        // add select button to picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let select = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(self.treasureHuntTextDidEndEditing))
        toolbar.setItems([select], animated: true)
        toolbar.isUserInteractionEnabled = true
        treasureHuntText.inputAccessoryView = toolbar
    }
    
    // check for distance between user and treasure hunts is less than 1km using coordinates
    func checkDistance(user: CLLocation,  treasureHunt: treasureHunt) -> (Bool) {
        let huntLat = Double(treasureHunt.latitude)
        let huntLong = Double(treasureHunt.longitude)
        let huntLocation = CLLocation(latitude: huntLat!, longitude: huntLong!)
        
        let distanceInMeters = huntLocation.distance(from: user)
        if distanceInMeters <= 1000 {
            return true
        } else {
            return false
        }
    }

    // function to handle view loading
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        initPicker()
        
        // initialise and set up location manager for use of user location
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        // store url for php web service with json output of treasure hunt database table
        let urlString = "https://urban-explorar-php.000webhostapp.com/treasure-hunts.php"
        guard let url = URL(string: urlString) else {return}
        
        // create url session to get data from php web service
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!)
            } else {
                if let urlContent = data {
                    do {
                        // use json decoder to retrieve the information in the file as type treasureHunt
                        let data = Data(urlContent)
                        let decoder = JSONDecoder()
                        self.treasureHunts = try decoder.decode([treasureHunt].self, from: data)
                        
                        // wait for data to be retrieved in background before carrying out following lines
                        DispatchQueue.main.async {
                            // check user has enabled location otherwise error message
                            if self.userLocation == nil {
                                self.treasureHuntText.text = "Must enable Location"
                                self.treasureHuntText.isUserInteractionEnabled = false
                                self.playBtn.isUserInteractionEnabled = false
                            } else {
                                self.treasureHuntText.text = "Select Treasure Hunt"
                                self.treasureHuntText.isUserInteractionEnabled = true
                                self.playBtn.isUserInteractionEnabled = true
                                
                                // check didtance between user and treasure hunts then if nearby add to array
                                for treasureHunt in self.treasureHunts {
                                    if self.checkDistance(user: self.userLocation!, treasureHunt: treasureHunt) == true {
                                        self.localTreasureHunts.append(treasureHunt)
                                    }
                                }
                                
                                // if no treasure hunts nearby display message
                                if self.localTreasureHunts.count == 0 {
                                    self.treasureHuntText.text = "No Hunts Nearby"
                                    self.treasureHuntText.isUserInteractionEnabled = false
                                }
                            }
                        }
                    } catch {
                        print("error")
                    }
                }
            }
        }
        task.resume()
    }


}

// extension of view controller to include picker view methods
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // number of columns
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // number of rows as number of elements in array of nearby treasure hunts
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return localTreasureHunts.count
    }
    
    // set text at row i of picker to name at row i of treasure hunt array
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return localTreasureHunts[row].name
    }
    
    // when row selected, update text box and set id of selected treasure hunt
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        treasureHuntText.text = localTreasureHunts[row].name
        selectedTreasureHunt = localTreasureHunts[row].treasure_hunt_id
    }
    
}

// extension of view controller with location manager methods
extension ViewController: CLLocationManagerDelegate {
    
    // check if the location has been updated previously
    // otherwise set the user location to the last known location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if firstLocation {
            let location: CLLocation? = locations.last
            firstLocation = false
            userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
        treasureHuntText.text = "Select Treasure Hunt"
        treasureHuntText.isUserInteractionEnabled = true
        
        // check didtance between user and treasure hunts then if nearby add to array
        for treasureHunt in self.treasureHunts {
            if self.checkDistance(user: locationManager.location!, treasureHunt: treasureHunt) == true {
                self.localTreasureHunts.append(treasureHunt)
            }
        }
        
        // if no treasure hunts nearby display message
        if self.localTreasureHunts.count == 0 {
            self.treasureHuntText.text = "No Hunts Nearby"
            self.treasureHuntText.isUserInteractionEnabled = false
        } else {
            playBtn.isUserInteractionEnabled = true
        }
    }
}

