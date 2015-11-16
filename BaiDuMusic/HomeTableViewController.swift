//
//  HomeTableViewController.swift
//  BaiDuMusic
//
//  Created by GXY on 15/11/10.
//  Copyright © 2015年 Tangxianhai. All rights reserved.
//

import UIKit
import Alamofire
import JGProgressHUD

/*
http://fm.baidu.com/dev/api/?tn=channellist
http://fm.baidu.com/dev/api/?tn=playlist&id=public_tuijian_rege
http://fm.baidu.com/data/music/songlink?songIds=913288
http://fm.baidu.com/data/music/songinfo?songIds=913288
*/

class HomeTableViewController: UITableViewController,NSURLConnectionDelegate,NSURLConnectionDataDelegate {
    var jsonData:NSArray!
    var hud:JGProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "推荐歌曲"
        
        hud = JGProgressHUD(style: .Dark)
        hud.textLabel.text = "加载中..."
        hud.showInView(self.navigationController?.view)
        
        Alamofire.request(.GET, "http://fm.baidu.com/dev/api/?tn=channellist", parameters: nil)
            .responseJSON { response in
                self.hud.dismissAfterDelay(1.0)
                if let JSON = response.result.value {
                    self.jsonData = JSON["channel_list"] as! NSArray
                    print("JSON: \(self.jsonData)")
                    self.tableView .reloadData()
                }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.jsonData == nil {
            return 0
        }
        return self.jsonData.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("homefenleiindetifier")
        if (cell == nil) {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "homefenleiindetifier")
        }
        let dic:NSDictionary = self.jsonData[indexPath.row] as! NSDictionary
        let channelName:String = dic["channel_name"] as! String
        cell!.textLabel?.text = channelName
        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dic:NSDictionary = self.jsonData[indexPath.row] as! NSDictionary
        let channelName:String = dic["channel_name"] as! String
        let channelid:String = dic["channel_id"] as! String
        let playerVC:PlayerViewController = UIStoryboard(name: "Main",bundle:nil).instantiateViewControllerWithIdentifier("playerIndetifier") as! PlayerViewController
        playerVC.myTitle = channelName
        playerVC.fenleiId = channelid
        self.navigationController?.pushViewController(playerVC, animated: true)
    }
}
