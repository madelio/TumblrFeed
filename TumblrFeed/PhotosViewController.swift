//
//  PhotosViewController.swift
//  TumblrFeed
//
//  Created by Madel Asistio on 2/2/17.
//  Copyright © 2017 Madel Asistio. All rights reserved.
//

import UIKit
import AFNetworking

class PhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    
    var posts: [NSDictionary] = []
    var refresher: UIRefreshControl!
    var isMoreDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?
    var imageTemp: [URL] = []
    

    @IBOutlet weak var tableView: UITableView!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
        
        
        // refresh screen
         refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(PhotosViewController.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresher)
        refresh()
        
        tableView.dataSource = self
        tableView.delegate = self
        //tableView.rowHeight = 240
        
        getData()
        
        
        // Do any additional setup after loading the view.
    }
    
    func getData() {
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options:[]) as? NSDictionary {
                        //print("responseDictionary: \(responseDictionary)")
                        
                        // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                        // This is how we get the 'response' field
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]
                        // This is where you will store the returned array of posts in your posts property
                        // self.feeds = responseFieldDictionary["posts"] as! [NSDictionary]
                        
                    }
                    
                }
                self.tableView.reloadData()
                self.refresher.endRefreshing()
        });
        task.resume()

        
    }
    
    func refresh() {
        getData()

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!isMoreDataLoading) {
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            if (scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging) {
                isMoreDataLoading = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()

                loadMoreData()
        
            }
        }
    }
    
    func loadMoreData() {
        
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (data, response, error) in
                                                                        
            // Update flag
            
            if let data = data {
                self.isMoreDataLoading = false
                
                // Stop the loading indicator
                self.loadingMoreView!.stopAnimating()
                
                if let responseDictionary = try! JSONSerialization.jsonObject(
                    with: data, options:[]) as? NSDictionary {
                    //print("responseDictionary: \(responseDictionary)")
                    
                    // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                    // This is how we get the 'response' field
                    let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                    
                    for x in  responseFieldDictionary["posts"] as! [NSDictionary] {
                        self.posts.append(x)
                    }
                    
                    // This is where you will store the returned array of posts in your posts property
                    // self.feeds = responseFieldDictionary["posts"] as! [NSDictionary]
                    
                }
                
            }
            // ... Use the new data to update the data source ...
            
            
            // Reload the tableView now that there is new data
           self.tableView.reloadData()
        });
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! PhotoCell
        
        let post = posts[indexPath.row]
        
        if let photos = post.value(forKey: "photos") as? [NSDictionary] {
            
            let imageUrlString = photos[0].value(forKeyPath:
                "original_size.url") as? String
            
            if let imageUrl = URL(string: imageUrlString!) {
                cell.photoImageView.setImageWith(imageUrl)
                imageTemp.append(imageUrl)
            } else {
                
            }
            
        } else {
            
            
        }

        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "showImage" {
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            let vc = segue.destination as! PhotoDetailsViewController
            
            let post = posts[(indexPath?.row)!]
            
            if let photos = post.value(forKey: "photos") as? [NSDictionary] {
                
                let imageUrlString = photos[0].value(forKeyPath:
                    "original_size.url") as? String
                
                if let imageUrl = URL(string: imageUrlString!) {
                    //cell.photoImageView.setImageWith(imageUrl)
                    //imageTemp.append(imageUrl)
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: imageUrl) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                        DispatchQueue.main.async {
                            vc.tumblrImageBig.image = UIImage(data: data!)
                        }
                    }
                } else {
                    
                }
                
            } else {
                
            }
        }
        
        //vc.tumblrImageBig = posts[indexPath!.row]
        

 
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
