//
//  AccountViewController.swift
//  Neighborly
//
//  Created by Avni Barman on 4/8/18.
//  Copyright © 2018 Adam Liber. All rights reserved.
//

import UIKit
import Starscream
import Cloudinary


class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WebSocketDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
   
        
    @IBOutlet weak var nameField: UILabel!
    
    @IBAction func updatePhotoButtonClicked(_ sender: Any) {
        let imagePicked = UIImagePickerController()
        imagePicked.delegate = self
        
        imagePicked.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        imagePicked.allowsEditing = false
        imagePicked.modalPresentationStyle = .overCurrentContext
        self.present(imagePicked, animated: true){
            
        }
    }
    
   
    @IBOutlet weak var profileImageView: UIImageView!
    
    var encodedImg:String = ""
    var imageData = Data()
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let imagePicked = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profileImageView.image = imagePicked
            user?.setImage(image: imagePicked)
            user?.saveUser()
            updateAccount()
            
            imageData = UIImageJPEGRepresentation(imagePicked, 0.000005)!
            
        }

        
        self.dismiss(animated: true, completion: nil)
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "szxnywdo"){
            result, error in
            print("account profile image upload error:  \(String(describing: error))")
            print("account profile image result: \(String(describing: result?.publicId))")
            
        }
     
        
    }
   
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("accountinfo socket connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("accountinfo socket disconnected")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("account info received text: \(text)")
        let jsonText = text.data(using: .utf8)!
        let decoder = JSONDecoder()
        let userInfo = try! decoder.decode(UserInfoMessage.self, from: jsonText)
        print("userID received:  \(String(describing: userInfo.userID))" )
        print("message received:  \(userInfo.message)" )
        print("\nmy Items received: \(String(describing: userInfo.myItems?.first?.itemName))" )
        
        if(userInfo.message == "valid"){
            model.setMyItems(items: userInfo.myItems!)
            model.setBorrowedItems(items: userInfo.borrowedItems!)
            
            
        }
            
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("account info received data: \(data)")

    }
    
    
    public var user:User?
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    private var model = ItemsModel()
    
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate  as! AppDelegate
        appDelegate.centerContainer?.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket.delegate = self
        // Do any additional setup after loading the view.
        self.tableView.rowHeight = 134
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2
        profileImageView.layer.masksToBounds = false
        profileImageView.clipsToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAccount), name: NSNotification.Name(rawValue: "loadAccount"), object: nil)
        updateAccount()
        
        
        let accountInfoMessage = AccountInfoMessage(userID: (user?.userID)!)
        let encoder = JSONEncoder()
        
        
        do{
            let data = try encoder.encode(accountInfoMessage)
            socket.write(string: String(data: data, encoding: .utf8)!)
            
        }catch{}
        print("account view did load")
        
    }
    
    @objc func updateAccount(){
        self.user = loadUser()
        self.nameField.text = user?.name
        if(self.user?.image != nil){
            self.profileImageView.image = self.user?.image
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loadMenu"), object: nil)
        tableView.reloadData()
        
    }
    
    @IBAction func segmentControlClicked(_ sender: Any) {
        tableView.reloadData();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        switch(segmentControl.selectedSegmentIndex){
        case 0:
            return model.borrowedItems.count
            
        case 1:
            return model.myItems.count
            
        default:
            break
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell( withIdentifier: "itemCard", for: indexPath) as! ItemCardTableViewCell
        var item:Item?
        
        switch(segmentControl.selectedSegmentIndex){
        case 0:
            item = model.borrowedItems[indexPath.row]
            cell.itemPhoto.image = UIImage(named:"DefaultItemCamera")
            break
        case 1:
            item = model.myItems[indexPath.row]
            cell.itemPhoto.image = UIImage(named:"DefaultItemDrill")
            break
        default:
            break
        }
        
        cell.itemName.text = item?.itemName
        cell.itemDetails.text = item?.itemDescription
        
        if(item?.available == 1){
            cell.itemStatusLabel.text = "Available"
            cell.itemStatusLabel.backgroundColor = UIColor.green
            cell.itemStatusLabel.textColor = UIColor.white
        }else{
            cell.itemStatusLabel.text = "Unavailable"
            cell.itemStatusLabel.backgroundColor = UIColor.red
            cell.itemStatusLabel.textColor = UIColor.white
        }
        
        return cell
    }
    
}
