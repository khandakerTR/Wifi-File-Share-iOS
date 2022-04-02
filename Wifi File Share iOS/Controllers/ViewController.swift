//
//  ViewController.swift
//  Wifi File Share iOS
//
//  Created by Tushar Khandaker on 3/29/22.
//

import UIKit
import Photos
import GCDWebServer

class ViewController: UIViewController {
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var serverSwitch: UISwitch!
    @IBOutlet weak var serverURLLabel: UILabel!
    
    var webServer: GCDWebUploader!
    var imageList = [String]()
    let imageExtensions = ["png", "jpg", "jpeg", "JPG", "PNG"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageList = ERFileManager.sharedInstance.getFilesFromDirectory(srcPath: BASE_PATH) ?? [""]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setCollectionViewFlowlayout()
        }
        webServer = GCDWebUploader(uploadDirectory: BASE_PATH)
        webServer.delegate = self
    }
    
    @IBAction func didPressOnServerSwitch(_ sender: UISwitch) {
        if sender.isOn {
            if webServer.start() {
                serverURLLabel.isHidden = false
                guard let url = webServer.serverURL else {return}
                serverURLLabel.text = "\(url) Port: \(webServer.port)"
            }
            else {
                print("Not Connected : ")
                sender.isOn = false
            }
        } else if !sender.isOn {
            webServer.stop()
            serverURLLabel.isHidden = true
        }
    }
    @IBAction func didPressPickerButton(_ sender: UIButton) {
        showPhotoLibary()
    }

    func setCollectionViewFlowlayout() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 3
        let width = (imageCollectionView.bounds.width - (2 * 3)) / 3
        layout.itemSize = CGSize(width: width, height: width)
        imageCollectionView.collectionViewLayout = layout
    }
    
    func loadTemplateImageFromDocumentFolader(FileName: String)-> UIImage? {
        guard let endURL = ERFileManager.sharedInstance.getPathFor(directoryType: .documentDirectory, subDirectory: "\(FOLDER_NAME)/\(FileName)") else { return nil}
        let image = UIImage(contentsOfFile: endURL)
        if let img = image {
            return img
        }
        return nil
    }
    
    func getImageList() {
        imageList.removeAll()
        imageList = ERFileManager.sharedInstance.getFilesFromDirectory(srcPath: BASE_PATH) ?? [""]
        imageCollectionView.reloadData()
    }
    
    func checkPhotoLibraryPermission(completion: @escaping CompletionWithSuccess) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] (status) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    completion(self.checkPermissionStatus(for: status))
                }
            }
        }
        else {
            PHPhotoLibrary.requestAuthorization { [weak self] statues in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    completion(self.checkPermissionStatus(for: statues))
                }
            }
        }
    }
    
    func checkPermissionStatus(for status: PHAuthorizationStatus)-> Bool {
        
        switch status {
        case .authorized:
            return true
            
        default:
            return false
        }
    }
    
    func showPhotoLibary() {
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
            self?.showExceededMaximumAlert(vc: picker)
        }
        var configure = TLPhotosPickerConfigure()
        configure.maxSelectedAssets = 20
        configure.numberOfColumn = 3
        configure.allowedVideo = false
        configure.singleSelectedMode = false
        configure.allowedLivePhotos = false
        viewController.configure = configure
        viewController.logDelegate = self as? TLPhotosPickerLogDelegate
        viewController.modalPresentationStyle = .overFullScreen // overFullSceeen is best
        self.present(viewController, animated: true, completion: nil)
    }

    func showExceededMaximumAlert(vc: UIViewController) {
        ERAlertController.showAlert("Alert!", message: "Exceed Maximum Number Of Selection", isCancel: false, okButtonTitle: "OK", cancelButtonTitle: "", completion: nil)
    }
    
    func imageSaveToDocumentFolder(image: UIImage, imageName:String) -> Void {
        autoreleasepool {
            guard let endURL = ERFileManager.sharedInstance.getURLFor(directoryType: .documentDirectory, subDirectory: "\(FOLDER_NAME)/") else { return }
            let data = image.jpegData(compressionQuality: 1.0)
            if let dat = data {
                _ = ERFileManager.sharedInstance.writeItem(directory: endURL, fileName: imageName , fileExtension: FileType.PNG.rawValue, filedata: dat, isOverWrite: true)
            }
        }
    }
}

//MARK: - GCDWebUploaderDelegate
extension ViewController: GCDWebUploaderDelegate {
    
    func webUploader(_: GCDWebUploader, didUploadFileAtPath path: String) {
        print("[UPLOAD] \(path)")
        
        getImageList()
        checkPhotoLibraryPermission { success in
            if !success {
                DispatchQueue.main.async {
                    ERAlertController.showAlert(PHOTOS_PERMISSION_TITLE, message: PHOTOS_PERMISSION_MESSAGE, isCancel: true, okButtonTitle: "Settings", cancelButtonTitle: "Cancel") { isAllowed in
                        if isAllowed {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url, options: [:]) { success in
                                }
                            }
                        }
                    }
                }
            }
            else {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: path)!)
                }) { saved, error in
                    if saved {
                        print("Image saved in Photos")
                    } else {
                        print("Image was not saved to Photos.",error?.localizedDescription as Any)
                    }
                }
            }
        }
    }
    
    func webUploader(_: GCDWebUploader, didDownloadFileAtPath path: String) {
        print("[DOWNLOAD] \(path)")
    }
    
    func webUploader(_: GCDWebUploader, didMoveItemFromPath fromPath: String, toPath: String) {
        print("[MOVE] \(fromPath) -> \(toPath)")
        getImageList()
    }
    
    func webUploader(_: GCDWebUploader, didCreateDirectoryAtPath path: String) {
        print("[CREATE] \(path)")
    }
    
    func webUploader(_: GCDWebUploader, didDeleteItemAtPath path: String) {
        print("[DELETE] \(path)")
        getImageList()
    }
}

//MARK: - TLPhotosPickerViewControllerDelegate
extension ViewController: TLPhotosPickerViewControllerDelegate {
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for asset in withTLPHAssets {
                if let image = asset.fullResolutionImage {
                    let iamgeName = asset.originalFileName?.dropLast(4)
                    self.imageSaveToDocumentFolder(image: image, imageName: String(iamgeName ?? "myImage"))
                }
            }
            self.getImageList()
        }
    }
    
    func photoPickerDidCancel() {
        print("Picker Canceled")
    }
}

//MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CustomCollectionViewCell else { return UICollectionViewCell() }
        
        let imagePath = imageList[indexPath.item]
        let url: URL? = NSURL(fileURLWithPath: imagePath) as URL
        let pathExtention = url?.pathExtension
        if imageExtensions.contains(pathExtention!) {
            cell.imageView.image = loadTemplateImageFromDocumentFolader(FileName: imageList[indexPath.item])
        } else {
            cell.imageView.image = UIImage(named: "files")
        }
        
        return cell
    }
}
