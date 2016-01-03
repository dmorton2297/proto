//
//  SignUpViewController.swift
//  proto
//
//  Created by Dan Morton on 2/24/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var backgroundImage: UIImageView!       //background image connection from storyboard
    @IBOutlet weak var titleLabel: UILabel!           //"title label" connection from storyboard
    @IBOutlet weak var signUpButton: UIButton!        //"sign up button" connection from storyboard
    @IBOutlet weak var cancelButton: UIButton!        //"cancel button" connection from storyboard
    @IBOutlet weak var emailTextField: UITextField!   //"email text field" connection from storyboard
    @IBOutlet weak var usernameTextField: UITextField!//"username text field" connection from storyboard
    @IBOutlet weak var passwordTextField: UITextField!//"password text field" connection from storyboard
    @IBOutlet weak var reentryTextField: UITextField! //"re-enter password" connectionf from storyboard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        
        //blurring effect setup for background
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.frame
        self.view.addSubview(blurView)
        self.view.sendSubviewToBack(blurView)
        self.view.sendSubviewToBack(backgroundImage)
        
        //styling for "titleLabel"
        titleLabel.clipsToBounds = true
        titleLabel.layer.cornerRadius = 10
        
        //styling for "cancelButton"
        cancelButton.clipsToBounds = true
        cancelButton.layer.cornerRadius = 10
        
        //styling for "signUpButton"
        signUpButton.clipsToBounds = true
        signUpButton.layer.cornerRadius = 10
        
        //UITextField delegation setup
        emailTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        reentryTextField.delegate = self
        
        //making password textfield secure
        passwordTextField.secureTextEntry = true
        reentryTextField.secureTextEntry = true
    }
    
    //UITextField delegation set up ------------------------------------------------------
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        //close the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    //IBActions from storyboard-----------------------------------------------------------
    
    //will fire when "cancelButton" is pressed
    @IBAction func cancelButtonPressed(sender: AnyObject)
    {
        //dimiss this view controller, and do nothing
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    //will fire when "signUpButton" is pressed
    //This method will sign up user with parse.
    @IBAction func signUpButtonPressed(sender: AnyObject)
    {
        print("Check one")
        //conditional checks to make sure all info is present
        let checkOne:Bool = emailTextField.text == nil || emailTextField.text == ""
        let checkTwo:Bool = usernameTextField.text == nil || usernameTextField.text == ""
        let checkThree:Bool = passwordTextField.text == nil || passwordTextField.text == ""
        let checkFour:Bool = reentryTextField.text == nil || reentryTextField.text == ""
        
        if (checkOne || checkTwo || checkThree || checkFour)
        {
            //display alert if all info is not present
            appManager.displayAlert(self, title: "Missing information", message: "Please enter valid information", completion: nil)
        }
        else
        {
            let checkFive:Bool = passwordTextField.text != reentryTextField.text
            //make sure that the two password field agree
            if (checkFive)
            {
                appManager.displayAlert(self, title: "Oops..", message: "Passwords don't match.", completion: nil)
                return
            }
            
            //get all the information from the textfields
            let email = emailTextField.text
            let username = usernameTextField.text
            let password = passwordTextField.text
            
            //create a dataobject for the possible user
            var userdata = PFObject(className:"UserData")
            
            //all of these arrays are inline, each will be same length and correspond with each other
            userdata["location_names"] = [NSData]()
            userdata["location_coordinates"] = [NSData]()
            userdata["point_worth"] = [NSData]()
            userdata["images"] = [PFFile]()
            userdata["likes"] = [NSData]()
            //userdata["profile_picture"] = PFFile()
            
            var friends = PFObject(className: "FriendsObject")
            
            friends["following"] = [NSData]()
            friends["friend_requests"] = [NSData]()
            friends["friends"] = [NSData]()
            friends["requested"] = [NSData]()
            
            
            //this following array will contain a custom PFFile class which will represent
            //a photo message
            userdata.save()
            friends.save()            
            
            //set up a new user and register the user with parse
            var user = PFUser()
            user.username = username
            user.password = password
            user.email = email
            // other fields can be set just like with PFObject
            user["dataID"] = userdata.objectId
            user["friendsDataID"] = friends.objectId
            user["image_posts"] = [NSString]()
            user["lastPostedTime"] = NSDate()
            var defaultImage = UIImage(named: "profilePicturePlaceholder")
            var defImageFile = appManager.convertUIImageToPFFile(defaultImage!)
            
            user["profile_picture"] = defImageFile
            
            user.signUpInBackgroundWithBlock({ (completion, error) -> Void in
                if error == nil {
                    appManager.displayAlert(self, title: "Congratulations!", message: "You are now registered"){(alertAction) -> Void in
                        PFUser.logInWithUsernameInBackground(username, password: password) {
                            (user: PFUser!, error: NSError!) -> Void in
                            if user != nil
                            {
                                appManager.user = user
                                print("This is running")
                                self.performSegueWithIdentifier("login", sender: self)
                            }
                            else
                            {
                                appManager.displayAlert(self, title: "Error", message: "Something horrible happend", completion: nil)
                                userdata.deleteInBackgroundWithBlock(nil)
                            }
                        }
                    }
                } else {
                    let errorString = error.description
                    appManager.displayAlert(self, title: "Oops..", message: errorString, completion: nil)
                    userdata.deleteInBackgroundWithBlock(nil)
                }

            })
        }
    
    }
}


