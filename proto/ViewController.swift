//
//  ViewController.swift
//  proto
//
//  Created by Dan Morton on 2/23/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate
{

    @IBOutlet var titleLabel: UILabel!           //title label connection from storyboard
    @IBOutlet var signUpButton: UIButton!        //sign up button connection from storyboard
    @IBOutlet var cameraImageView: UIImageView!  //background image connectino from storyboard
    @IBOutlet var logInButton: UIButton!         //log in button connection from storyboard
    @IBOutlet var usernameTextField: UITextField!//Username text field connection from storyboard
    @IBOutlet var passwordTextField: UITextField!//Password textfield from storyboard
    
    
    var currentUser:PFUser! = nil
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        currentUser = PFUser.currentUser()
        
        //set up for blur effect on background image
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.frame
        self.view.addSubview(blurView)
        self.view.sendSubviewToBack(blurView)
        self.view.sendSubviewToBack(cameraImageView)
        
        //set up for round style of "titleLabel"
        titleLabel.clipsToBounds = true
        titleLabel.layer.cornerRadius = 10
        
        //set up for round style of "signUpButton"
        signUpButton.clipsToBounds = true
        signUpButton.layer.cornerRadius = 10
        
        //set up for round style of "logInButton"
        logInButton.clipsToBounds = true
        logInButton.layer.cornerRadius = 10
        
        //setup for textfield delegation
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        if (currentUser != nil)
        {
            usernameTextField.text = currentUser.username
            passwordTextField.text = "••••••••"
        }
        
        //securing password text field
        passwordTextField.secureTextEntry = true
    }
    
    //if there is a current user, sign in
    override func viewDidAppear(animated: Bool)
    {
        currentUser = PFUser.currentUser()
        if (currentUser != nil)
        {
            appManager.user = currentUser
            self.performSegueWithIdentifier("login2", sender: self)
        }
    }
    
    //UITextField delgation methods--------------------------------------------------
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    //IBAction connections from story board------------------------------------------
    
    //action will be triggered when "logInButton" is pressed
    @IBAction func loginButtonPressed(sender: UIButton)
    {
        var checkOne:Bool = usernameTextField.text == "" || usernameTextField.text == nil
        var checkTwo:Bool = passwordTextField.text == "" || passwordTextField.text == nil
        
        //if the user has not completed the textfields, break action.
        if (checkOne || checkTwo)
        {
            appManager.displayAlert(self, title: "Invalid Information", message: "Please complete both text fields.", completion: nil)
        }
        else
        {
            PFUser.logInWithUsernameInBackground(usernameTextField.text, password:passwordTextField.text) {
                (user: PFUser!, error: NSError!) -> Void in
                if user == nil
                {
                    println(error.description)
                    appManager.displayAlert(self, title: "Error", message: "Invalid Login Information", completion: nil)
                }
                else
                {
                    println(PFUser.currentUser().username)
                    appManager.user = user
                    self.performSegueWithIdentifier("login2", sender: self)
                }
                
            }
        }
    }
    
}

