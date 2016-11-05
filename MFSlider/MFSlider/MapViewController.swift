//
//  StoreLocatorViewController.swift
//  MySumo
//
//  Created by Fekri on 5/24/16.
//  Copyright © 2016 Round Table Apps. All rights reserved.
//

import UIKit
import CoreLocation


class MapViewController: UIViewController {
    
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
    
    @IBAction func backButton(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }

    //Request to get stores
    func requestToGetStores(list: [ListItem]) {
        self.isBusy = true
        
        self.storeList = list
        self.updateStoreLists()
        self.isBusy = false
        if let address = self.storeList.first?.addressRelationship?.coordinate {
            let location = CLLocation(latitude: address.latitude, longitude: address.longitude)
        }
        
    }
    
    
    func updateStoreLists() {
        self.collectionView.reloadData()
    }
    
    var lockScroll = false

    
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
            if index != self.selectedMarkerIndex {
                let store : ListItem?
                store = self.storeList[index]
                
                if let address = store?.addressRelationship?.coordinate {
                    let adddressCLLocation = CLLocation(latitude: address.latitude, longitude: address.longitude)
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
