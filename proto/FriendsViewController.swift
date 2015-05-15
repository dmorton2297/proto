//
//  FriendsViewController.swift
//  proto
//
//  Created by Dan Morton on 3/2/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{

    var images = [UIImage]()
    
    @IBOutlet weak var friendsTableView: UITableView!
    var data = [PFUser]()
    var tableViewData = Dictionary<String, [PFUser]>()
    let sectionTitles = ["Recently Updated", "Friends"]
    var updateTimes = [NSDate]() //Parallel array to te data array. This is used to notify when a friend has uploaded a new image.
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //menu setup----------------
    }
    
    override func viewDidAppear(animated: Bool)
    {
        
        self.loadTableViewData()
    }
    
    //IBActions from storyboard-------------------
    
    //UITableViewDataSource methods------------------------------
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if (updateTimes.count != data.count){println("Parallel arrays are error")}
        
        if (!data.isEmpty)
        {
            var cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "b")
            
            var username = data[indexPath.row].username
            
            cell.textLabel?.text = username
            cell.imageView?.image = images[indexPath.row]
            cell.imageView?.clipsToBounds = true
            cell.imageView?.layer.cornerRadius = 30
            
            cell.backgroundColor = UIColor.clearColor()
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            //check the local data store for the last time this user viewed this friend
            var query = PFQuery(className: "FriendsInfo")
            query.fromLocalDatastore()
            query.whereKey("Name", equalTo: "fInfo")
            query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
                if (error == nil && object != nil)
                {
                    var check = object[self.data[indexPath.row].username] as?
                    NSObject
                    if (check == nil)
                    {
                        cell.detailTextLabel?.text = "New"
                        cell.detailTextLabel?.textColor = UIColor.redColor()
                    }
                    else
                    {
                        var date = check as! NSDate
                        if (date.timeIntervalSinceDate(self.updateTimes[indexPath.row]) < 0)
                        {
                            cell.detailTextLabel?.text = "New"
                            cell.detailTextLabel?.textColor = UIColor.redColor()
                        }
                    }
                }
            }

            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 70
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        //add the current time to the local data store
        var query = PFQuery(className: "FriendsInfo")
        query.fromLocalDatastore()
        query.whereKey("Name", equalTo: "fInfo")
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if (error == nil && object != nil)
            {
                var newObject = object
                println(indexPath.row)
                newObject[self.data[indexPath.row].username] = NSDate()
                newObject.pinInBackgroundWithBlock({ (completion, error) -> Void in
                    if (completion)
                    {
                        println("new date recorded.")
                    }
                    
                })
            }
        }
        
        self.performSegueWithIdentifier("showFriendsFeed", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        
        if (editingStyle == UITableViewCellEditingStyle.Delete)
        {
            
            var userFriendsID = appManager.user.objectForKey("friendsDataID") as! String
            var toBeUnfriendedFriendsID = data[indexPath.row].objectForKey("friendsDataID") as! String
            var toBeUnfriendedID = data[indexPath.row].objectId
            
            self.data.removeAtIndex(indexPath.row)
            self.images.removeAtIndex(indexPath.row)
            updateTimes.removeAtIndex(indexPath.row)
            self.friendsTableView.reloadData()
            

            var query = PFQuery(className: "FriendsObject")
            query.getObjectInBackgroundWithId(userFriendsID, block: { (object, error) -> Void in
                if (error == nil && object != nil)
                {
                    var friendsList = object.objectForKey("friends") as! [String]
                    for (var i = 0; i < friendsList.count; i++)
                    {
                        var x = friendsList[i]
                        if (x == toBeUnfriendedID)
                        {
                            var a = friendsList.removeAtIndex(i)
                            
                            println("removeing \(a)")
                            var newObject = object
                            newObject["friends"] = friendsList
                            for x in friendsList
                            {
                                println(x)
                            }
                            newObject.saveInBackgroundWithBlock { (completion, error) -> Void in
                                if (error == nil)
                                {
                                    println("We are good")
                                    self.finishUnfriendingUser(toBeUnfriendedFriendsID, dataIndex: indexPath.row)
                                }
                            }
                        }
                    }
                    
                    
                }
                else
                {
                    appManager.displayAlert(self, title: "Error", message: "Could not unfriend user.", completion: nil)
                }
            })
            
        }
    }

    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return ""
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Unfriend"
    }
    //Parse methods--------------------------------------------------------------------------------------------
    
    func finishUnfriendingUser(userFriendId: String, dataIndex: Int)
    {
        
        println(userFriendId)
        var query = PFQuery(className: "FriendsObject")
        query.getObjectInBackgroundWithId(userFriendId, block: { (object, error) -> Void in
            if (error == nil && object != nil)
            {
                println("we are good 2")
                var friendsList = object.objectForKey("friends") as! [String]
                for (var i = 0; i < friendsList.count; i++)
                {
                    var x = friendsList[i]
                    if (x == appManager.user.objectId)
                    {
                        friendsList.removeAtIndex(i)
                        var newObject = object
                        newObject["friends"] = friendsList
                        newObject.saveInBackgroundWithBlock { (completion, error) -> Void in
                            appManager.displayAlert(self, title: "Success!", message: "User unfriended.", completion: nil)
                            
                        }
                    }
                }
                
                
                
                
            }
            else
            {
                appManager.displayAlert(self, title: "Error", message: "Could not unfriend user.", completion: nil)
            }
        })
        
    }
    //load all the users information into the 'data' array
    func loadTableViewData()
    {
        var query = PFQuery(className: "FriendsObject")
        
        var dataID = appManager.user.objectForKey("friendsDataID") as! String
        query.getObjectInBackgroundWithId(dataID, block: { (data, error) -> Void in
            if (error == nil)
            {
                var friends = data.objectForKey("friends") as! [String]
                self.finishLoadingTableViewData(friends)
                
            }
            else
            {
                println("error in step one")
            }
        })
    }
    
    //the second step to loading the table view data
    func finishLoadingTableViewData(dataIds:[String])
    {
        var query = PFUser.query()
        
        query.whereKey("objectId", containedIn: dataIds)
        query.findObjectsInBackgroundWithBlock { (d, error) -> Void in
            if (error != nil)
            {
                println("we have a problem")
            }
            else
            {
                self.data.removeAll(keepCapacity: false)
                self.data = d as! [PFUser]
                self.loadUsersPhotos()
            }
        }
    }
    
    
    func loadUsersPhotos()
    {
        var unsortedArray = [(UIImage, Int)]()
        for (var i = 0; i < data.count; i++)
        {
            var x = data[i]
            var temp = i
            var pictureFile =  x.objectForKey("profile_picture") as! PFFile
            pictureFile.getDataInBackgroundWithBlock({ (dat, error) -> Void in
                var image = UIImage(data: dat)
                unsortedArray.append((image!, temp))
                
                if (unsortedArray.count == self.data.count)
                {
                    self.sortImageArray(unsortedArray)
                }
            })
        }
    }
    
    func sortImageArray(unsortedArray:[(UIImage, Int)])
    {
        for (var i = 0; i < unsortedArray.count; i++)
        {
            for x in unsortedArray
            {
                if (x.1 == i)
                {
                    images.append(x.0)
                }
            }
        }
        
        loadUpdateDates()
    }
    
    func loadUpdateDates()
    {
        updateTimes.removeAll(keepCapacity: false)
        for (var i = 0; i < data.count; i++)
        {
            var x = data[i]
            var date = x.objectForKey("lastPostedTime") as! NSDate
            updateTimes.append(date)
        }
        
        friendsTableView.reloadData()
    }
    
    //segue configurations------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if (segue.identifier == "showFriendsFeed")
        {
            var dvc = segue.destinationViewController as! FriendsFeedViewController
            
            println("CHECK \(friendsTableView.indexPathForSelectedRow()!.row) and size of array = \(data.count)")
            dvc.user = data[friendsTableView.indexPathForSelectedRow()!.row]
        }
    }
}
