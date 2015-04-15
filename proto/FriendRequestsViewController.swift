//
//  FriendRequestsViewController.swift
//  proto
//
//  Created by Dan Morton on 4/12/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class FriendRequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    //connections from storyboard
    
    @IBOutlet weak var slideMenu: SlideMenu!//slide menu connection from storyboard
    
    @IBOutlet weak var requestsTableView: UITableView!
    

    var data = [PFUser]() // the data for the 'requestsTableView' for this viewcontroller
    
    //initialization code
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //menu configuration
        slideMenu.superViewController = self
        loadData()
    }
    
    //IBActions---------------------------------
    
    //this method wil fire when the user clicks the menu button in the navigation bar. It will toggle the nav panel
    @IBAction func menuButtonPressed(sender: AnyObject)
    {
        slideMenu.toggleMenu(slideMenu)
    }
    
    //this method will fire when the user pans for the menu. This will toggle the nav panel
    @IBAction func swipedForMenu(sender: AnyObject)
    {
        if (sender.state ==
            UIGestureRecognizerState.Ended)
        {
            var conditionOne = slideMenu.hidden
            var conditionTwo = sender.velocityInView(self.view).x < 0
            var conditionThree = sender.velocityInView(self.view).x > 0
            
            if (conditionOne && conditionTwo || !conditionOne && conditionThree)
            {
                slideMenu.toggleMenu(slideMenu)
            }
            slideMenu.toggleMenu(slideMenu)
        }

    }
    
    //tableViewConfigurations-------------------------------------------------------------------------
    
    //this UITableViewDataSouce method  will establish the number of rows, or entries, in the table view
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    //this UITableViewDataSource will configure each cell in the tableview
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if (!data.isEmpty)
        {
            var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "a")
            
            //get the info for this current data entry
            var username = data[indexPath.row].objectForKey("username") as! String
            var imageFile = data[indexPath.row].objectForKey("profile_picture") as! PFFile
            var image = appManager.convertPFFiletoUIImage(imageFile)
            
            cell.textLabel?.text = username
            cell.imageView?.image = image
            cell.imageView?.clipsToBounds = true
            cell.imageView?.layer.cornerRadius = 30
            
            cell.backgroundColor = UIColor.clearColor()
            return cell
            
        }
        return UITableViewCell()
    }
    
    //this UITableViewDelegate method will establish the height of each table view cell
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 70
    }
    
    //this UITableViewDelegate method will handle what happens when a user click on a TableView cell
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var alert = UIAlertController(title: "Required Action", message: "Decline or accept this friend request", preferredStyle: UIAlertControllerStyle.Alert)
        var acceptAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.acceptFriendRequest(indexPath.row)
        }
        var declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alert) -> Void in
            self.declineFriendRequest(indexPath.row)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    //Parse functions to load in data----------------------------------------------------------------------------------
    
    //this function loads all the data into the 'data' array, which is the data source for the 'requestsTableView'
    func loadData()
    {
        var query = PFQuery(className: "FriendsObject")
        
        var dataID = appManager.user.objectForKey("friendsDataID") as! String
        query.getObjectInBackgroundWithId(dataID, block: { (data, error) -> Void in
            if (error == nil)
            {
                var requests = data.objectForKey("friend_requests") as! [String]
                self.getFriendRequestUserInfo(requests)
            }
            else
            {
                println("error in step one")
            }
        })
    }
    
    //this will get all the requests that a user has
    func getFriendRequestUserInfo(requests:[String])
    {
        var query = PFUser.query()
        
        query.whereKey("objectId", containedIn: requests)
        query.findObjectsInBackgroundWithBlock { (d, error) -> Void in
            if (error != nil)
            {
                println("we have a problem")
            }
            else
            {
                self.data = d as! [PFUser]
                self.requestsTableView.reloadData()
                
            }
        }
    }
    
    //this is the first step to registering the two people as friends
    func acceptFriendRequest(atIndex:Int)
    {
        var fDIDOne = data[atIndex].objectForKey("friendsDataID") as! String
        var fDIDTwo = appManager.user.objectForKey("friendsDataID") as! String
        
        var query = PFQuery(className: "FriendsObject")
        query.getObjectInBackgroundWithId(fDIDOne, block: { (dat, error) -> Void in
            println("we are here")
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not complete request.", completion: nil)
            }
            else
            {
                var requests = dat.objectForKey("requested") as! [String]
                
                //remove the request from the use
                println("length \(requests.count)")
                for (var i = 0; i < requests.count; i++)
                {
                    var looking = requests[i]
                    if (looking == appManager.user.objectId)
                    {
                        println("Removing \(requests[i])")
                        requests.removeAtIndex(i)
                    }
                }
                
                var friends = dat.objectForKey("friends") as! [String]
                friends.append(appManager.user.objectId)
                
                var updatedObject = dat
                dat["requested"] = requests
                dat["friends"] = friends
                updatedObject.saveInBackgroundWithBlock({ (completion, error) -> Void in
                    if (!completion)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not complete request", completion: nil)
                    }
                    else
                    {
                        self.finishAcceptingFriendRequest(atIndex, fDIDTwo: fDIDTwo)
                    }
                })
            }
        })
        
        
    }
    
    //this is the second step to registering the two people as friendss
    func finishAcceptingFriendRequest(atIndex: Int, fDIDTwo:String)
    {
        var queryTwo = PFQuery(className: "FriendsObject")
        queryTwo.getObjectInBackgroundWithId(fDIDTwo, block: { (dat, error) -> Void in
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not complete request", completion: nil)
            }
            else
            {
                var friendRequests = dat.objectForKey("friend_requests") as! [String]
                
                for (var i = 0; i < friendRequests.count; i++)
                {
                    var looking = friendRequests[i]
                    if (looking == self.data[atIndex].objectId)
                    {
                        friendRequests.removeAtIndex(i)
                    }
                }
                var friends = dat.objectForKey("friends") as! [String]
                friends.append(self.data[atIndex].objectId)
                
                var updatedObject = dat
                updatedObject["friend_requests"] = friendRequests
                updatedObject["friends"] = friends
                updatedObject.saveInBackgroundWithBlock({ (completion, error) -> Void in
                    if (!completion)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not complete request", completion: nil)
                    }
                    else
                    {
                        appManager.displayAlert(self, title: "Success!", message: "You and \(self.data[atIndex].username) are now friends!", completion: nil)
                        self.notifyUserOfAcceptance(appManager.user.username, userName: self.data[atIndex].username)
                        
                        self.data.removeAtIndex(atIndex)
                        self.requestsTableView.reloadData()
                        
                    }
                })

            }
        })

    }
    
    //this is the first step to declining a user to be friends
    func declineFriendRequest(atIndex:Int)
    {
        var fDIDOne = data[atIndex].objectForKey("friendsDataID") as! String
        var fDIDTwo = appManager.user.objectForKey("friendsDataID") as! String
        
        var query = PFQuery(className: "FriendsObject")
        query.getObjectInBackgroundWithId(fDIDOne, block: { (dat, error) -> Void in
            println("we are here")
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not complete request.", completion: nil)
            }
            else
            {
                var requests = dat.objectForKey("requested") as! [String]
                for (var i = 0; i < requests.count; i++)
                {
                    var looking = requests[i]
                    if (looking == appManager.user.objectId)
                    {
                        println("Removing \(requests[i])")
                        requests.removeAtIndex(i)
                    }
                }
                
                var updatedObject = dat
                dat["requested"] = requests
                updatedObject.saveInBackgroundWithBlock({ (completion, error) -> Void in
                    if (!completion)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not complete request", completion: nil)
                    }
                    else
                    {
                        self.finishDecliningFriendRequest(atIndex, fDIDTwo: fDIDTwo)
                    }
                })
            }
        })

    }
    
    //this is the second step to decling a user to be friends.
    func finishDecliningFriendRequest(atIndex: Int, fDIDTwo:String)
    {
        var queryTwo = PFQuery(className: "FriendsObject")
        queryTwo.getObjectInBackgroundWithId(fDIDTwo, block: { (dat, error) -> Void in
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not complete request", completion: nil)
            }
            else
            {
                var friendRequests = dat.objectForKey("friend_requests") as! [String]
                
                for (var i = 0; i < friendRequests.count; i++)
                {
                    var looking = friendRequests[i]
                    if (looking == self.data[atIndex].objectId)
                    {
                        friendRequests.removeAtIndex(i)
                    }
                }
                
                var updatedObject = dat
                updatedObject["friend_requests"] = friendRequests
                updatedObject.saveInBackgroundWithBlock({ (completion, error) -> Void in
                    if (!completion)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not complete request", completion: nil)
                    }
                    else
                    {
                        appManager.displayAlert(self, title: "Success!", message: "You declined \(self.data[atIndex].username)", completion: nil)
                        self.data.removeAtIndex(atIndex)
                        self.requestsTableView.reloadData()
                    }
                })
                
            }
        })
        

    }
    
    func notifyUserOfAcceptance(id:String, userName:String)
    {
        var query = PFInstallation.query()
        query.whereKey("channels", containedIn: ["channel\(id)"])
        query.whereKey("deviceType", containedIn
            : ["ios"])
        let push = PFPush()
        push.setQuery(query)
        push.setMessage("\(userName) just accepted your friend Request!")
        push.sendPushInBackgroundWithBlock({ (completion, error) -> Void in
            if (error != nil)
            {
                appManager.displayAlert(self, title: "Error", message: "Could not notify user of friend request", completion: nil)
                
            }
        })
    }
}








