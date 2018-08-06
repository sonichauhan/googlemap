//
//  ViewController.swift
//  googlemapDemo
//
//  Created by Rajesh Vishnani on 23/07/18.
//  Copyright © 2018 Rajesh Vishnani. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import GooglePlaces
import GooglePlacesSearchController
import MJSnackBar
class ViewController: UIViewController, UINavigationBarDelegate, GMSAutocompleteFetcherDelegate, UISearchControllerDelegate, CLLocationManagerDelegate,UISearchResultsUpdating,GMSMapViewDelegate
{

    
   
    var isPressProperty = false
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var BGVIEW: UIView!
    @IBOutlet var googleMapsContainerView: UIView!
    var resultsArray = [String]()
    var googleMapsView:GMSMapView!
    var gmsFetcher: GMSAutocompleteFetcher!
    var locationManager = CLLocationManager()
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var marker = GMSMarker()
    var sourcelat = 23.0225
    var sourcelong = 75.5214
    var rectangle = GMSPolyline()
    var snackerbar : MJSnackBar!
    var delegate : GooglePlacesAutocompleteViewControllerDelegate!
    var selectedPlace: GMSPlace!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        let camera = GMSCameraPosition.camera(withLatitude: sourcelat,longitude: sourcelong, zoom: 12.0)
        let mapView = GMSMapView.map(withFrame: BGVIEW.frame, camera: camera)
        
        if selectedPlace != nil {
            let marker = GMSMarker(position: (self.selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
        }

        let origin = "\(sourcelat),\(sourcelong)"
        let destination = "\(selectedPlace?.coordinate.latitude),\(selectedPlace?.coordinate.longitude)"
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)")
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if(error != nil){
                print("error")
            }else{
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                    if json["status"] as! String == "OK"
                    {
                        print(json)
                        let routes = json["routes"] as! NSArray
                        print(routes)
                        let arrLegs = (routes[0] as! NSDictionary).object(forKey: "legs")as! NSArray
                        
                        let arrStep = arrLegs[0] as! NSDictionary
                        
                        print("arrStep",arrStep)
                        let Dicdistance = arrStep["distance"] as! NSDictionary
                        let distance = Dicdistance["text"]as! String
                        print(distance,"distance1")
                        let Dicduration = arrStep["duration"] as! NSDictionary
                        print(Dicduration,"Dicduration")
                        let duration = Dicdistance["text"]as! String
//                        print("(distance2)",duration)
                        let msg = String(format: "Distance: \(distance) & Duration :\(duration)")
                        print(msg)
                        let data1 = MJSnackBarData(withIdentifier: 0, message: msg, andActionMessage: "", objectSaved: nil)
                        print(data1)
                        self.snackerbar.show(data: data1, onView: self.BGVIEW)
                        //                        let Dicdistance  = arrLegs["distance"] as! String
                        OperationQueue.main.addOperation({
//                            for route in routes
//                            {
                                let routes = json["routes"] as! NSArray
                                let dic = routes[0] as! NSDictionary
                                let dic1 = dic["overview_polyline"]as! NSDictionary
                                let points = dic1["points"]as? String
                                let path = GMSPath.init(fromEncodedPath: points!)
                                self.rectangle.map = nil
                                self.rectangle = GMSPolyline(path: path)
                                self.rectangle.strokeColor = .blue
                                self.rectangle.strokeWidth = 4.0
                                self.rectangle.map = mapView//Your GMSMapview
//                            }
                        })
                    }
                }catch let error as NSError{
                    print(error)
                }
            }
        }).resume()
        let position = CLLocationCoordinate2DMake(sourcelat, sourcelong)
        self.marker = GMSMarker(position: position)
        let pincolor = UIColor.green
        self.marker.icon = GMSMarker.markerImage(with: pincolor)
        self.marker.map = mapView
        mapView.isMyLocationEnabled = true
        self.BGVIEW = mapView
        locationManager.distanceFilter = 100
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // GOOGLE MAPS SDK: COMPASS
        mapView.settings.compassButton = true
        
        // GOOGLE MAPS SDK: USER'S LOCATION
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        self.snackerbar = MJSnackBar(onView: self.BGVIEW)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        self.googleMapsView = GMSMapView (frame: self.googleMapsContainerView.frame)
        self.googleMapsView.settings.compassButton = true
        self.googleMapsView.isMyLocationEnabled = true
        self.googleMapsView.settings.myLocationButton = true
        self.googleMapsContainerView.addSubview(self.googleMapsView)
        
        gmsFetcher = GMSAutocompleteFetcher()
        gmsFetcher.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let userLocation = locations.last
        let center = CLLocationCoordinate2D(latitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude)
        
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude, zoom: 15);
        self.googleMapsView.camera = camera
        self.googleMapsView.isMyLocationEnabled = true
        
        let marker = GMSMarker(position: center)
        let position = userLocation?.coordinate
        self.marker = GMSMarker(position: position!)
        print("Latitude :- \(userLocation!.coordinate.latitude)")
        print("Longitude :-\(userLocation!.coordinate.longitude)")
        marker.map = self.googleMapsView
        
        marker.title = "Current Location"
        locationManager.stopUpdatingLocation()
    }
    @IBAction func onClickButton(_ sender: UIButton) {
        if !isPressProperty == true
        {
            isPressProperty = true
            resultsViewController = GMSAutocompleteResultsViewController()
            resultsViewController?.delegate = self
            searchController = UISearchController(searchResultsController: resultsViewController)
            searchController?.searchResultsUpdater = resultsViewController
            searchController?.searchBar.frame = (CGRect(x: 0, y: 0, width: 250.0, height: 44.0))
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: (searchController?.searchBar)!)
            definesPresentationContext = true
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.modalPresentationStyle = .popover
            
        }
        else{
            isPressProperty = false
            searchController?.searchResultsUpdater = self
            searchController?.dimsBackgroundDuringPresentation = false
            searchController?.searchBar.sizeToFit()
            searchController?.hidesNavigationBarDuringPresentation = true
            
        }
        
    }
    func updateSearchResults(for searchController: UISearchController) {
        print("hhh")
        
    }
    
    func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
        print("hhh")
    }
    
    func didFailAutocompleteWithError(_ error: Error) {
        print("hhh")
        
    }
}
// Handle the user's selection.
extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
    
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // Print place info to the console.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        
        // TODO: Add code to get address components from the selected place.
        
        // Close the autocomplete widget.
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
