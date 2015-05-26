//
//  FriendsFeedViewController.swift
//  proto
//
//  Created by Dan Morton on 4/13/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class FriendsFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var entryTableView: UITableView!//Connection to the main tableview in xcode
    @IBOutlet weak var profilePicture: UIImageView! //connection to the profile pictur imageview in storyboard
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!//connection to the activity indicator in storyboard
    @IBOutlet weak var userLabel: UILabel! //connection to the users label in storyboard
    
    var user : PFUser! //this will be passed over in a prepare for segueMethod in FriendsViewController. The owner of the feed were looking at
    var data = [PictureEntry]() //contains all the data to the table view
    var likes = [Bool]() //parallel array to data to check if you liked that post
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //style the label
        userLabel.text = user.username
        
        loadTableViewData()
        loadProfilePicture()
    }
    
    //tableview data source methods---------------------------------------------------------------------------------------------------
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if (!data.isEmpty)
        {
            var cell = tableView.dequeueReusableCellWithIdentifier("recentLocCell") as! PictureEntryTableViewCell
            
            cell.locationTextLabel.text = data[indexPath.row].caption
            
            //getting coorinates of this specific picture entry
            cell.coordinatesTextLabel.text = data[indexPath.row].locality
            
            //setting the image thumbnail in the cell
            cell.selfieImageView.clipsToBounds = true
            cell.selfieImageView.image = data[indexPath.row].image
            cell.selfieImageView.layer.cornerRadius = 5
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, entryTableView.frame.width, 100)
            
            cell.likeButton.tag = indexPath.row
            
            if (data[indexPath.row].liked)
            {
                cell.likeButton.setImage(UIImage(named: "likeButtonEnabled"), forState: UIControlState.Normal)
            }
            else
            {
                cell.likeButton.setImage(UIImage(named: "likeButtonDisabled"), forState: UIControlState.Normal)
            }
            
            if (data[indexPath.row].likes.count != 0)
            {
                cell.likeCountLabel.text = "\(data[indexPath.row].likes.count)"
            }
            else
            {
                cell.likeCountLabel.text = ""
            }
            
            
            
            return cell
            
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        //calculate the new height of the cell view
        var scale = data[indexPath.row].image.size.width / entryTableView.frame.width
        var height = data[indexPath.row].image.size.height/scale
        
        return height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.performSegueWithIdentifier("detail2", sender: self)
    }
    
    @IBAction func likeButtonPressed(sender: UIButton)
    {
        var unliking = false //boolean flag used to check if the post is being liked or unliked.
        
        if (sender.imageForState(UIControlState.Normal) == UIImage(named: "likeButtonEnabled"))
        {
            self.data[sender.tag].liked = false
            for (var i = 0; i < self.data[sender.tag].likes.count; i++)
            {
                var x = self.data[sender.tag].likes[i]
                if (x == appManager.user.objectId)
                {
                    self.data[sender.tag].likes.removeAtIndex(i)
                }
            }
            unliking = true
        }
        else
        {
            self.data[sender.tag].liked = true
            self.data[sender.tag].likes.append(appManager.user.objectId)
        }
        entryTableView.reloadData()
        var entry = data[sender.tag] //this will get the data that the user just "liked"
        let posts = user.objectForKey("image_posts") as! [String]
        
        if (sender.tag > posts.count){return} //check to see if there is a data entry at that point
        
        
        var postID = posts[sender.tag]
        
        let query = PFQuery(className: "ImagePost")
        query.getObjectInBackgroundWithId(postID, block: { (object, error) -> Void in
            if (error == nil && object != nil)
            {
                var likes = object.objectForKey("likes") as! [String]
                var newObject = object
                if (!unliking)
                {
                    likes.append(appManager.user.objectId)
                    self.data[sender.tag].liked = true
                    
                }
                else
                {
                    for (var i = 0; i < likes.count; i++)
                    {
                        if (likes[i] == appManager.user.objectId)
                        {
                            likes.removeAtIndex(i)
                        }
                        self.data[sender.tag].liked = false
                    }
                }
                
                
                newObject["likes"] = likes
                newObject.saveInBackgroundWithBlock { (completion, error) -> Void in
                    if (error != nil)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not like image.", completion: nil)
                        sender.setImage(UIImage(named: "likeButtonDisabled"), forState: UIControlState.Normal)
                    }
                }
                
                
            }
            else
            {
                appManager.displayAlert(self, title: "Error", message: "Could not like image.", completion: nil)
                sender.setImage(UIImage(named: "likeButtonDisabled"), forState: UIControlState.Normal)
            }
        })
        
    }
    
    
    //Parse functions-------------------------------------------------------------------------------------------------------------------------------
    
    func loadTableViewData()
    {
        var data = user.objectForKey("image_posts") as! [NSString]
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
                    
                    //load all the information into the data array
                    var imageFile = object.objectForKey("image") as! PFFile
                    var caption = object.objectForKey("caption") as! String
                    var likes = object.objectForKey("likes") as! [String]
                    var coordinatesString = object.objectForKey("coordinates") as! String
                    var date = object.objectForKey("date") as! NSDate
                    var pointWorth = object.objectForKey("point_worth") as! Int
                    var coordinates = self.getLocationFromString(coordinatesString)
                    var liked = false
                    //check to see if you liked this image
                    
                    for x in likes
                    {
                        if (x == appManager.user.objectId)
                        {
                            liked = true
                        }
                    }
                    
                    imageFile.getDataInBackgroundWithBlock { (picture, error) -> Void in
                        geocoder.reverseGeocodeLocation(coordinates, completionHandler: { (results, error) -> Void in
                            if (error == nil && results != nil)
                            {
                                if (results.count >= 0)
                                {
                                    let placemark = results[0] as! CLPlacemark
                                    var entry = PictureEntry(image: UIImage(data: picture)!, caption: caption, location: coordinates, pointWorth: pointWorth, locality: placemark.locality, date:date, liked: liked, likes: likes)
                                    unsortedArray.append((entry, tempIndex))
                                    completionCounter++
                                    if (completionCounter == data.count){self.sortInfoIntoTableView(unsortedArray)}
                                }
                            }
                            else
                            {
                                println(error)
                            }
                        })
                    }
                }
                else
                {
                    println(error)
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
        for (var i = 0; i < dat.count; i++)
        {
            for y in dat
            {
                if (y.1 == i)
                {
                    data.append(y.0)
                }
            }
        }
        
        entryTableView.reloadData()
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }
    
    func loadProfilePicture()
    {
        let profilePictureFile = user.objectForKey("profile_picture")as! PFFile
        
        profilePictureFile.getDataInBackgroundWithBlock { (dat, error) -> Void in
            var image = UIImage(data: dat)
            if (image == nil){image = UIImage(named: "friendsIcon")}
            self.profilePicture.image = image
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var dvc = segue.destinationViewController as! PostDetailViewController
        dvc.location = data[entryTableView.indexPathForSelectedRow()!.row].location
        
        entryTableView.deselectRowAtIndexPath(entryTableView.indexPathForSelectedRow()!, animated: true)
        
    }
    
    
    
}
