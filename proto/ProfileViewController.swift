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
    @IBOutlet var backgroundImage: UIImageView! //background image connectino from UIStoryBoard
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
        
        //background blur
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.frame
        self.view.addSubview(blurView)
        self.view.sendSubviewToBack(blurView)
        self.view.sendSubviewToBack(backgroundImage)
        
        //ProfilePicture styling-----------------
        profilePicture.clipsToBounds = true
        profilePicture.layer.cornerRadius = 10
        
        //load the profile picture if the user has one
        var profilePictureFile = appManager.user.objectForKey("profile_picture") as! PFFile
        var image = appManager.convertPFFiletoUIImage(profilePictureFile)
        
        profilePicture.image = image
        
        
    }
    
    override func viewDidAppear(animated: Bool)
    {
        //load the profile picture if the user has one (this is just to ensure that it is loaded
        var profilePictureFile = appManager.user.objectForKey("profile_picture") as! PFFile
        var image = appManager.convertPFFiletoUIImage(profilePictureFile)
        
        profilePicture.image = image
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
    
}
