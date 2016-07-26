//
//  SearchResultTableViewCell.swift
//  ChoreSolver
//
//  Created by yao  on 7/10/16.
//  Copyright © 2016 yao . All rights reserved.
//

import UIKit
import Bond
import Parse
import ConvenienceKit
class SearchResultTableViewCell: UITableViewCell {
    
    static var stateCache: NSCacheSwift<String, Int?>!
    var existingRequestDisposable: DisposableType?
    var imageDisposable: DisposableType?
    var stateRequest: Observable<Int?> = Observable(nil)
   
    var cleanPerson: User? {
        didSet {
            imageDisposable?.dispose()
            //free memory of image stored with the CP that is no longer displayed
            if let oldValue = oldValue where oldValue != cleanPerson {
                oldValue.image.value = nil
            }
            //to check if the new value is nil
            if let cleanPerson = cleanPerson {
//                cleanPerson.image.bindTo(cleanPersonImage.bnd_image)
                imageDisposable = cleanPerson.image.bindTo(cleanPersonImage.bnd_image)
            }
        }
    }
   
   

    var tabBarViewController: UITabBarController?
    
    @IBOutlet weak var cleanPersonNameLabel: UILabel!
    @IBOutlet weak var cleanPersonImage: UIImageView!
    @IBOutlet weak var hourRateLabel: UILabel!
    @IBOutlet weak var requestButton: UIButton! {
        didSet {
            existingRequestDisposable?.dispose()
//            if requestButton != nil {
            existingRequestDisposable = stateRequest.observe ({ (value: Int?) -> ()in
                if let value = value {
                    switch(value){
                    case 1:
                        //agree
                        self.requestButton.setTitle("Contact!", forState: UIControlState.Normal)
                        self.requestButton.enabled = false
                    case 2:
                        self.requestButton.setTitle("Request Sent", forState: UIControlState.Normal)
                        self.requestButton.enabled = false
                    default:
                        self.requestButton.enabled = true
                    }
                   
                }
            })
//            } else {
//                self.requestButton.enabled = true
//            }
        }
    }
    
    @IBAction func requestInfoTapped(sender: AnyObject) {
        ParseHelper.initRequestInfo(PFUser.currentUser()!, cleanPerson: cleanPerson!, block: { (success: Bool, error: NSError?) in
            self.tabBarViewController!.selectedViewController = self.tabBarViewController!.viewControllers![1]
            let customerName = PFUser.currentUser()?.username!
            if let cleanPersonOneSignalID = self.cleanPerson?.oneSignalID as? String {
            let jsonData = ["app_id": "6f185136-e88e-4421-84b2-f8e681c0da7e","include_player_ids": [cleanPersonOneSignalID],"contents": ["en": "\(customerName) sent a request for your contact info! Reply \(customerName)!"]]
            
            AppDelegate.oneSignal!.postNotification(jsonData)
            }
        })
        //transition to tab Request
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fetchRequest() {
    
        self.stateRequest.value = SearchResultTableViewCell.stateCache[self.cleanPerson!.username!] ?? nil
        if self.stateRequest.value == nil {
        
            ParseHelper.fetchParticularRequest(PFUser.currentUser()!, cleanPerson: cleanPerson!) { (result: [PFObject]?, error: NSError?) in
                if error != nil {
                    //no result, 0-> nil
                    self.stateRequest.value = 0
                }
                print("e")
                if let result = result as? [Request]? {
                    if result?.count != 0 {
                        if result![0].agree.boolValue {
                            self.stateRequest.value = 1  // a request exist and have agree
                        } else {
                            self.stateRequest.value = 2 // a request exist and no agree yet
                        }
                    } else {
                        self.stateRequest.value = 0
                    }
                }
                
                SearchResultTableViewCell.stateCache[self.cleanPerson!.username!] = self.stateRequest.value
                
            }
            
            
        }
    }
    
    

    
    
}
