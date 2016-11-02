//
//  StoreLocatorViewController.swift
//  MySumo
//
//  Created by Fekri on 5/24/16.
//  Copyright © 2016 Round Table Apps. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps


class MapViewController: UIViewController, GMSMapViewDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var menuButton: UIBarButtonItem!
    var isCheckout: Bool = false
    var screenWidth = UIScreen.mainScreen().bounds.width
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var userLocationMarkerAdded = false
    
    private var pinActiveUIImage = UIImage(named: "pinActive")
    private var pinUIImage = UIImage(named: "pin")
    
    var storeList = [ListItem]()
    
    var isBusy = false
    var markers = [GMSMarker]()
    var selctedMarkar = GMSMarker()
    var originMarker : GMSMarker?
    
    var selectedMarkerIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let listItem = ListItem()
        listItem.name = "1"
        listItem.uid = "1"
        listItem.addressRelationship = CLLocation(latitude: 112.343, longitude: 123.234)
        self.storeList.append(listItem)
        
        listItem.name = "2"
        listItem.uid = "2"
        listItem.addressRelationship = CLLocation(latitude: 113.343, longitude: 124.234)
        self.storeList.append(listItem)
        
        self.mapView.delegate = self
        self.mapView.tintColor = UIColor.blackColor()
        
        self.locationManager.delegate = self
        self.collectionView.delegate = self
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            self.locationManager.requestAlwaysAuthorization()
        }
        if CLLocationManager.authorizationStatus() == .Denied {
            let alert = UIAlertController(title: "Location", message: "We don't have the permission to get your location. Please go to your setting privacy and allow location for MySumo App.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        self.locationManager.startUpdatingLocation()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
        self.updateStoreLists()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
        
        didMoveToParentViewController(navigationController)
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            //"Back pressed"
            self.mapView.clear()
            self.mapView.removeFromSuperview()
            self.mapView = nil
        }
    }
    
    @IBAction func backButton(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }

    //Request to get stores
    func requestToGetStores(list: [ListItem]) {
        self.isBusy = true
        
        self.storeList = list
        self.addMarkers()
        self.updateStoreLists()
        self.isBusy = false
        if let address = self.storeList.first?.addressRelationship?.coordinate {
            let location = CLLocation(latitude: address.latitude, longitude: address.longitude)
            if self.userLocation == nil {
                self.mapView.animateWithCameraUpdate(GMSCameraUpdate.setTarget(location.coordinate))
            } else {
                let bounds = GMSCoordinateBounds(coordinate: self.userLocation!.coordinate, coordinate: location.coordinate)
                
                self.mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds, withPadding: 100.0))
            }
        }
        
    }
    

    
    @IBAction func unwindToStoreLocator(segue: UIStoryboardSegue) {}
    
    // add markers to map
    func addMarkers(){
        
        self.markers.removeAll()
        for store in self.storeList {
            if let lat = store.addressRelationship?.coordinate.latitude , lng = store.addressRelationship?.coordinate.longitude {
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2DMake(lat,lng)
                marker.appearAnimation = kGMSMarkerAnimationPop
                
                marker.icon = pinUIImage
                self.markers.append(marker)
                
                marker.map = self.mapView
            }
        }
        if self.markers.count > 0 {
            self.markers[0].icon = pinActiveUIImage
            //            let cell = storeCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? StoreLocatorCollectionViewCell
            //            cell?.pinImageView.image = pinActiveUIImage
            
            self.selectedMarkerIndex = 0
        }
        
    }
    
    func updateStoreLists() {
        self.collectionView.reloadData()
    }
    
    var lockScroll = false
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        if let index = self.markers.indexOf(marker) {
            //            if isCheckout && basket?.suggestStores == true {
            //                if !breakfastStores.contains(self.storeList[index]) {
            //                    return false
            //                }
            //            }
            var newContentOffset = CGFloat()
            lockScroll = true
            if index == 0 || index == self.markers.count-1{
                newContentOffset = (CGFloat(index) * (self.collectionView.frame.width/1.2))+CGFloat(index * 10)
            } else {
                newContentOffset = (CGFloat(index) * (self.collectionView.frame.width/1.2))+CGFloat((index-1) * 10)
            }
            
            UIView.animateWithDuration(0.2, animations: {
                self.collectionView.contentOffset.x = newContentOffset
                
                }, completion: { _ in
                    //deactive pins
                    var cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: self.selectedMarkerIndex, inSection: 0)) as? StoreLocatorCollectionViewCell
                    cell?.pinImageView.image = self.pinUIImage
                    self.markers[self.selectedMarkerIndex].icon = self.pinUIImage
                    
                    //active pins
                    self.markers[index].icon = self.pinActiveUIImage
                    cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? StoreLocatorCollectionViewCell
                    cell?.pinImageView.image = self.pinActiveUIImage
                    
                    self.selectedMarkerIndex = index
                    self.lockScroll = false
                    
            })
            
        }
        return true
    }
    
}


//MARK: LocationManager Delegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        } else if status == .Denied {
            if !self.isBusy {
                self.requestToGetStores(self.storeList)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        if let latestLocation = locations.last {
            self.userLocation = latestLocation
            
            if !userLocationMarkerAdded {
                userLocationMarkerAdded = true
                self.mapView?.camera = GMSCameraPosition.cameraWithTarget(latestLocation.coordinate, zoom: 9.0)
                originMarker = GMSMarker(position: latestLocation.coordinate)
                self.originMarker?.map = self.mapView
                self.originMarker?.appearAnimation = kGMSMarkerAnimationPop
                self.originMarker?.icon = UIImage(named: "MyLocation")
            }
            if !isBusy {
                self.requestToGetStores(self.storeList)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if !self.isBusy {
            self.requestToGetStores(self.storeList)
        }
    }
    
}

//MARK: CollectionView Delegate
extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.storeList.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("storeCell", forIndexPath: indexPath) as! StoreLocatorCollectionViewCell
        let store : ListItem?
        store = self.storeList[indexPath.row]
        cell.store = store
        if indexPath.row == 0 && self.selectedMarkerIndex == 0 {
            cell.pinImageView.image = pinActiveUIImage
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)

    }
    
    func collectionView(collectionView : UICollectionView,layout collectionViewLayout:UICollectionViewLayout,sizeForItemAtIndexPath indexPath:NSIndexPath) -> CGSize
    {
        return CGSize(width: self.collectionView.frame.width/1.2 , height: self.collectionView.frame.height - 32 )
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !lockScroll {
            let cellWidth = self.collectionView.frame.width/1.2
            let index = Int((self.collectionView.contentOffset.x+(cellWidth/2)) / (cellWidth + 10))
            if index < self.markers.count {
                if index != self.selectedMarkerIndex {
                    let store : ListItem?
                    store = self.storeList[index]
                    
                    if let address = store?.addressRelationship?.coordinate {
                        let adddressCLLocation = CLLocation(latitude: address.latitude, longitude: address.longitude)
                        self.mapView.animateWithCameraUpdate(GMSCameraUpdate.setTarget(adddressCLLocation.coordinate))
                        self.markers[selectedMarkerIndex].icon = pinUIImage
                        self.markers[index].icon = pinActiveUIImage
                        var cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? StoreLocatorCollectionViewCell
                        cell?.pinImageView.image = pinActiveUIImage
                        cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: selectedMarkerIndex, inSection: 0)) as? StoreLocatorCollectionViewCell
                        cell?.pinImageView.image = pinUIImage
                        self.selectedMarkerIndex = index
                        
                    }
                }
            }
        }
    }
    
}

class StoreLocatorCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var storeDistance: UILabel!
    @IBOutlet weak var pinImageView: UIImageView!
    
    var store: ListItem? {
        didSet{
            self.storeName.text = store?.name?.uppercaseString
            if let distance = store?.distance {
                let distanceString = String(distance)
                self.storeDistance.text = distanceString + "km"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.storeName.textColor = UIColor.blackColor()
        
    }
    

}
