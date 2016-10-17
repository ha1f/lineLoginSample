//
//  UserInfoViewController.swift
//  lineLoginSample
//
//  Created by はるふ on 2016/10/07.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import UIKit

class UserInfoViewController: UIViewController {
    
    var userInfo = Manager.manager.lineUser

    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var midLabel: UILabel!
    @IBOutlet weak var pictureUrlLabel: UILabel!
    @IBOutlet weak var statusMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        displayNameLabel.text = userInfo.displayName
        midLabel.text = userInfo.mid
        pictureUrlLabel.text = userInfo.pictureUrl
        statusMessageLabel.text = userInfo.statusMessage
    }

}

