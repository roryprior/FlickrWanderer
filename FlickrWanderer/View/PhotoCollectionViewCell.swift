//
//  PhotoCollectionViewCell.swift
//  FlickrWanderer
//
//  Created by Rory Prior on 20/07/2018.
//  Copyright © 2018 ThinkMac Software. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

  @IBOutlet var imageView : UIImageView!
  @IBOutlet var spinner : UIActivityIndicatorView!
  public var photoURL : URL?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.photoURL = nil
  }
  
  
  func setPhotoURL(aURL: URL) {
    
    self.imageView.isHidden = true
    
    // for the sake of simplicity we'll request the image each time we set
    // the URL, in a real world app we'd want to cache the image to reduce network activity
    // and improve the user experience
    URLSession.shared.dataTask(with: aURL) { (imageData, URLResponse, error) in
      guard imageData != nil else {
        print("Could not load image from \(aURL.absoluteString) error: \(error?.localizedDescription ?? "Unknown")")
        return
      }
      
      if let image = UIImage(data: imageData!) {
        DispatchQueue.main.async {
          self.spinner.stopAnimating()
          self.imageView.image = image
          self.imageView.alpha = 0.0
          self.imageView.isHidden = false
          
          UIView.animate(withDuration: 0.33, animations: {
            self.imageView.alpha = 1.0
          })
        }
      }
    }.resume()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    spinner.startAnimating()
  }
}
