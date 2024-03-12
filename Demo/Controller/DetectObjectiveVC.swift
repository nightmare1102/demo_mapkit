//
//  DetectObjectiveVC.swift
//  Demo
//
//  Created by Luis on 08/03/2024.
//

import ARCL
import ARKit
import Cartography
import CoreLocation
import UIKit
import MapKit

class DetectObjectiveVC: UIViewController {
    
    @IBOutlet weak var tfSearch: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var sceneLocationView: SceneLocationView!
    let locationManager = CLLocationManager()
    let searchCompleter = MKLocalSearchCompleter()
    var currentLocation: CLLocation?
    var pois: [MKMapItem] = []
    var isInit = true
    var isZoom = false
    var centerLocation: MKUserLocation?
    var isShowMap = true {
        didSet {
            mapView.isHidden = !isShowMap
            sceneLocationView.isHidden = isShowMap
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        guard ARConfiguration.isSupported else {
            return showErrorAlert(message: "Your device does not support ARKit") { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.sceneLocationView.run()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneLocationView.pause()
    }
    
    func addPins() {
        sceneLocationView.removeAllNodes()
        guard let currentLocation = currentLocation  else {
            return
        }
        for n in 0..<pois.count {
            let item = pois[n]
            self.mapView.addAnnotation(CustomAnnotation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude, title: item.name, isZoom: isZoom))
            let poiView = UIView()
            let lb = UILabel(frame: CGRect(x: 10, y: 0, width: 150, height: 45))
            lb.text = item.name ?? ""
            lb.textColor = .black
            lb.numberOfLines = 3
            let alpha = Double(pois.count - n)/Double(pois.count)
            var fontSize = CGFloat(Int(1 / alpha) * 2)
            if fontSize > 30 {
                fontSize = 30
            }
            if fontSize < 8 {
                fontSize = 8
            }
            print("font \(fontSize)")
            lb.font = UIFont.systemFont(ofSize: fontSize)
            lb.textAlignment = .center
            lb.sizeToFit()
            poiView.frame.size = CGSize(width: 160, height: lb.frame.size.height)
            poiView.backgroundColor = UIColor(white: 1, alpha: 1)
            poiView.addSubview(lb)
            print("\(item.name ?? "") \(item.placemark.coordinate)")
            
            poiView.layer.cornerRadius = 8
            poiView.layer.masksToBounds = true
            poiView.layer.borderWidth = 0.3
            poiView.layer.borderColor = UIColor.white.cgColor
            let location = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude, altitude: currentLocation.altitude + Double(n * 100))
            let node = LocationAnnotationNode(location: location, image: poiView.asImage())
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
        }
    }
    
    func searchPOI() {
        guard let centerLocation = centerLocation else {return}
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = tfSearch.text ?? ""
        searchRequest.resultTypes = .pointOfInterest
        searchRequest.region = MKCoordinateRegion(center: centerLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        let localSearch = MKLocalSearch(request: searchRequest)
        localSearch.start { (response, error) in
                guard let response = response, error == nil else {
                    print("Error searching for POI: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
            self.mapView.removeAnnotations(self.mapView.annotations)
                self.pois = response.mapItems
                self.pois = self.pois.sorted(by: { self.getDistance(location: CLLocation(latitude: $0.placemark.coordinate.latitude, longitude: $0.placemark.coordinate.longitude)) > self.getDistance(location: CLLocation(latitude: $1.placemark.coordinate.latitude, longitude: $1.placemark.coordinate.longitude))})
                self.addPins()
        }
    }
    
    func isCoordinateVisibleOnMap(coordinate: CLLocationCoordinate2D) -> Bool {
        let visibleMapRect = mapView.visibleMapRect
        let point = MKMapPoint(coordinate)
        return visibleMapRect.contains(point)
    }
    
    @objc func searchData() {
        searchPOI()
    }
    
    @IBAction func actionChangeView(_ sender: UIButton) {
        isShowMap = !isShowMap
    }
    
    @IBAction func tfEdittingChanged(_ sender: UITextField) {
        perform(#selector(searchData), with: "searchText", afterDelay: 0.6)
    }
}

extension DetectObjectiveVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is CustomAnnotation else { return nil }
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        guard let customAnnotation = annotation as? CustomAnnotation else { return nil }
        annotationView = CustomAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier, title: customAnnotation.title)
        annotationView!.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if isInit {
            isInit = false
            mapView.setCenterCoordinate(centerCoordinate: userLocation.coordinate, zoomLevel: 10, animated: true)
            centerLocation = userLocation
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        isZoom = mapView.getZoom() > 10
        guard let centerLocation = centerLocation else {return}
        if !isCoordinateVisibleOnMap(coordinate: centerLocation.coordinate) || pois.count == 0 {
            searchPOI()
        }
    }
}
extension DetectObjectiveVC: CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
        }
    }
}

extension DetectObjectiveVC: ARSCNViewDelegate {
    
}

extension DetectObjectiveVC {
    func getDistance(location: CLLocation) -> Double {
        guard let currentLocation = currentLocation else { return 0}
        let distance = (currentLocation.distance(from: location) / 1000)
        return distance
    }
}

