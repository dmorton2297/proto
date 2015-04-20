//
//  ProfileViewController.swift
//  proto
//
//  Created by Dan Morton on 3/13/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet var slideMenu: SlideMenu! //connection from UIStoryboard
    @IBOutlet var profilePicture: UIImageView! //Profile picture connection from UIStoryBoard
    var chosenProfileImage : UIImage! //This will be used when setting a new profile picture
    
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //slide menu configuration
        slideMenu.superViewController = self

        
        //configure the imagPicker
        imagePicker.delegate = self
        
        
        //ProfilePicture styling-----------------
        profilePicture.clipsToBounds = true
        profilePicture.layer.cornerRadius = 10
        
        
        loadProfilePicture()
        
        
    }
    
    
    //IBActions--------------------------
    
    @IBAction func swiped(sender: AnyObject)
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
    
    //toggle the slide menu
    @IBAction func menuButtonPressed(sender: AnyObject)
    {
        slideMenu.toggleMenu(slideMenu)
    }
    
    //present the option to change your profile picture
    @IBAction func changeProfilePictureButtonPressed(sender: AnyObject)
    {
        //self.dismissViewControllerAnimated(true, completion: nil)
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!)
    {
        println("this ran")
        imagePicker.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.chosenProfileImage = image
            self.performSegueWithIdentifier("editPicture", sender: self)
        })
        
    }
    
    //Segue configurations--------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        var dvc = segue.destinationViewController as! EditPictureViewController
        dvc.image = chosenProfileImage
    }
    
    func loadProfilePicture()
    {
        //load the profile picture if the user has one
        var profilePictureFile = appManager.user.objectForKey("profile_picture") as! PFFile
        
        profilePictureFile.getDataInBackgroundWithBlock { (dat, error) -> Void in
            if (error == nil)
            {
                self.profilePicture.image = UIImage(data: dat)
            }
            else
            {
                appManager.displayAlert(self, title: "Error", message: "Could not retrieve profile picture.", completion: nil)
            }
        
        }
    }
    
}
