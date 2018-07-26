//
//  ViewController.swift
//  FlickrWanderer
//
//  Created by Rory Prior on 20/07/2018.
//  Copyright © 2018 ThinkMac Software. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate {
  
  @IBOutlet var collectionView : UICollectionView?
  @IBOutlet var trackingButton : UIBarButtonItem?
  var imageManager = ImageManager()
  let photoCellIdentifier = "PhotoCellIdentifier"
  let locationManager = CLLocationManager()
  var trackingEnabled = false
  var nextUpdate = Date()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Check location services are enabled or the app is useless
    guard CLLocationManager.locationServicesEnabled() == true else {
      
      let alertController = UIAlertController(title: "Location Services Not Enabled",
                                              message: "This app won't work with location services disabled. Please enable Location Services in the Settings app", preferredStyle: UIAlertControllerStyle.alert)
      self.present(alertController, animated: true, completion: nil)
      
      return
    }
    
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.activityType = CLActivityType.fitness
    locationManager.distanceFilter = 100 // get location update events every 100 meters

    // Setup the collection view
    collectionView?.register(UINib.init(nibName: "PhotoCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: photoCellIdentifier)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Actions
  
  @IBAction func doChangeTrackingStatus(sender: UIBarButtonItem) {
    trackingEnabled = !trackingEnabled
    
    if(trackingEnabled) {
      self.trackingButton?.title = "Stop"
      self.locationManager.startUpdatingLocation()
    }
    else {
      self.trackingButton?.title = "Start"
      self.locationManager.stopUpdatingLocation()
    }
  }
  
  // MARK: - Location Manager Delegate
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    let now = Date()
    
    // avoid spurious updates by requiring at least 20 seconds between image searches,
    // we also don't want to trigger any rate limiting on the flickr API
    guard now > nextUpdate else {
      return
    }
    
    guard let location = locations.last else {
      // we can't do much if we've got no location object so just exit here
      return
    }
    
    // we'll allow another location update 20 seconds from now
    nextUpdate = now.addingTimeInterval(20)
    
    Flickr().fetchPhotos(lat: location.coordinate.latitude, long: location.coordinate.longitude) { (URLs, error) in
      guard error == nil else {
        print("Error fetching photos %@", error!.localizedDescription)
        return
      }
      guard URLs != nil else {
        print("We didn't get any image URLs")
        return
      }
      
      // avoid adding the same image over and over if there aren't many available
      // for our location

      var addedImage = false
      
      for URL in URLs! {
        if self.imageManager.imageURLs.contains(URL) == false {
          self.imageManager.imageURLs.insert(URL, at: 0)
          addedImage = true
          break
        }
      }
      
      // avoid adding nothing at all
      if !addedImage {
        self.imageManager.imageURLs.insert(URLs![0], at: 0)
      }
      
      // make sure UI updates are called on the main thread
      DispatchQueue.main.async {
        
        // only update the UI if the app is actually in the foreground
        if UIApplication.shared.applicationState == UIApplicationState.active {
          self.collectionView?.reloadData()
        }
      }
    }
  }

  // MARK: - Data Source

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
  {
    return self.imageManager.imageURLs.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellIdentifier, for: indexPath) as! PhotoCollectionViewCell
    
    cell.setPhotoURL(aURL: self.imageManager.imageURLs[indexPath.row])
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
  {
    return CGSize(width: self.view.frame.size.width, height: 240)
  }
}
