# FlickrWanderer
This app was created for a code challenge, I decided to open source it as I wanted to have some public Swift code to point to for any future job/contract applications. The app uses your device's location to download photos from the Flickr search API.

The app demonstrates the use of:
- Swift 4
- CoreLocation
- Making asynchronous URL connections to a RESTful API
- Receiving and deserializing JSON objects
- Basic use of Storyboards & Autolayout
- Simple MVC app structure

*Please note that to actually use the app you will need to request an API key from Flickr. This app was coded with XCode 9.4 and may require modification to run in earlier or later versions, especially as Swift is still in a state of constant flux.*

The app at present has a number of limitations such as not tracking in the background or caching images. These are known issues and the app was deliberately implemented this way to meet the scope of the coding challenge.
