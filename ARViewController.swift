//
//  ARViewController.swift
//  augmentedRealityView
//
//  Created by Christopher Wainwright on 21/02/2019.
//  Copyright © 2019 Christopher Wainwright. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    //initialise variables and constants for data passed to this view
    var label: String?
    var treasureHuntID: String?
    
    // create lighting for AR
    let ambient = SCNLight()
    let ambientNode = SCNNode()
    
    let spot = SCNLight()
    let spotNode = SCNNode()
    
    // outlets for ui elements
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var descriptionLbl: UILabel!
    
    var backBtn: UIButton?
    
    // create back button
    func drawButton() {
        let buttonImage = UIImage(named: "pauseBtn")
        backBtn = UIButton.init(type: .custom)
        backBtn?.frame = CGRect(x: 7, y: 35, width: 150, height: 50)
        backBtn?.setTitle("Back", for: .normal)
        backBtn?.setTitleColor(.darkGray, for: .normal)
        backBtn?.titleLabel?.font = UIFont(name: "Bit-Darling10-sRB", size: 17.0)
        backBtn?.setBackgroundImage(buttonImage, for: .normal)
        backBtn?.addTarget(self, action: #selector(backBtnClicked(_ :)), for: .touchUpInside)
    }
    
    // method to return to map when back button clicked
    @objc func backBtnClicked(_ : UIButton) {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    // method to handle object being tapped using tap gesture recognizer
    @objc func objectTapped(_ sender: UITapGestureRecognizer) {
        
        // create shrinking animation
        let shrink = SCNAction.scale(to: 0, duration: 0.25)
        
        // check if image was tapped
        let image = sender.view as! SCNView
        let touch = sender.location(in: image)
        let hitTest = image.hitTest(touch, options: nil)
        
        // if touch was inside image bounds array will contain 1 element
        if hitTest != [] {
            // run shring on child node (AR image)
            sceneView.scene.rootNode.childNode(withName: label!, recursively: true)!.runAction(shrink)
            // wait for animation completion before returning to map
            let wait = 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                    node.removeFromParentNode()
                }
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    // handles view loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create gesture recognizer for user tapping the screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(objectTapped))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        drawButton()
        
        // start with hidden scene until image is loaded
        sceneView.isHidden = true
        
        // modify description overlay constraints
        descriptionLbl.layer.masksToBounds = true
        descriptionLbl.layer.cornerRadius = 20
        
        // create description to be displayed using label passed to view from map view
        var description: String?
        
        switch label {
        case "ball":
            description = "Sports Center"
        case "biology":
            description = "Biology Building"
        case "chemistry":
            description = "Chemistry Building"
        case "computer":
            description = "Computer Science Building"
        case "geography":
            description = "Geography Building"
        case "library":
            description = "Library"
        case "math":
            description = "Mathematics Building"
        case "physics":
            description = "Physics Building"
        case "plane":
            description = "Engineering Building"
        default:
            description = "University of Liverpool"
        }
        
        descriptionLbl.text = "Welcome to the " + description! + "!"
        
        // select image based on label passed from map view
        let sceneName: String = "SceneKitAssetCatalog.scnassets/" + label! + ".scn"

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false

        // Create a new scene
        let scene = SCNScene(named: sceneName)!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.addSubview(backBtn!)
        sceneView.bringSubviewToFront(backBtn!)
    }
    
    // update the spot light intensity and colour temperature based on real world light as this changes
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let lightEstimate = sceneView.session.currentFrame?.lightEstimate else {return}
        spot.intensity = lightEstimate.ambientIntensity
        spot.temperature = lightEstimate.ambientColorTemperature
    }

    // deinitialise the nodes in the scene
    deinit {
        print("deinit")
        sceneView.scene.rootNode.cleanup()
    }
    
    // handles view appearing
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal
        
        
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        // initialise lighting
        spot.type = .spot
        spot.spotInnerAngle = 45
        spot.spotOuterAngle = 45
        spot.intensity = 100
        spotNode.light = spot

        ambient.type = .ambient
        ambient.intensity = 40
        ambientNode.light = ambient
        
        // initialise rotation animation of image displayed
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 3.0)
        let repeatAction = SCNAction.repeatForever(rotate)
        sceneView.scene.rootNode.childNode(withName: label!, recursively: true)!.runAction(repeatAction)
        sceneView.scene.rootNode.addChildNode(spotNode)
        sceneView.scene.rootNode.addChildNode(ambientNode)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sceneView.isHidden = false
    }

    // MARK: - ARSCNViewDelegate

    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()

     return node
     }
     */

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
}

// extends node
extension SCNNode {
    // remove all child nodes
    func cleanup() {
        for child in childNodes {
            child.cleanup()
        }
        geometry = nil
    }
}
