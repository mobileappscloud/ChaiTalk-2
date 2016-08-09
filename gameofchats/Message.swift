//
//  Message.swift
//  CongenialApps
//
//  Created by Faisal Syed on 7/7/16.
//  Copyright © 2016 CongenialApps.com All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {

    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    var videoUrl: String?
    
    func chatPartnerId()->String?
    {
        if fromId == FIRAuth.auth()?.currentUser?.uid
        {
            return toId
        }
            
        else
        {
            return fromId
        }
    }
    
    init(dictionary: [String: AnyObject])
    {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["fromId"] as? NSNumber
        toId = dictionary["toId"] as? String
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }
    
}
