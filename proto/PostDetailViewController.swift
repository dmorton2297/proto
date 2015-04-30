//
//  PostDetailViewController.swift
//  proto
//
//  Created by Dan Morton on 4/27/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
class PostDetailViewController: UIViewController {

    var location : CLLocation! //will be populated upon method call
    @IBOutlet weak var mapView: MKMapView! //map view connection from storyboard
    
    override func viewDidLoad()
    {
        var center = location.coordinate
        var span = MKCoordinateSpanMake(0.01, 0.01)
        var region = MKCoordinateRegionMake(center, span)
        
        mapView.setRegion(region, animated: true)
        
        let anno = MKPointAnnotation()
        anno.coordinate = location.coordinate
        
        mapView.addAnnotation(anno)
    }
    
    
    
}
