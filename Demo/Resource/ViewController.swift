//
//  ViewController.swift
//  Demo
//
//  Created by Luis on 07/03/2024.
//

import UIKit
import ARKit
import ARCL
import CoreLocation

class ViewController: UIViewController {
    
    var sceneLocationView = SceneLocationView()
    
    @IBOutlet weak var arSceneView: ARSCNView!
    
    var currentLocation: CLLocation? {
        return sceneLocationView.sceneLocationManager.currentLocation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setupAR() {
        arSceneView.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        arSceneView.session.run(configuration)
    }
}

extension ViewController: ARSCNViewDelegate {}
