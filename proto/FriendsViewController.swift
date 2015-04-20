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

    @IBOutlet var menu: SlideMenu!
    
    var images = [UIImage]()
    
    @IBOutlet weak var friendsTableView: UITableView!
    var data = [PFUser]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //menu setup----------------
        menu.superViewController = self

        
        self.loadTableViewData()

    }
    
    //IBActions from storyboard-------------------
    

    @IBAction func swiped(sender: AnyObject)
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
    
    //UITableViewDataSource methods------------------------------
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if (!data.isEmpty)
        {
            var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "b")
            
            var username = data[indexPath.row].username
            
            cell.textLabel?.text = username
            cell.imageView?.image = images[indexPath.row]
            cell.imageView?.clipsToBounds = true
            cell.imageView?.layer.cornerRadius = 30
            
            cell.backgroundColor = UIColor.clearColor()
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
        self.performSegueWithIdentifier("showFriendsFeed", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    //Parse methods--------------------------------------------------------------------------------------------
    
    
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
        
        friendsTableView.reloadData()
    }
    
    //segue configurations------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if (segue.identifier == "showFriendsFeed")
        {
            var dvc = segue.destinationViewController as! FriendsFeedViewController
            dvc.user = data[friendsTableView.indexPathForSelectedRow()!.row]
        }
    }
}
