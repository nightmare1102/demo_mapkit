//
//  UIViewExtension.swift
//  Demo
//
//  Created by Luis on 12/03/2024.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

extension UIViewController {

    typealias AlertOKCallback = (UIAlertAction) -> Void

    /// Shows an alert with a title of "Error" and an "OK" button that dismisses
    /// the alert.
    ///
    /// - Parameter message: The message to show in the alert.
    func showErrorAlert(message: String, completion handler: AlertOKCallback? = nil) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))

        present(alertVC, animated: true)
    }

}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { (context) in
            layer.render(in: context.cgContext)
        }
        return image
    }
}

extension CLLocation {

    convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, altitude: CLLocationDistance) {
        self.init(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: altitude)
    }

}

extension MKMapView {
    
    private var MERCATOR_OFFSET: Double {
        get {
            return 268435456
        }
    }
    private var MERCATOR_RADIUS: Double {
        get {
            return 85445659.44705395
        }
    }
    private var MAX_ZOOM_LEVEL: Double {
        get {
            return 19
        }
    }
    
    // MARK: -  Private functions
    private func longitudeToPixelSpaceX (longitude: Double) -> Double {
        return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * Double.pi / 180.0)
    }
    
    private func latitudeToPixelSpaceY (latitude: Double) -> Double {
        
        let a = 1 + sinf(Float(latitude * Double.pi) / 180.0)
        let b = 1.0 - sinf(Float(latitude * Double.pi / 180.0)) / 2.0
        
        return round(MERCATOR_OFFSET - MERCATOR_RADIUS * Double(logf(a / b)))
    }
    
    private func pixelSpaceXToLongitude (pixelX: Double) -> Double {
        return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / Double.pi
    }
    
    private func pixelSpaceYToLatitude (pixelY: Double) -> Double {
        return (Double.pi / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / Double.pi
    }
    
    private func coordinateSpanWithMapView(mapView: MKMapView, centerCoordinate: CLLocationCoordinate2D, andZoomLevel zoomLevel:Int) -> MKCoordinateSpan {
        
        // convert center coordiate to pixel space
        let centerPixelX = self.longitudeToPixelSpaceX(longitude: centerCoordinate.longitude)
        let centerPixelY = self.latitudeToPixelSpaceY(latitude: centerCoordinate.latitude)
        
        // determine the scale value from the zoom level
        let zoomExponent = 20 - zoomLevel
        let zoomScale = CGFloat(pow(Double(2), Double(zoomExponent)))
        
        // scale the map’s size in pixel space
        let mapSizeInPixels = mapView.bounds.size
        let scaledMapWidth = mapSizeInPixels.width * zoomScale
        let scaledMapHeight = mapSizeInPixels.height * zoomScale
        
        // figure out the position of the top-left pixel
        let topLeftPixelX = CGFloat(centerPixelX) - (scaledMapWidth / 2)
        let topLeftPixelY = CGFloat(centerPixelY) - (scaledMapHeight / 2)
        
        // find delta between left and right longitudes
        let minLng: CLLocationDegrees = self.pixelSpaceXToLongitude(pixelX: Double(topLeftPixelX))
        let maxLng: CLLocationDegrees = self.pixelSpaceXToLongitude(pixelX: Double(topLeftPixelX + scaledMapWidth))
        let longitudeDelta: CLLocationDegrees = maxLng - minLng
        
        // find delta between top and bottom latitudes
        let minLat: CLLocationDegrees = self.pixelSpaceYToLatitude(pixelY: Double(topLeftPixelY))
        let maxLat: CLLocationDegrees = self.pixelSpaceYToLatitude(pixelY: Double(topLeftPixelY + scaledMapHeight))
        let latitudeDelta: CLLocationDegrees = -1 * (maxLat - minLat)
        
        // create and return the lat/lng span
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        return span
    }
    
    // MARK: - Public Functions
    func setCenterCoordinate(centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool) {
        let zoom = min(zoomLevel, 28)
        let span = self.coordinateSpanWithMapView(mapView: self, centerCoordinate:centerCoordinate, andZoomLevel:zoom)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        self.setRegion(region, animated:animated)
    }
    
    func getZoom() -> Double {
        let longitudeDelta = self.region.span.longitudeDelta
        let mapWidthInPixels = self.bounds.size.width*2
        let zoomScale = longitudeDelta * MERCATOR_RADIUS * Double.pi / Double((180.0 * mapWidthInPixels))
        var zoomer = MAX_ZOOM_LEVEL - log2(zoomScale)
        if zoomer < 0 {
            zoomer = 0
        }
        zoomer = round(zoomer)
        return zoomer
    }
}
