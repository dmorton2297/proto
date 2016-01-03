//
//  SlideMenu.swift
//  SlideInMenu
//
//  Created by Dan Morton on 3/2/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class SlideMenu: UIView, UITableViewDelegate, UITableViewDataSource{
    
    var open = false
    @IBOutlet var table: UITableView!
    @IBOutlet var menu: UIView! //view for the slide menu
    
    var superViewController: UIViewController!
    
    var menus = ["Home", "Friends", "Friend Requests", "My Profile", "Logout"]
    
    var images = [UIImage(named: "homeIcon"), UIImage(named: "friendsIcon"), UIImage(named: "friendsIcon"), UIImage(named:"friendsIcon"), UIImage(named: "Logout")]
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
        
        NSBundle.mainBundle().loadNibNamed("SlideMenu", owner: self, options: nil)
        
        self.autoresizesSubviews = true
        menu.autoresizesSubviews = true
        
        menu.frame = self.bounds
        table.frame = menu.bounds
        
        menu.updateConstraints()
        //self.alpha = 1
        self.hidden = true
        self.addSubview(menu)
    }
    
    @IBAction func swipeOut(sender: AnyObject) {
        toggleMenu(self)
    }
    
    
    func toggleMenu(superView:UIView)
    {
        
        if (open)
        {
            UIView.animateWithDuration(0.1){
                self.alpha = 0
            }
            self.hidden = true
            open = false
        }
        else
        {
            self.hidden = false
            UIView.animateWithDuration(0.1){
                self.alpha = 1.0
            }
            open = true
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "nothing")
        cell.textLabel?.font = UIFont(name: "Arial", size: 20)
        cell.textLabel?.text = menus[indexPath.row]
        cell.backgroundColor = UIColor.lightTextColor()
        cell.imageView?.image = images[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
        if (indexPath.row == 0)
        {
            var storyBoard = UIStoryboard(name: "Mainn", bundle: NSBundle.mainBundle())
            var a = storyBoard.instantiateViewControllerWithIdentifier("home") as! UINavigationController
            superViewController.presentViewController(a, animated: true, completion: nil)
            
        }
        else if (indexPath.row == 1)
        {
            var storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            var a = storyBoard.instantiateViewControllerWithIdentifier("friends")as! UINavigationController
            superViewController.presentViewController(a, animated: true, completion: nil)
        }
        else if (indexPath.row == 2)
        {
            var storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            var a = storyBoard.instantiateViewControllerWithIdentifier("friendRequests") as! UIViewController
            superViewController.presentViewController(a, animated: true, completion: nil)

        }
        else if (indexPath.row == 3)
        {
            var storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            var a = storyBoard.instantiateViewControllerWithIdentifier("ProfileViewController") as! UIViewController
            superViewController.presentViewController(a, animated: true, completion: nil)
        }
        else if (indexPath.row == 4)
        {
            PFUser.logOut()
            var storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            var a = storyBoard.instantiateViewControllerWithIdentifier("loginViewController")as! UIViewController
            superViewController.presentViewController(a, animated: true, completion: nil)
        }
    }
    
}
