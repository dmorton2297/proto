//
//  HomeViewController.swift
//  proto
//
//  Created by Dan Morton on 2/25/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//
//  This class describes the functino of the "home" view controller.
//  This view controller contains the "My Posts" section.
//

//last left off writing the method to save a post. see savePost

import UIKit
import CoreLocation
import Parse


class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var postsTableView: UITableView! //connection to tableview in view controller
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! //connection used wen there is an external process happending
    @IBOutlet var profilePictureImage: UIImageView! //placeholder for the profile picture of a user
    
    let picker = UIImagePickerController()//image picker that will be used when user presses
    
    var data = [PictureEntry]()//the data for the postsTableView
    var alreadyOpened = false //this is used to determeine weather the view should be loaded or not. See viewDidAppear
    
    var selectedUser : PFUser! //placeholder variable for when the user selects a friends from the likes list. Used in likeButtonPressed and prepare for segue.
    
    var savingPost = false
    
    
    
    //----ViewController Configurations------------------------------------------------------------------------
    //setup for this view controller
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var navController = self.parentViewController as! UINavigationController
        
        
        //start activity indicator
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        //UIImagePickerDelegation
        picker.delegate = self
        
        
        //Slide menu setup
        
        if (registeredForPushNotification )
        {
            let currentInstallation = PFInstallation.currentInstallation()
            var channels = currentInstallation.objectForKey("channels") as! [String]
            
            var contains = false
            
            let look = "channel\(appManager.user.objectId)"
            for x in channels
            {
                if (x == look)
                {
                    contains = true
                }
            }
            if (!contains)
            {
                currentInstallation.addUniqueObject("channel\(appManager.user.objectId)", forKey: "channels")
                currentInstallation.saveInBackgroundWithBlock({ (success, error) -> Void in
                    if (!success)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not sign up user for notifications", completion: nil)
                    }
                    else
                    {
                        appManager.displayAlert(self, title: "Success", message: "You are now signed up for notifications", completion: nil)
                    }
                })
            }
        }
        
        loadUserData()
        loadProfilePicture()
    }
    
    override func viewDidAppear(animated: Bool) {
        if (!savingPost)
        {
            loadUserData()
        }
        loadProfilePicture()
        
    }
    
    
    
    //--Parse functions-----------------------------------------------------------------------------------------
    
    //this method saves posts to the current users data object
    func savePost(entry:PictureEntry)
    {
        var object = PFObject(className: "ImagePost")
        
        var imageFile = appManager.convertUIImageToPFFile(entry.image)
        
        object["image"] = imageFile
        object["caption"] = entry.caption
        object["likes"] = [NSObject]()
        object["coordinates"] = ("\(entry.location.coordinate.latitude), \(entry.location.coordinate.longitude)")
        object["date"] = NSDate()
        object["point_worth"] = entry.pointWorth
        
        object.saveInBackgroundWithBlock { (completion, error) -> Void in
            
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not save post", completion: nil)
            }
            else
            {
                self.finishSavingPost(object.objectId)
            }
        }
        
        
        
    }
    
    func finishSavingPost(objectId:String)
    {
        var imagePosts = appManager.user["image_posts"] as! [NSObject]
        imagePosts.insert(objectId, atIndex: 0)
        appManager.user["image_posts"] = imagePosts
        appManager.user["lastPostedTime"] = NSDate()
        appManager.user.saveInBackgroundWithBlock { (completion, error) -> Void in
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not save post. ", completion: nil)
                self.savingPost = false
                
            }
            else
            {
                appManager.displayAlert(self, title: "Success", message: "Your post was successfully uploaded", completion: nil)
                self.savingPost = false
                self.viewDidAppear(true)
            }
        }
    }
    
    
    
    
    
    //this method will get all of the users data and load it into the poststableview
    func loadUserData()
    {
        var data = appManager.user.objectForKey("image_posts") as! [NSString]
        var unsortedArray = [(PictureEntry, Int)]()
        
        var completionCounter = 0
        for (var i = 0; i < data.count; i++)
        {
            var query = PFQuery(className: "ImagePost")
            var object = data[i] as! String
            var tempIndex = i
            query.getObjectInBackgroundWithId(object, block: { (object, error) -> Void in
                if (error == nil)
                {
                    let geocoder = CLGeocoder()
                    
                    var imageFile = object.objectForKey("image") as! PFFile
                    var caption = object.objectForKey("caption") as! String
                    var likes = object.objectForKey("likes") as! [String]
                    var coordinatesString = object.objectForKey("coordinates") as! String
                    var date = object.objectForKey("date") as! NSDate
                    var pointWorth = object.objectForKey("point_worth") as! Int
                    
                    var coordinates = self.getLocationFromString(coordinatesString)
                    
                    imageFile.getDataInBackgroundWithBlock { (picture, error) -> Void in
                        geocoder.reverseGeocodeLocation(coordinates, completionHandler: { (results, error) -> Void in
                            if (error == nil && results != nil)
                            {
                                if (results.count >= 0)
                                {
                                    let placemark = results[0] as! CLPlacemark
                                    var entry = PictureEntry(image: UIImage(data: picture)!, caption: caption, location: coordinates, pointWorth: pointWorth, locality: placemark.locality, date:date, liked: false, likes: likes)
                                    unsortedArray.append((entry, tempIndex))
                                    completionCounter++
                                    if (completionCounter == data.count){self.sortInfoIntoTableView(unsortedArray)}
                                }
                            }
                            else
                            {
                                appManager.displayAlert(self, title: "Error", message: "Error retrieving image data.", completion: nil)
                            }
                        })
                    }
                }
                else
                {
                    appManager.displayAlert(self, title: "Error", message: "Error retrieving image data.", completion: nil)
                }
            })
        }
    }
    
    func getLocationFromString(str:String) -> CLLocation
    {
        var a = ""
        var b = ""
        var toggle = true
        for x in str
        {
            if (x != "\"")
            {
                if (x == ","){toggle = false}
                else if (toggle)
                {
                    a = a + "\(x)"
                }
                else if (!toggle)
                {
                    b = b + "\(x)"
                }
            }
        }
        
        
        var lat = (a as NSString).doubleValue
        var long = (b as NSString).doubleValue
        
        
        
        return CLLocation(latitude: lat, longitude: long)
    }
    
    func sortInfoIntoTableView(dat:[(PictureEntry, Int)])
    {
        var temp = [PictureEntry]()
        for (var i = 0; i < dat.count; i++)
        {
            for y in dat
            {
                if (y.1 == i)
                {
                    
                    temp.append(y.0)
                }
            }
        }
        
        data.removeAll(keepCapacity: false)
        data = temp
        postsTableView.reloadData()
        
        postsTableView.reloadData()
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }
    
    func loadProfilePicture()
    {
        let profilePictureFile = appManager.user.objectForKey("profile_picture")as! PFFile
        
        profilePictureFile.getDataInBackgroundWithBlock { (dat, error) -> Void in
            var image = UIImage(data: dat)
            if (image == nil){image = UIImage(named: "friendsIcon")}
            self.profilePictureImage.image = image
        }
    }
    
    
    //function to remove a data entry from this user
    func deletePost(atIndexPath:NSIndexPath)
    {
        var userPosts = appManager.user.objectForKey("image_posts") as! [NSString]
        var objectId = userPosts.removeAtIndex(atIndexPath.row)
        appManager.user["image_posts"] = userPosts
        appManager.user.saveInBackgroundWithBlock { (completion, error) -> Void in
            if (error == nil)
            {
                var query = PFQuery(className: "ImagePost")
                query.getObjectInBackgroundWithId(objectId as! String, block: { (obj, error) -> Void in
                    if (error == nil)
                    {
                        var a = obj
                        a.deleteInBackgroundWithBlock { (completion, error) -> Void in
                            if (error != nil)
                            {
                                appManager.displayAlert(self, title: "Error", message: "Post could not be deleted.", completion: nil)
                            }
                            else
                            {
                                self.data.removeAtIndex(atIndexPath.row)
                                self.postsTableView.deleteRowsAtIndexPaths([atIndexPath], withRowAnimation: UITableViewRowAnimation.Bottom)
                                self.postsTableView.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }
    
    
    //UITableView delegation methods-----------------------------------------------------------------------------------------
    
    //configures each tableview cell at a given indexpath
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        //creating a cell
        var cell = tableView.dequeueReusableCellWithIdentifier("recentLocCell")as! PictureEntryTableViewCell
        //setting the title text label to
        cell.locationTextLabel.text = data[indexPath.row].caption
        
        
        cell.coordinatesTextLabel.text = "\(data[indexPath.row].locality)"
        
        //setting the image thumbnail in the cell
        cell.selfieImageView.clipsToBounds = true
        cell.selfieImageView.image = data[indexPath.row].image
        cell.selfieImageView.layer.cornerRadius = 5
        
        
        cell.likeButton.tag = indexPath.row
        cell.likeCountLabel.text = "\(data[indexPath.row].likes.count)"
        
        cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, postsTableView.frame.width, 100)
        
        
        return cell
    }
    
    //determine the height of the cell. This will be determined by the aspect ratio of the image in the cell
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        //calculate the new height of the cell view
        var scale = data[indexPath.row].image.size.width / postsTableView.frame.width
        var height = data[indexPath.row].image.size.height/scale
        
        return height
    }
    
    //returns the number of tableviewcells in the table
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    //handles if tableview is selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        performSegueWithIdentifier("detail", sender: self)
    }
    
    //configurations for deleting tableviewcell on swipe
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        
        //Configure these cells to have a swipe to delete
        if (editingStyle == UITableViewCellEditingStyle.Delete)
        {
            deletePost(indexPath)
        }
    }
    
    //UIIMagePickerController delgation methods-------------------------------------------------------------------------
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!)
    {
        
        //once the user has made a choice with an image, ask them where the name of their location.
        //this is for collecting data for their post.
        var alert = UIAlertController(title: "Give a name to this picture", message: "Where are you?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler{(textField) -> Void in
            textField.placeholder = "-Name-"
        }
        
        var action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            let field = alert.textFields?[0]as! UITextField
            let info = field.text
            //check if user added nothing
            if (info == "" || info == nil)
            {
                appManager.displayAlert(picker, title: "Oops..", message: "Nothing added, no title provided.", completion: nil)
            }
            else
            {
                appManager.locationManager.stopUpdatingLocation()
                var location = appManager.locationManager.location
                var entry = PictureEntry(image: image, caption: info, location: location, pointWorth: 10, locality: "temp", date:NSDate(), liked: false, likes: [String]())
                self.data.insert(entry, atIndex: 0)
                self.postsTableView.reloadData()
                self.savingPost = true
                self.savePost(entry)
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(action)
        picker.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //IBAction connections from storyboard-------------------------------------------------------------------------
    
    //this method will log out the current user
    @IBAction func logoutButtonPresssed(sender: UIBarButtonItem)
    {
        let alert = UIAlertController(title: "", message: "Do you want to logout?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) { (action) -> Void in
            PFUser.logOut()
            appManager.user = nil
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let noAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //this method will allow a user to take a photo, or pick on from the library for a post.
    @IBAction func checkInButtonPressed(sender: AnyObject)
    {
        //create an action sheet that allows a user to pick between library and camera
        var alert : UIAlertController!
        
        if(UIDevice.currentDevice().model.lowercaseString.rangeOfString("ipad") != nil)
        {
            alert = UIAlertController(title: "Select an input source.", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        }
        else
        {
            alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        }
        var cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default){(alertAction) -> Void in
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera
            self.presentViewController(self.picker, animated: true, completion: nil)
        }
        var libraryAction = UIAlertAction(title: "Library", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            self.picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(self.picker, animated: true, completion: nil)
        }
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        
        //present the action sheet
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func likeButtonPressed(sender: UIButton)
    {
        var index = sender.tag
        var alert = UIAlertController(title: "Loading...", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        var likes = data[index].likes
        var tempCounter = 0
        
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        for x in likes
        {
            let query = PFUser.query()
            query.getObjectInBackgroundWithId(x, block: { (object, error) -> Void in
                if (error == nil)
                {
                    var selUser = object as! PFUser
                    
                    var action = UIAlertAction(title: selUser.username, style: UIAlertActionStyle.Default, handler: { (alertAction) -> Void in
                        self.selectedUser = selUser
                        self.performSegueWithIdentifier("showFriendsFeed2", sender: self)
                        
                    })
                    alert.addAction(action)
                    tempCounter++
                    
                    if (tempCounter == likes.count)
                    {
                        alert.title = "Likes"
                    }
                    
                }
            })
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
        
    }
    
    
    //menu setup---------------------------------------------------------------------------------------------
    //segue configuration
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showFriendsFeed2")
        {
            var dvc = segue.destinationViewController as! FriendsFeedViewController
            dvc.user = selectedUser
        }
        else
        {
            var dvc = segue.destinationViewController as! PostDetailViewController
            dvc.location = data[postsTableView.indexPathForSelectedRow()!.row].location
            
            postsTableView.deselectRowAtIndexPath(postsTableView.indexPathForSelectedRow()!, animated: true)
        }
        
    }
    
    
    
    //date utility
    func toStringOfAbbrevMonthDayAndTime(date:NSDate) -> String
    {
        //convert to regular looking time
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, hh:mm aa"
        return dateFormatter.stringFromDate(date)
    }
    
    
    
    
    
}
