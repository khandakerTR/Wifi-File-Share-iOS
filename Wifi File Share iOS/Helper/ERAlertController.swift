//
//  ERAlertController.swift
//  ERAlertController
//
//  Created by Mohammad Hasan on 2/16/17.
//  Copyright © 2017 Matrix Solution. All rights reserved.
//

import UIKit

class ERAlertController: NSObject {
    
    class func showAlert(_ title : String, message: String, isCancel: Bool, okButtonTitle: String, cancelButtonTitle: String, completion: ((Bool)->())?) {
        let alertController = AlertController(title: title, message: message, preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: okButtonTitle, style: .default) { action -> Void in
            if completion != nil {
                completion!(true)
            }
        }
        alertController.addAction(okButton)
        
        if isCancel {
            
            let cancelButton = UIAlertAction(title: cancelButtonTitle, style: .cancel){ action -> Void in
                if completion != nil {
                    completion!(false)
                }
            }
            alertController.addAction(cancelButton)
        }
        
        alertController.present(animated: true, completion: nil)
    }
    
    class func showAlertWithTextInput(title:String? = nil,
                                      subtitle:String? = nil,
                                      actionTitle:String? = "Add",
                                      cancelTitle:String? = "Cancel",
                                      inputPlaceholder:String? = nil,
                                      inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                                      cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                                      actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alertController = AlertController(title: title, message: subtitle, preferredStyle: .alert)
        
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alertController.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        
        alertController.present(animated: true, completion: nil)
    }
}

private var windows: [String:UIWindow] = [:]

extension UIWindowScene {
    static var focused: UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }
}

class AlertController: UIAlertController {
    
    var wid: String?
    
    func present(animated: Bool, completion: (() -> Void)?) {
        
        guard let window = UIWindowScene.focused.map(UIWindow.init(windowScene:)) else {
            return
        }
        window.rootViewController = UIViewController()
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()
        window.rootViewController!.present(self, animated: animated, completion: completion)
        
        wid = UUID().uuidString
        windows[wid!] = window
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let wid = wid {
            windows[wid] = nil
        }
    }
}
