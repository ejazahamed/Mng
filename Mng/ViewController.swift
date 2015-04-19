//
//  ViewController.swift
//  Mng
//
//  Created by vale on 4/19/15.
//  Copyright (c) 2015 changweitu@gmail.com. All rights reserved.
//

import UIKit
import Foundation

let USER_AVATAR_KEY = "user_avatar"
let PLACE_TPYE_KEY = "place_type"
let PLACE_NAME_KEY = "place_name"
let GOOGLE_API_KEY = "AIzaSyCI9JEdZ2Nx82qftV9ZSGzFr0ar98PsYQc"
enum PLACE_TYPE: String { //Find them in here:https://developers.google.com/places/supported_types
    
    case Gourmet_Guru = "cafe|food|restaurant"
    case Fitness_Freak = "gym|health"
    case Shopaholic = "clothing_store|shopping_mall|shoe_store|store"
    case Entertainment = "amusement_park|aquarium|art_gallery|movie_theater|museum|park"
}
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView: UITableView!
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var users: NSArray!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.users = NSArray()
        self.setupViews()
        println("\(PLACE_TYPE.Gourmet_Guru.hashValue)")
        if PFUser.currentUser() == nil {
            
            self.signUpUser()
            
        } else {
            
            self.loadUsers()
        }
        self.setupLocationManager()
        
    }

    func setupViews() {
        
        self.title = "MeetnGain"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Locate", style: .Plain, target: self, action: "locate")
        
        self.tableView = UITableView(frame: self.view.bounds, style: .Plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
    }

    func locate() {
        
        self.currentLocation = self.locationManager.location
        if let location = self.currentLocation {
            
            self.searchPlaceWithLocation(location)
            
        } else {
            
            SVProgressHUD.showInfoWithStatus("Please open the location function at: Settings->Privacy->Location")
        }
        
        
    }
    
    func searchPlaceWithLocation(location:CLLocation) {
        
        SVProgressHUD.showWithStatus("Check-In...")
        
        let searchPath = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&radius=100&types=\(PLACE_TYPE.Entertainment.rawValue)|\(PLACE_TYPE.Gourmet_Guru.rawValue)|\(PLACE_TYPE.Fitness_Freak.rawValue)|\(PLACE_TYPE.Shopaholic.rawValue)&key=\(GOOGLE_API_KEY)"
        request(.GET, searchPath.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!, parameters: nil, encoding:.URL).responseJSON(options: NSJSONReadingOptions.MutableContainers) { (_, _, json, _) -> Void in
           
            SVProgressHUD.dismiss()
            if json != nil {
                
                var json = JSON(json!)
                let result = json["results"]
                if result.length > 0 {
                    
                    
                    let check_in_place = result[0]
                    let place_name = check_in_place["name"]
                    println("\(check_in_place)")
                    for (_, v) in check_in_place["types"] {
                        
                        let type = v.asString
                        if PLACE_TYPE.Gourmet_Guru.rawValue.rangeOfString(type!) != nil {
                            self.saveUserPlace(type:PLACE_TYPE.Gourmet_Guru.hashValue,name:place_name.asString!)
                            break;
                        } else if PLACE_TYPE.Fitness_Freak.rawValue.rangeOfString(type!) != nil {
                            
                            self.saveUserPlace(type:PLACE_TYPE.Fitness_Freak.hashValue,name:place_name.asString!)
                            break;
                        } else if PLACE_TYPE.Shopaholic.rawValue.rangeOfString(type!) != nil {
                            
                            self.saveUserPlace(type:PLACE_TYPE.Shopaholic.hashValue,name:place_name.asString!)
                            break;
                        } else if PLACE_TYPE.Entertainment.rawValue.rangeOfString(type!) != nil {
                            
                            self.saveUserPlace(type:PLACE_TYPE.Entertainment.hashValue,name:place_name.asString!)
                            break;
                        }
                    }
                    
                } else {
                    
                    SVProgressHUD.showInfoWithStatus("can't check-in")
                }
                
            } else {
                
                SVProgressHUD.showInfoWithStatus("can't check-in")
            }
        }
        
    }
    func saveUserPlace(#type:Int, name:String) {
        
        PFUser.currentUser()?.setObject(type, forKey: PLACE_TPYE_KEY)
        PFUser.currentUser()?.setObject(name, forKey: PLACE_NAME_KEY)
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (successed:Bool, errror:NSError?) -> Void in
            
            if successed {
                
                self.loadUsers()
            }
        })

    }
    func setupLocationManager() {
        
        self.locationManager = CLLocationManager()
        //self.locationManager.delegate = self
        self.locationManager.distanceFilter = Double(100.0)
        if self.locationManager.respondsToSelector("requestWhenInUseAuthorization") {
            
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.requestAlwaysAuthorization()
        }
        
        self.locationManager.startUpdatingLocation()

    }
    func signUpUser() {
        
        //upload user's avatar
        var avatarPath = NSBundle.mainBundle().pathForResource("2604045", ofType: "png")
        var avatar = PFFile(name: "avatar", contentsAtPath: avatarPath!)
        SVProgressHUD.showWithStatus("upload user's avatar")
        avatar.saveInBackgroundWithBlock { (successed:Bool, error:NSError?) -> Void in
            
            if successed {
                
                SVProgressHUD.showWithStatus("sign up...")
                var user = PFUser()
                user.username = "Vale"
                user.password = "123456"
                user.setObject(avatar.url!, forKey:  USER_AVATAR_KEY)
                user.signUpInBackgroundWithBlock { (successed:Bool, error:NSError?) -> Void in
                    
                    if successed {
                        
                        self.login()
                        
                    } else {
                        
                        SVProgressHUD.showErrorWithStatus("sign up failed")
                    }
                    
                    
                }
                
            } else {
                
                SVProgressHUD.showErrorWithStatus("sign up failed")
            }
        }
       
    }
    
    func login() {
        
        SVProgressHUD.showWithStatus("login...")
        PFUser.logInWithUsernameInBackground("Vale", password: "123456") { (currentUser:PFUser?, error: NSError?) -> Void in
            if error != nil {
                
                SVProgressHUD.showErrorWithStatus("login failed")
                
            } else {
                
                SVProgressHUD.showSuccessWithStatus("login successed")
                self.loadUsers()
                
            }
        }
    }
    
    func loadUsers() {
        
        let userQuery = PFUser.query()
        SVProgressHUD.showWithStatus("loading users...")
        userQuery?.findObjectsInBackgroundWithBlock({ (array:[AnyObject]?, error:NSError?) -> Void in
            
            SVProgressHUD.dismiss()
            self.users = array
            self.tableView.reloadData()
        })
        
    }
    
    
    //MARK: - UITableViewDataSource
    
     func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.users.count
    }
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell
        if cell == nil {
            
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
        }
        let user = self.users[indexPath.row] as! PFUser
        cell?.textLabel?.text = user.username
        
        if let type = user.objectForKey(PLACE_TPYE_KEY) as? Int{
            
            var imgName: String
            switch type {
                
            case 0 :
                imgName = "Attribute_Gourmet_Guru"
            case 1:
                imgName = "Attribute_FitnessFreak"
            case 2:
                imgName = "Attribute_Shopaholic"
            case 3:
                imgName = "Attribute_entertainment"
            default:
                imgName = ""
                
            }
            var imgView = UIImageView(frame: CGRectMake(0, 5, 30, 30))
            imgView.image = UIImage(named: imgName)
            cell?.accessoryView = imgView
            
        } else {
            
            cell?.accessoryView = nil
        }
        
        
        
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            
            
            if let avatarURL = user.objectForKey(USER_AVATAR_KEY) as? String {
                
                if let data = NSData(contentsOfURL: NSURL(string: avatarURL)!) {
                    
                    let avatar = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        cell?.imageView?.image = avatar
                        cell?.layoutSubviews()
                    })
                }
            }

            
        })
        if let placeName = user.objectForKey(PLACE_NAME_KEY) as? String {
            
            cell?.detailTextLabel?.text = "I am in \(placeName)"
            
        } else {
            
            cell?.detailTextLabel?.text = "unknown place"
        }
        return cell!
    }
    
}

