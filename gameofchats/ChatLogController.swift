//
//  ChatLogController.swift
//  ChaiTalk
//
//  Created by Faisal Syed on 7/7/16.
//  Copyright © 2016 CongenialApps.com All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation
class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    func observeMessages()
    {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid, toId = user?.id
        else
        {
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observeEventType(.ChildAdded, withBlock: { (snapshot) in
           
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String:AnyObject]
                else
                {
                    return
                }
                
                self.messages.append(Message(dictionary: dictionary))
                dispatch_async(dispatch_get_main_queue())
                {
                    self.collectionView?.reloadData()
                    
                    let indexPath = NSIndexPath(forRow: self.messages.count - 1, inSection: 0)
                    self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
                }
                
            }, withCancelBlock: nil)
        }, withCancelBlock: nil)
        
    }
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 58, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView?.registerClass(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .Interactive
    
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: ChatInputContainerView =
    {
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    func handleUploadTap()
    {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL
        {
            //we selected a video
            handleVideoSelectedForUrl(videoUrl)
        } else
        {
            //we selected an image
            handleImageSelectedForInfo(info)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(url: NSURL)
    {
        let filename = NSUUID().UUIDString + ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_movies").child(filename).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print("Failed upload of video:", error)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                if let thumbnailImage = self.thumbnailImageForFileUrl(url) {
                    
                    self.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { (imageUrl) in
                        let properties: [String: AnyObject] = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl]
                        self.sendMessageWithProperties(properties)
                        
                    })
                }
            }
        })
        
        uploadTask.observeStatus(.Progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observeStatus(.Success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForFileUrl(fileUrl: NSURL) -> UIImage?
    {
        let asset = AVAsset(URL: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            
            let thumbnailCGImage = try imageGenerator.copyCGImageAtTime(CMTimeMake(1, 60), actualTime: nil)
            return UIImage(CGImage: thumbnailCGImage)
            
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String: AnyObject])
    {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl, image: selectedImage)
            })
        }
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: (imageUrl: String) -> ())
    {
        let imageName = NSUUID().UUIDString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image:", error)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl: imageUrl)
                }
                
            })
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override var inputAccessoryView: UIView?
    {
        get
        {
            return inputContainerView
        }
    }
    
    override func canBecomeFirstResponder() -> Bool
    {
        return true
    }
    
    func setupKeyboardObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIKeyboardDidShowNotification, object: nil)
        
        /*
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        */
    }
    
    func handleKeyboardDidShow()
    {
        if messages.count > 0
        {
            let indexPath = NSIndexPath(forItem: messages.count - 1, inSection: 0)
            collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleKeyboardWillShow(notification: NSNotification)
    {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animateWithDuration(keyboardDuration!) { 
            self.view.layoutIfNeeded()
        }
        
        //move the input area up
    }
    
    func handleKeyboardWillHide(notification: NSNotification)
    {
        containerViewBottomAnchor?.constant = 0
        
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue
        containerViewBottomAnchor?.constant = 0
        UIView.animateWithDuration(keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as! ChatMessageCell
        
        //create a reference to the chat log controller to delegate zoom to it
        cell.chatLogController = self 
        
        let message = messages[indexPath.item]
        
        cell.message = message 
        
        cell.textView.text = message.text
        setUpCell(cell, message: message)
        
        if let text = message.text
        {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text).width + 32
            cell.textView.hidden = false
        }
        
        else if message.imageUrl != nil
        {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.hidden = true 
        }
        
        cell.playButton.hidden = message.videoUrl == nil 

        return cell
    }
    
    private func setUpCell(cell: ChatMessageCell, message: Message)
    {
        if let profileImageUrl = self.user?.profileImageUrl
        {
            cell.profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl
        {
            cell.messageImageView.loadImageUsingCacheWithUrlString(messageImageUrl)
            cell.messageImageView.hidden = false
            cell.bubbleView.backgroundColor = UIColor.clearColor()
        }
        
        else
        {
            cell.messageImageView.hidden = true
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid
        {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.whiteColor()
            cell.profileImageView.hidden = true
            
            cell.bubbleViewRightAnchor?.active = true
            cell.bubbleViewLeftAnchor?.active = false 
        }
            
        else
        {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.blackColor()
            cell.profileImageView.hidden = false
            
            cell.bubbleViewRightAnchor?.active = false
            cell.bubbleViewLeftAnchor?.active = true
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var height:CGFloat = 80
        
        let message = messages[indexPath.item]
        
        if let text = message.text
        {
            height = estimateFrameForText(text).height + 20
        }
        
        else if let imageWidth = message.imageWidth?.floatValue, imageHeight = message.imageHeight?.floatValue
        {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.mainScreen().bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text:String) -> CGRect
    {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin)
        return NSString(string: text).boundingRectWithSize(size, options: options, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func handleSend()
    {
        let properties = ["text": inputContainerView.inputTextField.text!]
        sendMessageWithProperties(properties)
    }
    
    private func sendMessageWithImageUrl(imageUrl:String, image:UIImage)
    {
        let properties: [String:AnyObject] = ["imageUrl":imageUrl, "imageHeight":image.size.height, "imageWidth":image.size.width]
        
        sendMessageWithProperties(properties)
    }
    
    private func sendMessageWithProperties(properties: [String:AnyObject])
    {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp: NSNumber = Int(NSDate().timeIntervalSince1970)
        var values: [String:AnyObject] = ["toId": toId, "fromId": fromId, "timestamp": timestamp]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil
            {
                print(error)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
        

    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    //custom zooming logic
    
    var startingFrame: CGRect?
    var blackBackground:UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForImage(startingImageView:UIImageView)
    {
        self.startingImageView = startingImageView
        self.startingImageView?.hidden = true
        startingFrame = startingImageView.superview?.convertRect(startingImageView.frame, toView: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.redColor()
        zoomingImageView.image = startingImageView.image
        zoomingImageView.userInteractionEnabled = true 
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.sharedApplication().keyWindow
        {
            
            blackBackground = UIView(frame: keyWindow.frame)
            blackBackground?.backgroundColor = UIColor.blackColor()
            blackBackground?.alpha = 0
            keyWindow.addSubview(blackBackground!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations:
                {
                    self.blackBackground?.alpha = 1
                    self.inputContainerView.alpha = 0
                    //calculate ending image height
                    // h2 / w2 = h1/ w1 and solve for h2
                    //h2 = h1/w1 * w2
                    let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                    
                    zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                    
                    zoomingImageView.center = keyWindow.center

                },
                
                completion: { (completed:Bool) in
                                        
            })
        }

    }
    
    func handleZoomOut(tapGesture:UITapGestureRecognizer)
    {
        if let zoomOutImageView = tapGesture.view
        {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations:
            {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackground?.alpha = 0
                self.inputContainerView.alpha = 1
            },
            completion: { (completed:Bool) in
                
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.hidden = false

            })
        }
    }
    
}













