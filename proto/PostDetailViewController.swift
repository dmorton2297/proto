//
//  PostDetailViewController.swift
//  proto
//
//  Created by Dan Morton on 4/27/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class PostDetailViewController: UIViewController {
    
    var post : PictureEntry!//this will be populated upon the instantiation of this view controller
    
    var user : PFUser!//this will be populated upon instantiation of this class
    
    var presentView : HomeViewController!
    
    var index : Int!
    
    @IBOutlet weak var postImageView: UIImageView! //image view connection from storybaord. will load image from post into this view.
    
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //configure stylingsettings for the imageview
        postImageView.contentMode = UIViewContentMode.ScaleAspectFit
        postImageView.clipsToBounds = true
        postImageView.layer.cornerRadius = 10
        
        postImageView.image = post.image
        
        //label configurations
        userNameLabel.text = user.username
        
        locationLabel.text = post.locationName
        
        mapButton.clipsToBounds = true
        mapButton.layer.cornerRadius = 10
        
        dateLabel.text = toStringOfAbbrevMonthDayAndTime(post.date)
        
        
    }
    
    func toStringOfAbbrevMonthDayAndTime(date:NSDate) -> String
    {
        //convert to regular looking time
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, hh:mm aa"
        return dateFormatter.stringFromDate(date)
    }
    
    @IBAction func infoButtonPressed(sender: AnyObject)
    {
        var alert = UIAlertController(title: "Options", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        var deleteAction = UIAlertAction(title: "Delete Post", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.beginDeletingPost()
        }
        
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func beginDeletingPost()
    {
        var alert = UIAlertController(title: "Confirm", message: "Are you sure you want to delete this post?", preferredStyle: UIAlertControllerStyle.Alert)
        
        var deleteAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.finishDeletingPost()
        }
        
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func finishDeletingPost()
    {
        let query = PFQuery(className: "UserData")
        let datObjectID = appManager.user.objectForKey("dataID") as! String
        
        query.getObjectInBackgroundWithId(datObjectID, block: { (result, error) -> Void in
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not delete post.", completion: nil)
            }
            else
            {
                var imageFiles = result.objectForKey("images") as! [PFFile]
                var locationCoordinates = result.objectForKey("location_coordinates") as! [String]
                var locationNames = result.objectForKey("location_names") as! [String]
                var dates = result.objectForKey("dates") as! [NSDate]
                var pointWorths = result.objectForKey("point_worth") as! [Int]
                
                
                imageFiles.removeAtIndex(self.index)
                locationCoordinates.removeAtIndex(self.index)
                locationNames.removeAtIndex(self.index)
                dates.removeAtIndex(self.index)
                pointWorths.removeAtIndex(self.index)
                
                var updatedObject = result
                
                updatedObject["images"] = imageFiles
                updatedObject["location_coordinates"] = locationCoordinates
                updatedObject["location_names"] = locationNames
                updatedObject["dates"] = dates
                updatedObject["point_worth"] = pointWorths
                
                updatedObject.saveInBackgroundWithBlock({ (test, error) -> Void in
                    if (error != nil)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not delete post.", completion: nil)
                    }
                    else
                    {
                       self.presentView.data.removeAtIndex(self.index)
                    self.presentView.postsTableView.reloadData()
                        
                        appManager.displayAlert(self, title: "Success", message: "Post deleted.", completion: { (action) -> Void in
                            //self.dismissViewControllerAnimated(true, completion: nil)
                        })
                    }
                })
            }
        })
    }
}
