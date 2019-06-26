//
//  LeaderboardViewController.swift
//  urban explorAR
//
//  Created by Christopher Wainwright on 18/03/2019.
//  Copyright © 2019 Christopher Wainwright. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController {
    
    // variable for array to be passed to from home screen
    var localTreasureHunts = [treasureHunt]()
    
    // variables to store all scores and scores of selected treasure hunt
    var allScores = [score]()
    var selectedScores = [score]()
    
    var selectedTreasureHunt: String = "0"
    
    // outlets for text field and table view
    @IBOutlet weak var treasureHuntText: UITextField!
    @IBOutlet weak var scoreTable: UITableView!
    
    // when treasure hunt textbox begins editing set the selected treasure hunt to the first in the list
    @IBAction func treasureHuntTextDidBeginEditing(_ sender: Any) {
        if localTreasureHunts.count > 0 {
            treasureHuntText.text = localTreasureHunts[0].name
            selectedTreasureHunt = localTreasureHunts[0].treasure_hunt_id
        }
    }
    
    // return to home when back button clicked
    @IBAction func backBtnClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // function to initialise drop down
    func initPicker() {
        
        // create picker view
        let picker = UIPickerView()
        picker.delegate = self
        
        // set input to tet box as picker view
        treasureHuntText.inputView = picker
        
        // add select button to picker view
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let select = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(self.treasureHuntTextDidEndEditing))
        toolbar.setItems([select], animated: true)
        toolbar.isUserInteractionEnabled = true
        treasureHuntText.inputAccessoryView = toolbar
        
    }
    
    // when text box finishes editing
    @objc func treasureHuntTextDidEndEditing() {
        
        // remove score from selected scores array
        treasureHuntText.resignFirstResponder()
        selectedScores.removeAll()
        
        // add scores to selected scores array if they have the same treasure hunt id as selected treasure hunt
        for score in allScores {
            if score.treasure_hunt_id == selectedTreasureHunt {
                selectedScores.append(score)
            }
        }
        
        // sort scores by score first and then time
        selectedScores = selectedScores.sorted {
            if $0.score != $1.score {
                return $0.score > $1.score
            } else {
                return $0.time < $1.time
            }
        }
        
        // repopulate score table
        scoreTable.reloadData()
    }
    
    // handles when the view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initPicker()
        
        // url for php web service with json output of table with scores
        let urlString = "https://urban-explorar-php.000webhostapp.com/scores.php"
        guard let url = URL(string: urlString) else {return}
        
        // create url session to read data from url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!)
            } else {
                if let urlContent = data {
                    do {
                        // use json decoder to retrieve the information in the file as type treasureHunt
                        let data = Data(urlContent)
                        let decoder = JSONDecoder()
                        self.allScores = try decoder.decode([score].self, from: data)
                    } catch {
                        print("error")
                    }
                }
            }
        }
        task.resume()

        // Do any additional setup after loading the view.
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

// extend the leader board class with methods for table view
extension LeaderboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    // set number of rows in table to number of scores for selected treasure hunt
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedScores.count
    }
    
    // function to display score in cell at row i
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create cell
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "scoreCell")
        cell.textLabel?.text = selectedScores[indexPath.row].nickname
        
        // format time into mm:ss then display
        let seconds = Int(selectedScores[indexPath.row].time)
        let mins = seconds! / 60
        let secs = seconds! % 60
        let displayMins = String(format: "%02d", mins)
        let displaySecs = String(format: "%02d", secs)
        let displayTime = displayMins + " : " + displaySecs
        cell.detailTextLabel?.text = "Score: " + selectedScores[indexPath.row].score + "       Time: " + displayTime
        cell.textLabel?.font = UIFont(name: "Bit-Darling10-sRB", size: 17.0)
        cell.detailTextLabel?.font = UIFont(name: "Bit-Darling10-sRB", size: 14.0)
        cell.backgroundColor = .clear
        return cell
    }
    
    
}

// extension of leader board class for picker view
extension LeaderboardViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
        print(selectedTreasureHunt)
    }
    
}
