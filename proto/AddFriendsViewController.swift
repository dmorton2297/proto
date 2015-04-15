//
//  AddFriendsViewController.swift
//  proto
//
//  Created by Dan Morton on 3/10/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class AddFriendsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource
{
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! //connection from storyboard
    @IBOutlet weak var resultsTableView: UITableView!//connection from Storyboard
    
    var data = [PFUser]() //data for tableview
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        activityIndicator.hidden = true

    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        data = queryForUsers(textField.text)
        resultsTableView.reloadData()
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        return true
    }
    
    func queryForUsers(searchTerm:String)->[PFUser]
    {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        var query = PFUser.query()
        query.whereKey("username", containsString:searchTerm)
        var a = query.findObjects() as! [PFUser]
        return a
    }
    
    //UITableViewDataSource methods --------------------------------------------------
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if !data.isEmpty
        {
            var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "nothing")
            cell.textLabel?.text = data[indexPath.row].objectForKey("username") as? String
            cell.textLabel?.font = UIFont(name: "Avenir Next Demi Bold", size: 20)
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    //UITableViewDelegation methods -------------------------------------------------
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var friendsInfoForCurrentUser = appManager.getParseObject("FriendsObject", objectID: appManager.user.objectForKey("friendsDataID") as! String)
        var friendsInfoForRequested = appManager.getParseObject("FriendsObject", objectID: data[indexPath.row].objectForKey("friendsDataID") as! String)
        
        println(friendsInfoForCurrentUser.objectId)
        
        println(friendsInfoForRequested.objectId)
        
        var friendsArray = friendsInfoForCurrentUser.objectForKey("requested") as! [String]
        var requestsArray = friendsInfoForRequested.objectForKey("friend_requests") as! [String]
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        var user = data[indexPath.row]
        var username = user.objectForKey("username") as! String
        var alertController = UIAlertController(title: "Add friend", message: "Do you want to follow and friend \(username)?", preferredStyle: UIAlertControllerStyle.Alert)
        var alertAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) { (alert) -> Void in
            var newFriendEntry = self.data[indexPath.row].objectId
            var newRequestEntry = appManager.user.objectId
            
            var alreadyFriends = false
            for x in friendsArray
            {
                if x == newFriendEntry
                {
                    alreadyFriends = true
                    appManager.displayAlert(self, title: "Error", message: "You have already added this person", completion: nil)
                }
            }
            
            if !alreadyFriends
            {
                friendsArray.append(newFriendEntry)
                requestsArray.append(newRequestEntry)
                friendsInfoForCurrentUser["requested"] = friendsArray
                friendsInfoForRequested["friend_requests"] = requestsArray
                
                friendsInfoForRequested.saveInBackgroundWithBlock({ (success, error) -> Void in
                    if (success)
                    {
                        friendsInfoForCurrentUser.saveInBackgroundWithBlock({ (succ, error) -> Void in
                            if (succ)
                            {
                                appManager.displayAlert(self, title: "Success", message: "Your friend request has been sent", completion: nil)
                            }
                        })
                    }
                    
                })
                
                //push a notification to tell the requested that they have just been requested
                println("we made it here")
                var query = PFInstallation.query()
                query.whereKey("channels", containedIn: ["channel\(user.objectId)"])
                query.whereKey("deviceType", containedIn: ["ios"])
                let push = PFPush()
                push.setQuery(query)
                push.setMessage("\(appManager.user.username) just sent you a friend Request!")
                push.sendPushInBackgroundWithBlock({ (completion, error) -> Void in
                    if (error != nil)
                    {
                        appManager.displayAlert(self, title: "Error", message: "Could not notify user of friend request", completion: nil)
                        
                    }
                })
            }
        }
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alertController.addAction(alertAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        
        
    }
    
}
