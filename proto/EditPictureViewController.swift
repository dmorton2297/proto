//
//  EditPictureViewController.swift
//  proto
//
//  Created by Dan Morton on 4/2/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import AVFoundation

class EditPictureViewController: UIViewController {
    
    var image : UIImage! //this is the users preferred profile picture that will be passed over in segue from "profileViewController"
    var originalImageFrame : CGRect! //will be defined when the view loads
    
    @IBOutlet weak var croppingView: UIView!
    
    @IBOutlet var imageView: UIImageView! //the image view that contains the image taken by the suer
    
    
    
    
    //setup that will occur when the view loads
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imageView.contentMode = .ScaleAspectFit
        imageView.image = image
    }
    //IBActions-----------------------------------------------------------------
    
    //Action will fire when the user drags there finger across the screen. This will move the image
    @IBAction func userDragged(sender: AnyObject)
    {
        
        var recognizer = sender as! UIPanGestureRecognizer
        var delX = recognizer.velocityInView(self.view).x/70
        var delY = recognizer.velocityInView(self.view).y/70
        imageView.center = CGPointMake(imageView.center.x + delX, imageView.center.y + delY)
        
    }

    //action that will run when the user presses the "done" button
    @IBAction func done(sender: AnyObject)
    {
        println("This ran")
        saveImage()
    }
    
    //action that will run when the uzer pinches to zoom
    @IBAction func userPinched(sender: UIPinchGestureRecognizer)
    {

        if (sender.velocity < 0)
        {
            if (imageView.frame.height > 100 || imageView.frame.width > 100)
            {
            
            var delX = ((imageView.frame.width * 0.97) - imageView.frame.width)/2
            var delY = ((imageView.frame.height * 0.97) - imageView.frame.height)/2
            //println("\(delX), \(delY)")
            imageView.frame = CGRectMake((imageView.frame.origin.x-delX), (imageView.frame.origin.y-delY), imageView.frame.width*0.97, imageView.frame.height*0.97)
            }
        }
        else
        {
            var delX = ((imageView.frame.width / 0.97) - imageView.frame.width)/2
            var delY = ((imageView.frame.height / 0.97) - imageView.frame.height)/2
          //  println("\(delX), \(delY)")
            imageView.frame = CGRectMake((imageView.frame.origin.x-delX), (imageView.frame.origin.y-delY), imageView.frame.width/0.97, imageView.frame.height/0.97)
            
        }
    }
    
    func saveImage()
    {
        
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, false, UIScreen.mainScreen().scale) //scale it correctly for the retina display
        view.layer.renderInContext(UIGraphicsGetCurrentContext())
        let simage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()

        var scale = simage.scale
        var squareLength = croppingView.frame.width
        var clippedRect = CGRectMake(croppingView.frame.origin.x*scale, croppingView.frame.origin.y*scale, squareLength*scale, squareLength*scale)
        var imageRef = CGImageCreateWithImageInRect(simage.CGImage, clippedRect)
        var img = UIImage(CGImage: imageRef)
        
        var a = appManager.convertUIImageToPFFile(img!)
        
        appManager.user["profile_picture"] = a
        appManager.user.saveInBackgroundWithBlock { (completion, error) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
}



