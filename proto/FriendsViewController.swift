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

   // var images = [UIImage]()
    
    @IBOutlet weak var friendsTableView: UITableView!
    var userArray = [PFUser]()
    var data = [(PFUser, UIImage)]()
    var tableViewData = Dictionary<Int, [(PFUser, UIImage)]>()
    let sectionTitles = ["Recently Updated", "Friends"]
    var sections = ["Recently Updated", "Friends"]
    var updateTimes = [NSDate]() //Parallel array to te data array. This is used to notify when a friend has uploaded a new image.
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //menu setup----------------
    }
    
    override func viewDidAppear(animated: Bool)
    {
        data.removeAll(keepCapacity: false)
        self.loadTableViewData()
    }
    
    //IBActions from storyboard-------------------
    
    //UITableViewDataSource methods------------------------------
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //return tableViewData["\(section)"]!.count
        if (tableViewData.isEmpty)
        {
            return 0
        }
        else
        {
            return tableViewData[section]!.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if (updateTimes.count != data.count){println("Parallel arrays are error")}
        
        if (!tableViewData.isEmpty)
        {
            var dat = tableViewData[indexPath.section]!
            var cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "b")
            var user = dat[indexPath.row].0
            var image = dat[indexPath.row].1
            var username = user.username
            
            cell.textLabel?.text = username
            cell.imageView?.image = image
            cell.imageView?.clipsToBounds = true
            cell.imageView?.layer.cornerRadius = 30
            
            cell.backgroundColor = UIColor.clearColor()
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
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
                var username = self.tableViewData[indexPath.section]![indexPath.row].0.username
                newObject[username] = NSDate()
                newObject.pinInBackgroundWithBlock({ (completion, error) -> Void in
                    if (error != nil)
                    {
                        println(error)
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
            
            var allUsers = self.tableViewData[indexPath.section]!
            var selectedUser = allUsers[indexPath.row].0
            
            var userFriendsID = appManager.user.objectForKey("friendsDataID") as! String
            var toBeUnfriendedFriendsID = selectedUser.objectForKey("friendsDataID") as! String
            var toBeUnfriendedID = selectedUser.objectId
            
          //  self.data.removeAtIndex(indexPath.row)
            self.tableViewData[indexPath.section]?.removeAtIndex(indexPath.row)
            //self.images.removeAtIndex(indexPath.row)
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
                            
                            var newObject = object
                            newObject["friends"] = friendsList
                            newObject.saveInBackgroundWithBlock { (completion, error) -> Void in
                                if (error == nil)
                                {
                                    self.finishUnfriendingUser(toBeUnfriendedFriendsID, dataIndex: indexPath.row)
                                }
                                else
                                {
                                    appManager.displayAlert(self, title: "Error", message: "Could not unfriend user.", completion: nil)
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
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return sections[section]
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Unfriend"
    }
    //Parse methods--------------------------------------------------------------------------------------------
    
    func finishUnfriendingUser(userFriendId: String, dataIndex: Int)
    {
        
        var query = PFQuery(className: "FriendsObject")
        query.getObjectInBackgroundWithId(userFriendId, block: { (object, error) -> Void in
            if (error == nil && object != nil)
            {
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
                appManager.displayAlert(self, title: "Error", message: "Could not retrieve data.", completion: nil)
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
                appManager.displayAlert(self, title: "Error", message: "Could not retrieve data.", completion: nil)
            }
            else
            {
                self.data.removeAll(keepCapacity: false)
                self.userArray = d as! [PFUser]
                self.loadUsersPhotos()
            }
        }
    }
    
    
    func loadUsersPhotos()
    {
        var unsortedArray = [(UIImage, Int)]()
        for (var i = 0; i < userArray.count; i++)
        {
            var x = userArray[i]
            var temp = i
            var pictureFile =  x.objectForKey("profile_picture") as! PFFile
            pictureFile.getDataInBackgroundWithBlock({ (dat, error) -> Void in
                var image = UIImage(data: dat)
                self.data.append((x, image!))
                
                if (temp == self.userArray.count-1)
                {
                    self.loadUpdateDates()
                    
                }
            })
        }
    }
    
    func loadUpdateDates()
    {
        var updatedUsers = [(PFUser, UIImage)]()
        updateTimes.removeAll(keepCapacity: false)
        
        var completionCounter = 0
        for (var i = 0; i < data.count; i++)
        {
            var x = data[i]
            var date = x.0.objectForKey("lastPostedTime") as! NSDate
            updateTimes.append(date)
            
            var tempIndex = i
            
            var query = PFQuery(className: "FriendsInfo")
            query.fromLocalDatastore()
            query.whereKey("Name", equalTo: "fInfo")
            query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
                if (error == nil && object != nil)
                {
                    var check = object[self.data[tempIndex].0.username] as?
                    NSObject
                    if (check == nil)
                    {
                        updatedUsers.append(self.data[tempIndex])
                    }
                    else
                    {
                        var date = check as! NSDate
                        if (date.timeIntervalSinceDate(self.updateTimes[tempIndex]) < 0)
                        {
                            updatedUsers.append(self.data[tempIndex])
                        }
                    }
                }
                completionCounter++
                
                if (completionCounter == self.userArray.count)
                {
                    self.tableViewData[1] = self.data
                    self.tableViewData[0] = updatedUsers
                    self.friendsTableView.reloadData()
                }
            }

        }
        
        
        
        //friendsTableView.reloadData()
    }
    
    //segue configurations------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if (segue.identifier == "showFriendsFeed")
        {
            var dvc = segue.destinationViewController as! FriendsFeedViewController
            
            var indexPath = friendsTableView.indexPathForSelectedRow()!
            dvc.user = tableViewData[indexPath.section]![indexPath.row].0
        }
    }
}
