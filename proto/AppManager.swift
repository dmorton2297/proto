//
//  AppManager.swift
//  proto
//
//  Created by Dan Morton on 2/24/15.
//  Copyright (c) 2015 Dan Morton. All rights reserved.
//
//
//  This class provides global functionality for the entire app.
//

import Foundation
import UIKit
import Parse

var appManager = AppManager()//global manager that can be used throughout project.


class AppManager
{
    var user:PFUser! = nil
    var locationManager : CLLocationManager!
    
    init()
    {
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //Displays a UIAlert on the given view controller
    func displayAlert(viewController:UIViewController, title:String, message:String, completion:((UIAlertAction?) -> Void)?)
    {
        //creating alertViewController and alert action.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: completion)
        
        //adding the alert action to the view controller
        alertController.addAction(alertAction)
        
        //presenting the view
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //Parse functions--------------------------------------
    
    
    //get this users dataObject
    func getUsersData() -> PFObject
    {
        var query = PFQuery(className:"UserData")
        var dat:PFObject!
        if (user != nil)
        {
            var dataID = user.objectForKey("dataID") as! NSString
            println(dataID)
            dat = query.getObjectWithId(dataID as String)
            return dat
            
        }
        return dat
    }
    

    func getParseObject(className:String, objectID:String) ->PFObject
    {
        var query = PFQuery(className: className)
        println(objectID)
        return query.getObjectWithId(objectID);
    }
    
    //conert a UIImage to a pffile
    func convertUIImageToPFFile(image:UIImage)->PFFile
    {
        let imageData = UIImageJPEGRepresentation(image, 0.0)
        let file = PFFile(data: imageData)
        return file
    }
    
    func convertPFFiletoUIImage(file:PFFile)->UIImage
    {
        var image:UIImage? = nil
        
        var dat = file.getData() as NSData
        
        image = UIImage(data: dat)
        
        if (image == nil)
        {
            image = UIImage(named: "friendsIcon")
        }
        return image!
    }
    
}
