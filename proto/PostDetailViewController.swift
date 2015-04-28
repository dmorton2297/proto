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
}
