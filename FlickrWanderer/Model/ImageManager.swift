//
//  Tracker.swift
//  FlickrWanderer
//
//  Created by Rory Prior on 20/07/2018.
//  Copyright © 2018 ThinkMac Software. All rights reserved.
//

import UIKit

class ImageManager: NSObject {

  var imageURLs : Array<URL>
  
  override init() {
    self.imageURLs = Array()
  }
  
  /* this class could be expanded to add methods for archiving and restoring the
     the recorded image URLs, but for now at least it keeps our data out of the controller */
}
