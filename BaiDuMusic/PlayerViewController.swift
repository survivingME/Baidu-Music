//
//  PlayerViewController.swift
//  BaiDuMusic
//
//  Created by GXY on 15/11/11.
//  Copyright © 2015年 Tangxianhai. All rights reserved.
//  http://fm.baidu.com/data/music/songinfo?songIds=913288

import UIKit
import Alamofire
import Kingfisher
import JGProgressHUD

class PlayerViewController: UIViewController {

    var myTitle:String!
    var fenleiId:String!
    var urlPath:String!
    var jsonData:NSArray!
    var afsoundItem:AFSoundItem!
    var player:AFSoundPlayback!
    var queuq:AFSoundQueue!
    var hud:JGProgressHUD!
    var songPath:String!
    var musicPathUrl:String!
    var songList:NSArray!
    var songIndex:NSInteger!
    var dic2:NSMutableDictionary!
    
    @IBOutlet weak var imageView_center: UIImageView!
    @IBOutlet weak var label_musicName: UILabel!
    @IBOutlet weak var button_player: UIButton!
    @IBOutlet weak var slider_music: UISlider!
    @IBOutlet weak var label_current_time: UILabel!
    @IBOutlet weak var label_end_time: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = myTitle
        // Do any additional setup after loading the view.
        songIndex = 0
        dic2 = NSMutableDictionary(capacity: 4)
        urlPath = "http://fm.baidu.com/dev/api/?tn=playlist&id=\(fenleiId)"
        
        // 1.告诉系统接受远程响应事件，并注册成为第一响应者
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
        
        getSongList()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // 2.接受远程事件处理
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event?.type == UIEventType.RemoteControl {
            switch event!.subtype {
            case UIEventSubtype.RemoteControlPause:
                // 点击暂停
                queuq.pause()
                queuq.status = .Paused
                break
            case UIEventSubtype.RemoteControlNextTrack:
                // 点击下一曲
                self.nextSongAction("")
                break
            case UIEventSubtype.RemoteControlPreviousTrack:
                // 点击上一曲
                self.preSongAction("")
                break
            case UIEventSubtype.RemoteControlPlay:
                //点击播放
                queuq.playCurrentItem()
                queuq.status = .Playing
                break
            default:
                break
            }
        }
    }
    
    // 获取歌曲信息
    func getSongList() -> Void {
        Alamofire.request(.GET, urlPath, parameters: nil)
            .responseJSON { response in
                if let JSON1 = response.result.value {
                    self.jsonData = JSON1["list"] as! NSArray
                    print("jsonData: \(self.jsonData)")
                    self.songPathIndex(self.songIndex,autoPlay: false)
                }
        }
    }
    
    // 根据URL下载图片
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    // 获取第几首歌曲信息
    func songPathIndex(sIndex:NSInteger,autoPlay:Bool) -> Void {
        hud = JGProgressHUD(style: .Dark)
        hud.textLabel.text = "加载中..."
        hud.showInView(self.view)
        if let songId = self.jsonData[sIndex]["id"] as? NSNumber {
            self.songPath = "http://fm.baidu.com/data/music/songinfo?songIds=\(songId)"
            print("songPath: \(self.songPath)")
            Alamofire.request(.GET, self.songPath, parameters: nil)
                .responseJSON { response in
                    if let JSON2 = response.result.value {
                        Alamofire.request(.GET, "http://fm.baidu.com/data/music/songlink?songIds=\(songId)", parameters: nil)
                            .responseJSON { response in
                                if let songListJson = response.result.value {
                                    
                                    let data:NSDictionary! = JSON2["data"] as! NSDictionary
                                    self.songList = data["songList"] as! NSArray
                                    let dic:NSDictionary! = self.songList[0] as! NSDictionary
                                    let imagUrl:String! = dic["songPicBig"] as! String // 封面地址
                                    let musicName:String! = dic["songName"] as! String // 歌曲名
                                    let albumName:String! = dic["albumName"] as! String // 专辑名
                                    let artistName:String! = dic["artistName"] as! String // 歌手名
                                    print("dic:\(dic)")
                                    
                                    self.label_musicName.text = musicName
                                    self.imageView_center.layer.masksToBounds = true
                                    self.imageView_center.layer.cornerRadius = (UIScreen.mainScreen().bounds.size.width - 120) / 2
                                    self.imageView_center.kf_setImageWithURL(NSURL(string: imagUrl)!)
                                    
                                    // 3.设置后台，封面信息
                                    self.dic2.setObject(musicName, forKey: MPMediaItemPropertyTitle)
                                    self.dic2.setObject(artistName, forKey: MPMediaItemPropertyArtist)
                                    self.dic2.setObject(albumName, forKey: MPMediaItemPropertyAlbumTitle)
                                    self.getDataFromUrl(NSURL(string: imagUrl)!) { (data, response, error)  in
                                        dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                            guard let data = data where error == nil else { return }
                                            // 歌曲封面图片，从网络下载的
                                            let imageNew = UIImage(data: data)
                                            self.dic2.setObject(MPMediaItemArtwork(image: imageNew!), forKey: MPMediaItemPropertyArtwork)
                                            MPNowPlayingInfoCenter.defaultCenter().setValue(self.dic2, forKey: "nowPlayingInfo")
                                        }
                                    }
                                    
                                    let myJson =  JSON(songListJson)
                                    self.hud.dismissAfterDelay(1.0)
                                    if let path = myJson["data"]["songList"][0]["songLink"].string {
                                        print("path:\(path)")
                                        self.musicPathUrl = path
                                        if self.afsoundItem != nil && self.queuq != nil {
                                            self.queuq.removeItem(self.afsoundItem)
                                            self.queuq.clearQueue()
                                        }
                                        self.afsoundItem = AFSoundItem(streamingURL: NSURL(string: self.musicPathUrl))
                                        self.queuq = AFSoundQueue(items: [self.afsoundItem])
                                        self.queuq.pause()
                                        if autoPlay == true {
                                            self.playItemSong()
                                        }
                                }
                            }
                        }
                }
            }
        }
    }
    
    @IBAction func player(sender: AnyObject) {
        if self.queuq.status == AFSoundStatus.Playing {
            self.button_player.setImage(UIImage(named: "player_btn_play_normal"), forState: .Normal)
            self.button_player.setImage(UIImage(named: "player_btn_play_highlight"), forState: .Highlighted)
            queuq.pause()
            queuq.status = .Paused
        }
        else if self.queuq.status == AFSoundStatus.Paused {
            self.button_player.setImage(UIImage(named: "player_btn_pause_normal"), forState: .Normal)
            self.button_player.setImage(UIImage(named: "player_btn_pause_highlight"), forState: .Highlighted)
            queuq.playCurrentItem()
            queuq.status = .Playing
        }
        else if self.queuq.status == AFSoundStatus.NotStarted {
            self.button_player.setImage(UIImage(named: "player_btn_pause_normal"), forState: .Normal)
            self.button_player.setImage(UIImage(named: "player_btn_pause_highlight"), forState: .Highlighted)
            self.playItemSong()
        }
    }
    
    @IBAction func nextSongAction(sender: AnyObject) {
        let count = self.jsonData.count
        if self.songIndex < count {
            songIndex!++
        }
        if self.songIndex == count {
            songIndex = 0
        }
        self.sliderInit()
        self.songPathIndex(self.songIndex,autoPlay: true)
    }
    
    @IBAction func preSongAction(sender: AnyObject) {
        let count = self.jsonData.count
        if self.songIndex == 0 {
            songIndex = count
        }
        if self.songIndex <= count {
            songIndex!--
        }
        self.sliderInit()
        self.songPathIndex(self.songIndex,autoPlay: true)
    }
    
    func sliderInit() -> Void {
        self.slider_music.value = Float(0)
        self.label_current_time.text = "00:00"
        self.button_player.setImage(UIImage(named: "player_btn_pause_normal"), forState: .Normal)
        self.button_player.setImage(UIImage(named: "player_btn_pause_highlight"), forState: .Highlighted)
    }
    
    func playItemSong() -> Void {
        self.queuq.playCurrentItem()
        self.queuq.status = .Playing
        self.queuq.listenFeedbackUpdatesWithBlock({ (AFSoundItem soundItem) -> Void in
            print("Item duration: \(soundItem.duration) - time elapsed: \(soundItem.timePlayed)")
            
            // 设置封面总时长
            self.dic2.setObject("\(soundItem.duration)", forKey: MPMediaItemPropertyPlaybackDuration)
            // 设置封面当前时长
            self.dic2.setObject("\(soundItem.timePlayed)", forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
            
            self.dic2.setObject("lyrc......", forKey: MPMediaItemPropertyLyrics)
            // 发送封面信息到控制中心
            MPNowPlayingInfoCenter.defaultCenter().setValue(self.dic2, forKey: "nowPlayingInfo")
            
            self.label_current_time.text = self.formatTime(time: soundItem.timePlayed)
            self.label_end_time.text = self.formatTime(time: soundItem.duration)
            
            // 进度条控制
            self.slider_music.minimumValue = Float(0)
            self.slider_music.maximumValue = Float(soundItem.duration)
            self.slider_music.value = Float(soundItem.timePlayed)
            
            }) { (AFSoundItem soundItem) -> Void in
                print("finished playing")
                self.button_player.setImage(UIImage(named: "player_btn_play_normal"), forState: .Normal)
                self.button_player.setImage(UIImage(named: "player_btn_play_highlight"), forState: .Highlighted)
                self.queuq.status = .Finished
        }
    }
    
    func formatTime(time time:NSInteger) -> String {
        // 1.get the miniutes
        let miniute = time / 60
        // 2.get the seconds
        let second = time % 60
        var min = "\(miniute)"
        var sec = "\(second)"
        if miniute < 10 {
            min = "0\(miniute)"
        }
        if second < 10 {
            sec = "0\(second)"
        }
        return "\(min):\(sec)"
    }
    
    override func viewWillDisappear(animated: Bool) {
        if queuq != nil {
            queuq.removeItem(afsoundItem)
            queuq.clearQueue()
        }
    }
}
