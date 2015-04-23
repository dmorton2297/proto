//
//  FriendsFeedViewController.swift
//  proto
//
//  Created by Dan Morton on 4/13/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class FriendsFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var entryTableView: UITableView!//Connection to the main tableview in xcode
    @IBOutlet weak var profilePicture: UIImageView! //connection to the profile pictur imageview in storyboard
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!//connection to the activity indicator in storyboard
    @IBOutlet weak var userLabel: UILabel! //connection to the users label in storyboard
    
    var user : PFUser! //this will be passed over in a prepare for segueMethod in FriendsViewController. The owner of the feed were looking at
    
    var data = [PictureEntry]()
    
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
        println(data.count)
        if (!data.isEmpty)
        {
            var cell = tableView.dequeueReusableCellWithIdentifier("recentLocCell") as! PictureEntryTableViewCell
            
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
            
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, entryTableView.frame.width, 100)
            
            
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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //Parse functions-------------------------------------------------------------------------------------------------------------------------------
    
    func loadTableViewData()
    {
        var query = PFQuery(className: "UserData")
        var dataID = user.objectForKey("dataID") as! String
        query.getObjectInBackgroundWithId(dataID, block: { (dat, error) -> Void in
            if (error == nil)
            {
                var locationNames = dat.objectForKey("location_names") as! [String]
                var locationCoordinates = dat.objectForKey("location_coordinates") as! [String]
                var pointWorths = dat.objectForKey("point_worth") as! [NSObject]
                var imageFiles = dat.objectForKey("images") as! [PFFile]
                
                
                if (locationNames.count == 0)
                {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.hidden = true
                    return
                }
                
                var unsortedPosts = [(PictureEntry, Int)]()
                for (var i = 0; i < locationNames.count; i++)
                {
                    let imageFile = imageFiles[i]
                    var temp = i
                    imageFile.getDataInBackgroundWithBlock({ (data, error) -> Void in
                        let name = locationNames[temp]
                        let pointWorth = pointWorths[temp]as! NSInteger
                        let coordinates = CLLocation(latitude: 100, longitude: 500)
                        var image = UIImage(data: data)
                        if (image == nil){image = UIImage(named: "friendsIcon")}
                        let entry = PictureEntry(image: image!, name: name, location: coordinates, pointWorth: pointWorth, locationName: "temp")
                        
                        let geocoder = CLGeocoder()
                        
                        unsortedPosts.append((entry, temp))
                        
                        if (unsortedPosts.count == locationNames.count)
                        {
                            self.sortInfoIntoTableView(unsortedPosts)
                        }
                    })

                }
            }
            else
            {
                println("we encounterd an error")
            }
            
            
        })

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


    
    
    
}
