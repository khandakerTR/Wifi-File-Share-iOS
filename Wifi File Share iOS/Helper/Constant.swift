//
//  Constant.swift
//  Wifi File Share iOS
//
//  Created by Tushar Khandaker on 4/2/22.
//

import Foundation

let FOLDER_NAME = "Shared"
let PHOTOS_PERMISSION_TITLE = "Photos Access Denied"
let PHOTOS_PERMISSION_MESSAGE = "This app requires access to your device's Photos.\n\nPlease enable Photos access for this app in Settings / Privacy / Camera"

let BASE_PATH = ERFileManager.sharedInstance.getPathFor(directoryType: .documentDirectory, subDirectory: "\(FOLDER_NAME)")!

typealias CompletionWithSuccess = (_ success: Bool) -> Void
