//
//  ChatInputContainerView.swift
//  ChaiTalk
//
//  Created by Faisal Syed on 8/11/16.
//  Copyright © 2016 letsbuildthatapp. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate
{
    var chatLogController: ChatLogController?
    {
        didSet
        {
            sendButton.addTarget(chatLogController, action: #selector(ChatLogController.handleSend), forControlEvents: .TouchUpInside)
            
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target:chatLogController, action: #selector(ChatLogController.handleUploadTap)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let sendButton = UIButton(type: .System)
    let uploadImageView = UIImageView()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = .whiteColor()
        
        uploadImageView.image = UIImage(named: "upload_image_icon@2x.png")
        uploadImageView.userInteractionEnabled = true
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(uploadImageView)
        
        //x,y,w,h
        uploadImageView.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        uploadImageView.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        uploadImageView.widthAnchor.constraintEqualToConstant(44).active = true
        uploadImageView.heightAnchor.constraintEqualToConstant(44).active = true
        
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        //
        addSubview(sendButton)
        //x,y,w,h
        sendButton.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
        sendButton.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        sendButton.widthAnchor.constraintEqualToConstant(80).active = true
        sendButton.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        
        addSubview(self.inputTextField)
        //x,y,w,h
        self.inputTextField.leftAnchor.constraintEqualToAnchor(uploadImageView.rightAnchor, constant: 8).active = true
        self.inputTextField.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        self.inputTextField.rightAnchor.constraintEqualToAnchor(sendButton.leftAnchor).active = true
        self.inputTextField.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLineView)
        //x,y,w,h
        separatorLineView.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        separatorLineView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        separatorLineView.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        separatorLineView.heightAnchor.constraintEqualToConstant(1).active = true
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
