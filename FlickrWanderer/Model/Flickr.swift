//
//  Flickr.swift
//  FlickrWanderer
//
//  Created by Rory Prior on 20/07/2018.
//  Copyright © 2018 ThinkMac Software. All rights reserved.
//

import Foundation
import CoreLocation

class Flickr: NSObject {
  
  /**
   * Searches Flickr using the supplied latitude and longitude and returns
   * an array of image URLs via a completion handler on success
   */
  func fetchPhotos(lat: CLLocationDegrees, long: CLLocationDegrees, completion:@escaping (_ photoURLs: Array<URL>?, _ error: Error?) -> Void) {
    
    // flickr requires our search not be too open ended so lets cap it to the last 8 years and as we'll only
    // show 1 image to the user per location also cap the returns
    let params = ["min_taken_date": "2010-01-01 00:00:01",
                  "lat": "\(lat)",
                  "lon": "\(long)",
                  "has_geo": "1", // we want geotagged entries only
                  "radius": "1", // 1km
                  "per_page": "10", // 10 results should be plenty per location
                  "page": "1",
                  "safe_search": "1", // safe (should be default, but better safe than sorry!)
                  "accuracy": "16"] // highest accuracy level Flickr allows (street level)
    
    sendRequest(endPoint: "flickr.photos.search", params: params) { (data, error) in
      
      // no data? fail now
      guard (data != nil) else {
        completion(nil, error)
        return
      }
      
      // see if we've received some valid JSON objects
      let json = try? JSONSerialization.jsonObject(with: data!, options: [])
    
      if let dictionary = json as? [String: Any],
         let photos = dictionary["photos"] as? [String: Any],
         let photoArray = photos["photo"] as? [[String : Any]] {
      
        var photoURLs: [URL] = []
        
        for photo in photoArray {
          if let farm = photo["farm"] as? Int,
             let server = photo["server"] as? String,
             let photoID = photo["id"] as? String,
             let secret = photo["secret"] as? String {
               if let photoURL = self.photoURL(farm: farm,
                                           serverID: server,
                                            photoID: photoID,
                                             secret: secret,
                                               size: "c") {
                photoURLs.append(photoURL)
              }
          }
        }
        completion(photoURLs, nil)
      }
    }
  }
  
  // MARK: -
  
  /**
   * Construct a Flickr photo URL from various components. See https://www.flickr.com/services/api/misc.urls.html
   * for details.
   */
  func photoURL(farm: Int, serverID: String, photoID: String, secret: String, size: String) -> URL?
  {
    guard let returnURL = URL(string: "https://farm\(farm).staticflickr.com/\(serverID)/\(photoID)_\(secret)_\(size).jpg") else {
      return nil
    }
    return returnURL
  }
  
  /**
   * Sends a request to the flickr API.
   */
  func sendRequest(endPoint: String!, params: Dictionary<String,String>!, completion: @escaping (_ JSON: Data?, _ error: Error?) -> Void) {

    /* in a real world scenario we'd want to to configure the session to run in the background, but that adds
       significant complication as we need to use a data task delegate and setup a queue, so we'll just run things
       asynchronously while the app is in the foreground for the purposes of this challenge */
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    
    guard var URL = URL(string: "https://api.flickr.com/services/rest/") else {return}
    
    // warning: INSERT YOUR API LEY HERE!
    var combinedParams = ["api_key": "",
                          "format" : "json",
                          "nojsoncallback" : "1", // Flickr uses JSONP by default which JSONSerialization can't understand
                          "method" : endPoint!]
    
    // merge in the passed parameters favouring the passed parameters over the
    // convenience ones for added flexibility
    combinedParams = combinedParams.merging(params, uniquingKeysWith: { (_, last) in last })
    URL = URL.appendingQueryParameters(combinedParams)
    
    var request = URLRequest(url: URL)
    request.httpMethod = "GET"
    
    /* Start a new Task */
    let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
      if (error == nil) {
        // Success
        let statusCode = (response as! HTTPURLResponse).statusCode
        if(statusCode == 200) {
          completion(data, nil)
          return
        }
        else {
          // Unexpected status code
          print("Unexpected status code: \(statusCode)")
          completion(nil, nil) // we won't return JSON because the calling function may not be getting what it asked for
        }
      }
      else {
        // Failure
        print("URL Session Task Failed: %@", error!.localizedDescription);
        completion(nil, error)
      }
    })
    task.resume()
    session.finishTasksAndInvalidate()
  }

}

protocol URLQueryParameterStringConvertible {
  var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
  /**
   This computed property returns a query parameters string from the given NSDictionary. For
   example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
   string will be @"day=Tuesday&month=January".
   @return The computed parameters string.
   */
  var queryParameters: String {
    var parts: [String] = []
    for (key, value) in self {
      let part = String(format: "%@=%@",
                        String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                        String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
      parts.append(part as String)
    }
    return parts.joined(separator: "&")
  }
  
}

extension URL {
  /**
   Creates a new URL by adding the given query parameters.
   @param parametersDictionary The query parameter dictionary to add.
   @return A new URL.
   */
  func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
    let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
    return URL(string: URLString)!
  }
}


