//
//  ViewController.swift
//  MemeMe
//
//  Created by Shroog Salem on 26/09/2019.
//  Copyright © 2019 Shroug Salem. All rights reserved.
//

import UIKit
import Foundation
struct Meme {
    let topText: String
    let bottomText: String
    let originalImage: UIImage
    let memedImage: UIImage
}
class MemeViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextFieldDelegate {
    //MARK: Outlets
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topTextField.delegate = self
        self.bottomTextField.delegate = self
        //setting the default attributes
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth:  -3.50,
        ]
        configureUITextField(textField: topTextField, text: "TOP", defaultAttributes: memeTextAttributes)
        configureUITextField(textField: bottomTextField, text: "BOTTOM", defaultAttributes: memeTextAttributes)
        
        shareButton.isEnabled = false
    }
    //MARK: Top & bottom text field config
    func configureUITextField(textField: UITextField, text: String, defaultAttributes: [NSAttributedString.Key: Any]) {
        textField.defaultTextAttributes = defaultAttributes //Setting the defaultTextAttributes property
        textField.delegate = self
        textField.text = text //"TOP" or "BOTTOM"
        textField.textAlignment = .center //Text should be center-aligned
        textField.backgroundColor = .clear
        textField.autocapitalizationType = .allCharacters //All caps
    }
    //MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        subscribeToKeyboardNotifications()
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
    }
    
    //MARK: TextField Delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //clear when editing top or bottom text field
        textField.text = ""
        if textField == topTextField {
             //unsubscribe to keyboard notification when editing top text field
            unsubscribeFromKeyboardNotifications()
        } else {
             //subscribe when editing to bottom text field
            subscribeToKeyboardNotifications()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: Generating a Meme Object
    func save() {
        // Create the meme
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imagePickerView.image!, memedImage: generateMemedImage())
        
    }
    
    func generateMemedImage() -> UIImage {
        
        // Hide toolbar and navbar
        toolBar.isHidden = true
        navigationBar.isHidden = true
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show toolbar and navbar
        toolBar.isHidden = false
        navigationBar.isHidden = false
        return memedImage
    }
    

   
    //MARK: Image Picker Delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imagePickerView.image = image
            topTextField.topAnchor.constraint(equalTo: imagePickerView.topAnchor)
            bottomTextField.bottomAnchor.constraint(equalTo: imagePickerView.bottomAnchor)
        }
        
        shareButton.isEnabled = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Keyboard adjusments
    @objc func keyboardWillShow(_ notification:Notification) {
        
        view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    //MARK: Notification
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: Actions
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)

    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func cancelImage(_ sender: Any) {
        imagePickerView.image = nil
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        shareButton.isEnabled = false
    }
    @IBAction func cancelMemedImage(_ sender: Any) {
       
    }
    
    @IBAction func shareMemedImage(_ sender: Any) {
        // generate meme
        let memedImage = generateMemedImage()
        //define an instance of the ActivityViewController & pass the ActivityViewController memedImage as an activity item
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        // present the activity view
        self.present(activityViewController, animated: true, completion: nil)
        activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed:Bool, returnedItems:[Any]?, error: Error?) in
            if completed {
                self.save()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
}

