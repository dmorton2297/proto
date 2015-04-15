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
    
    @IBOutlet weak var backgroundImage: UIImageView! //background image connection from storyboard.
    @IBOutlet var menu: SlideMenu! //menu connection from storyboard
    @IBOutlet var postsTableView: UITableView! //connection to tableview in view controller
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! //connection used wen there is an external process happending
    @IBOutlet var profilePictureImage: UIImageView! //placeholder for the profile picture of a user
    
    let picker = UIImagePickerController()//image picker that will be used when user presses
    
    var data = [PictureEntry]()//the data for the postsTableView
    var alreadyOpened = false //this is used to determeine weather the view should be loaded or not. See viewDidAppear
    
    
    //----ViewController Configurations------------------------------------------------------------------------
    //setup for this view controller
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        postsTableView.backgroundColor = UIColor(white: 1, alpha: 0.3)
        //start activity indicator
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        //UIImagePickerDelegation
        picker.delegate = self
        
        //blurring the background image
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.frame
        self.view.addSubview(blurView)
        self.view.sendSubviewToBack(blurView)
        self.view.sendSubviewToBack(backgroundImage)
        
        //Slide menu setup
        menu.superViewController = self
        
        
        //styling of the profile picture image
        profilePictureImage.clipsToBounds = true
        profilePictureImage.layer.cornerRadius = 30
        
        //subscribe this user to there push notification channel
        let currentInstallation = PFInstallation.currentInstallation()
        
        currentInstallation.addUniqueObject("channel\(appManager.user.objectId)", forKey: "channels")
        currentInstallation.saveInBackgroundWithBlock { (completion, error) -> Void in
            if (error != nil)
            {
                appManager.displayAlert(self, title: "error", message: "could not subscribe to channel", completion: nil)
            }
        }
        
    }
    
    //once the view loads, load all of the users information into the viewcontroller
    override func viewDidAppear(animated: Bool)
    {
        if (!alreadyOpened)
        {
            loadUserData()
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            alreadyOpened = true
        }
    }
    
    //--Parse functions-----------------------------------------------------------------------------------------
    
    //this method saves posts to the current users data object
    func savePost(entry:PictureEntry)
    {
        var dataObject:PFObject? = appManager.getUsersData()
        if (dataObject != nil)
        {
            var locationsNames:[NSObject] = dataObject?.objectForKey("location_names") as! [NSObject]
            var locationsCoordinates:[NSObject] = dataObject?.objectForKey("location_coordinates") as! [NSObject]
            var pointWorths: [NSObject] = dataObject?.objectForKey("point_worth") as! [NSObject]
            var images:[NSObject] = dataObject?.objectForKey("images") as! [PFFile]
            //check if the size of the arrays are more that 15
            if (locationsNames.count == 15)
            {
                //get rid of the fifteenth post
                locationsNames.removeLast()
                locationsCoordinates.removeLast()
                images.removeLast()
            }
            
            //convert image to a saveable pffile before upload
            var imageFile:PFFile = appManager.convertUIImageToPFFile(entry.image)
            //get rest of info for post
            var pointWorth = entry.pointWorth
            var locationName = entry.name
            var locationCoordinates = entry.location.description
            
            //add new information to the array
            locationsNames.insert(locationName, atIndex: 0)
            locationsCoordinates.insert(locationCoordinates, atIndex: 0)
            pointWorths.insert(pointWorth, atIndex: 0)
            images.insert(imageFile, atIndex: 0)
            var newObject = dataObject!
            
            //create the new object to save
            newObject["location_names"] = locationsNames
            newObject["location_coordinates"] = locationsCoordinates
            newObject["point_worth"] = pointWorths
            newObject["images"] = images
            //save the new object
            newObject.saveInBackgroundWithBlock({ (test, error) -> Void in
                if (!test)
                {
                    appManager.displayAlert(self, title: "Error", message: "Could not save image", completion: nil)
                }
                else
                {
                    appManager.displayAlert(self, title: "Success", message: "Your image was successfully uploaded.", completion: nil)
                }
            })
        }
        else
        {
            appManager.displayAlert(self, title: "Error", message: "Could not load data", completion: nil)
        }
    }
    
    
    //this method will get all of the users data and load it into the poststableview
    func loadUserData()
    {
        //retrieve the users posts information
        var query = PFQuery(className:"UserData")
        var dat:PFObject!
        if (appManager.user == nil){return}
        var dataID = appManager.user.objectForKey("dataID") as! NSString
        query.getObjectInBackgroundWithId(dataID as String, block: { (data, error) -> Void in
            
            //this following block will load if the query was successful.
            if (error == nil)
            {
                //retrieve all of the users present information
                var locationsNames:[NSObject] = data?.objectForKey("location_names") as! [NSObject]
                var locationsCoordinates:[NSObject] = data?.objectForKey("location_coordinates")as! [NSObject]
                var pointWorths: [NSObject] = data?.objectForKey("point_worth")as! [NSObject]
                var images:[NSObject] = data?.objectForKey("images")as! [PFFile]
                var profilePictureFile = appManager.user.objectForKey("profile_picture")as! PFFile
                var profilePicture = appManager.convertPFFiletoUIImage(profilePictureFile)
                
                //set the profile picture thumbnail
                self.profilePictureImage.image = profilePicture
                
                //append the new post to the existing information
                for (var i = 0; i < locationsNames.count; i++)
                {
                    let imageFile = images[i]as! PFFile
                    let image = appManager.convertPFFiletoUIImage(imageFile)
                    let name = locationsNames[i]as! String
                    let pointWorth = pointWorths[i]as! NSInteger
                    let coordinates = CLLocation(latitude: 100, longitude: 500)
                    
                    let entry = PictureEntry(image: image, name: name, location: coordinates, pointWorth: pointWorth)
                    self.data.append(entry)
                }
                
                //save the updated object
                self.postsTableView.reloadData()
            }
            else
            {
                appManager.displayAlert(self, title: "Error", message: "Could not load data", completion: nil)
            }
        })
    }
    
    //function to remove a data entry from this user
    func deletePost(atIndex:Int)
    {
        //retrieve the users posts information
        var query = PFQuery(className:"UserData")
        var dat:PFObject!
        if (appManager.user == nil){return}
        var dataID = appManager.user.objectForKey("dataID") as! NSString
        query.getObjectInBackgroundWithId(dataID as String, block: { (data, error) -> Void in
            
            //this following block will load if the query was successful.
            if (error == nil)
            {
                var locationsNames:[NSObject] = data?.objectForKey("location_names") as! [NSObject]
                var locationsCoordinates:[NSObject] = data?.objectForKey("location_coordinates")as! [NSObject]
                var pointWorths: [NSObject] = data?.objectForKey("point_worth")as! [NSObject]
                var images:[NSObject] = data?.objectForKey("images")as! [PFFile]
                
                locationsNames.removeAtIndex(atIndex)
                locationsCoordinates.removeAtIndex(atIndex)
                pointWorths.removeAtIndex(atIndex)
                images.removeAtIndex(atIndex)
                
                var newObject = data
                
                //create the new object to save
                newObject["location_names"] = locationsNames
                newObject["location_coordinates"] = locationsCoordinates
                newObject["point_worth"] = pointWorths
                newObject["images"] = images
                //save the new object
                newObject.saveInBackgroundWithBlock({ (test, error) -> Void in
                    if (!test)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not save image", completion: nil)
                    }
                    else
                    {
                        appManager.displayAlert(self, title: "Success", message: "Your image was successfully deleted.", completion: nil)
                    }
                })
                
                
            }
        })
        
    }
    
    
    //UITableView delegation methods-----------------------------------------------------------------------------------------
    
    //configures each tableview cell at a given indexpath
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        //creating a cell
        var cell = tableView.dequeueReusableCellWithIdentifier("recentLocCell")as! PictureEntryTableViewCell
        //setting the title text label to
        cell.locationTextLabel.text = data[indexPath.row].name
        
        //getting coorinates of this specific picture entry
        let lat = data[indexPath.row].location.coordinate.latitude
        let long = data[indexPath.row].location.coordinate.longitude
        cell.coordinatesTextLabel.text = "Lat: 100, Long: 530"
        
        //setting the image thumbnail in the cell
        cell.selfieImageView.clipsToBounds = true
        cell.selfieImageView.image = data[indexPath.row].image
        cell.selfieImageView.layer.cornerRadius = 5
        
        println("Width of image \(cell.selfieImageView.frame.width). Size of the screen \(self.view.frame.width) ")
        
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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //configurations for deleting tableviewcell on swipe
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        
        //Configure these cells to have a swipe to delete
        if (editingStyle == UITableViewCellEditingStyle.Delete)
        {
            data.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Bottom)
            deletePost(indexPath.row)
            tableView.reloadData()
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
                var entry = PictureEntry(image: image, name: info, location: CLLocation(latitude: 10, longitude: 10), pointWorth: 10)
                self.data.insert(entry, atIndex: 0)
                self.postsTableView.reloadData()
                self.savePost(entry)
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(action)
        picker.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //IBAction connections from storyboard-------------------------------------------------------------------------
    
    
    //this method will allow a user to take a photo, or pick on from the library for a post.
    @IBAction func checkInButtonPressed(sender: AnyObject)
    {
        //create an action sheet that allows a user to pick between library and camera
        var alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
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
    
    //menu setup---------------------------------------------------------------------------------------------
    
    @IBAction func swiped(sender: UIPanGestureRecognizer)
    {
        if (sender.state ==
            UIGestureRecognizerState.Ended)
        {
            var conditionOne = menu.hidden
            var conditionTwo = sender.velocityInView(self.view).x < 0
            var conditionThree = sender.velocityInView(self.view).x > 0
            
            if (conditionOne && conditionTwo || !conditionOne && conditionThree)
            {
                menu.toggleMenu(menu)
            }
            menu.toggleMenu(menu)
        }
    }
    
    @IBAction func menuButtonPressed(sender: AnyObject)
    {
        menu.toggleMenu(menu)
    }
    
}
