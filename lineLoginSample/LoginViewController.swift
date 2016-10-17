//
//  LoginViewController.swift
//  lineLoginSample
//
//  Created by はるふ on 2016/10/07.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    var lineAdapter: LineAdapter!
    var failedLoginWithAppFlag = false
    
    @IBOutlet var lineLoginButton: UIButton!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMessageLabel.text = ""
        
        lineAdapter = LineAdapter.default()
        
        // Authorizationのステータス変更のobserver
        startObserveLineAdapterNotification()
        
        // ログインボタン。ログインが1パターンなら自動で呼んでも良いかも？
        // adapter.isAuthoralizedならこの時点で画面遷移しても良さそう
        lineLoginButton.addTarget(self, action: #selector(self.lineLoginButtonDidTouch(sender:)), for: .touchUpInside)
    }
    
    private func startObserveLineAdapterNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.lineAdapterAuthorizationDidChange(aNotification:)), name: NSNotification.Name.LineAdapterAuthorizationDidChange, object: nil)
    }
    
    func lineLoginButtonDidTouch(sender: UIButton!) {
        self.lineLoginButton.isEnabled = false
        lineLogin()
        self.lineLoginButton.isEnabled = true
    }
    
    func lineAdapterAuthorizationDidChange(aNotification: Notification) {
        guard let adapter = aNotification.object as? LineAdapter else {
            return
        }
        
        if adapter.isAuthorized {
            errorMessageLabel.text = "ログイン成功"
            lineLoginDidSucceeded()
        } else {
            // error
            guard let error = aNotification.userInfo?["error"] as? NSError else {
                return
            }
            var errorMessage = error.localizedDescription + "\n"
            let errorCode = error.code
            if errorCode == LineAdapterErrorMissingConfiguration {
                errorMessage += "URL Types is not set correctly"
            } else if errorCode == LineAdapterErrorAuthorizationAgentNotAvailable {
                errorMessage += "The LINE application is not installed"
            } else if errorCode == LineAdapterErrorInvalidServerResponse {
                errorMessage += "The response from the server is incorrect"
                print("謎のエラー")
            } else if errorCode == LineAdapterErrorAuthorizationDenied {
                self.lineLoginDidCancel()
                return
            } else if errorCode == LineAdapterErrorAuthorizationFailed {
                // 謎のエラー。これの時、webに投げたほうが良いかも？？
                errorMessage += "再度ログインしてください"
                failedLoginWithAppFlag = true
            }
            errorMessageLabel.text = errorMessage
            print(errorMessage)
        }
    }
    
    func tryApi(handler: @escaping (LineUserInfo?, Error?) -> ()) {
        let lineApiClient = lineAdapter.getLineApiClient()
        lineApiClient?.getMyProfile { (aResult, aError) in
            if let result = aResult {
                let user = LineUserInfo(
                    displayName: result["displayName"] as? String,
                    pictureUrl: result["pictureUrl"] as? String,
                    mid: result["mid"] as? String,
                    statusMessage: result["statusMessage"] as? String)
                handler(user, nil)
            } else {
                handler(nil, aError)
            }
        }
    }
    
    func lineLoginDidSucceeded() {
        print("logged in to LINE")
        // https://developers.line.me/ios/api-reference
        tryApi() { user, error in
            guard let user = user else {
                print(error?.localizedDescription)
                return
            }
            Manager.manager.lineUser = user
            // 画面遷移
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "userInfoViewController") as! UserInfoViewController
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func lineLoginDidCancelOnWeb(sender: Any? = nil) {
        self.dismiss(animated: true, completion: nil)
        lineLoginDidCancel()
    }
    
    func lineLoginDidCancel() {
        errorMessageLabel.text = "キャンセルされました"
    }
    
    func lineLogin() {
        if lineAdapter.isAuthorized {
            print("already authoralized")
            lineLoginDidSucceeded()
        } else {
            if lineAdapter.canAuthorizeUsingLineApp {
                // Authenticate with Appしたいが、うまくいかないので二回目はwebで
                if !failedLoginWithAppFlag {
                    lineLoginWithApp()
                } else {
                    lineLoginWithWeb()
                }
            } else {
                // Authenticate with WebView
                lineLoginWithWeb()
            }
        }
    }
    
    private func lineLoginWithApp() {
        lineAdapter.authorize()
    }
    
    private func lineLoginWithWeb() {
        let vc = LineAdapterWebViewController(adapter: lineAdapter, with: .all)
        vc.navigationItem.leftBarButtonItem = LineAdapterNavigationController.barButtonItem(withTitle: "Cancel", target: self, action: #selector(self.lineLoginDidCancelOnWeb(sender:)))
        let navc = LineAdapterNavigationController(rootViewController: vc)
        self.present(navc, animated: true, completion: nil)
    }
    
    func lineLogout() {
        lineAdapter.unauthorize()
    }
    
}
