//
//  CustomAnnotation.swift
//  Demo
//
//  Created by Luis on 09/03/2024.
//

import UIKit
import MapKit
import SwifterSwift

class CustomAnnotation: MKPointAnnotation {
    var isZoom = false
    
    init(latitude: Double, longitude: Double, title: String?, isZoom: Bool) {
        super.init()
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.coordinate = coordinate
        self.title = title
        self.isZoom = isZoom
    }
}

class CustomAnnotationView: MKAnnotationView {
    
    var title: String?
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.frame.size.width = 100
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.black
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 2
        label.numberOfLines = 0
        label.baselineAdjustment = .alignCenters
        return label
    }()
    
    public override var annotation: MKAnnotation? {
        didSet {
            updateAnnotationView()
        }
    }
    
    public convenience init(annotation: MKAnnotation?, reuseIdentifier: String?, title: String?){
        self.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.title = title
        self.setupView()
    }

    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
}

extension CustomAnnotationView {
    func setupView() {
        addSubview(nameLabel)
        nameLabel.anchorCenterXToSuperview()
        nameLabel.anchor(top: topAnchor, topConstant: 9)
        image = UIImage(named: "claim_selected")
    }
    
    func updateAnnotationView() {
        if let annotation = annotation as? CustomAnnotation {
            if annotation.isZoom {
                nameLabel.text = title
            } else {
                nameLabel.text = ""
            }
            setNeedsLayout()
        }
    }
}
