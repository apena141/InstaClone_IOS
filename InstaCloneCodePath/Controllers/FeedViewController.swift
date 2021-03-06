//
//  FeedViewController.swift
//  InstaCloneCodePath
//
//  Created by Anthony Pena on 8/6/21.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate{
    
    @IBOutlet weak var composeButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject]()
    let commentBar = MessageInputBar()
    var showsCommentBar = false
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillBeHidden(note: Notification){
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }

    override var inputAccessoryView: UIView?{
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create the comment
        let comment = PFObject(className: "Comment")
        comment["body"] = text
        comment["relatingPost"] = selectedPost
        comment["createdBy"] = PFUser.current()!
        selectedPost.add(comment, forKey: "comment")
        
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved")
            } else{
                print("Error saving comment")
            }
        }
        
        tableView.reloadData()
        
        // Clear and dismiss
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        
        let comments = (post["comment"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1{
            showsCommentBar = true
            becomeFirstResponder()
            
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery(className: "Post")
        query.includeKeys(["user", "comment", "comment.createdBy"])
        query.limit = 20
        query.findObjectsInBackground{ (posts, error) in
            if posts != nil{
                print("Posts not nil: \(posts?.count)")
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func onLogout(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = loginViewController
    }
    
    @IBAction func onCompose(_ sender: Any) {
        self.performSegue(withIdentifier: "composeSegue", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        // ?? = if the left side is nil then our variable will be whatever is on the right
        let comments = (post["comment"] as? [PFObject]) ?? []
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
        let comments = (post["comment"] as? [PFObject]) ?? []
        print("comments size: \(comments.count)")
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
            let user = post["user"] as! PFUser
            cell.userNameLabel.text = user.username
            cell.captionLabel.text = post["description"] as! String
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        }else if indexPath.row <= comments.count{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            //
            let comment = comments[indexPath.row - 1]
            cell.commentBody.text = comment["body"] as! String
            let commentUser = comment["createdBy"] as! PFUser
            cell.usernameLabel.text = commentUser.username
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
}
