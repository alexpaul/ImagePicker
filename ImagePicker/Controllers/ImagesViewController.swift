//
//  ViewController.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

// Topics covered today:

/*

 * Used UIAlertControlller to present and action sheet
 * Access the user's photo library
 * Access the user's camera
 * Add the NSCameraUsageDescription key to the info.plist
 * Resized a UIImage using UIGraphicsImageRenderer
 * Implemented UILongPressGestureRecognizer() to present an action sheet for deletion
 * Maintained the aspect ratio of the image using AVMakeRect (AVFoundation framework)
 * Create a custom delegate to notify the ImagesViewController about long presss from the ImageCell
 * Persisted image objects to the documents directory (create, read, delete)
 
 Other features we can add
 * Share an image along with text to a user via SMS, Facebook, ........
 * Automatically save original image taken to the photo library UIImageWriteToPhotosAlbum
 
*/

import UIKit
import AVFoundation // we want to use AVMakeRect() to maintain image aspect ratio

class ImagesViewController: UIViewController {
  
  @IBOutlet weak var collectionView: UICollectionView!
      
  private var imageObjects = [ImageObject]()
  
  private let imagePickerController = UIImagePickerController()
  
  private let dataPersistence = PersistenceHelper(filename: "images.plist")
  
  private var selectedImage: UIImage? {
    didSet {
      // gets called when new image is selected
      appendNewPhotoToCollection()
    }
  }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    
    // set UIImagePickerController delegate as this view controller
    imagePickerController.delegate = self
    
    loadImageObjects()
  }
  
  private func loadImageObjects() {
    do {
      imageObjects = try dataPersistence.loadItems()
    } catch {
      print("loading objects error: \(error)")
    }
  }
  
  private func appendNewPhotoToCollection() {
    guard let image = selectedImage else {
      print("image is nil")
      return
    }
    
    print("original image size is \(image.size)")
    
    // the size for resizing of the image
    let size = UIScreen.main.bounds.size
        
    // we will maintain the aspect ratio of the image
    let rect = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: CGPoint.zero, size: size))
    
    // resize image
    let resizeImage = image.resizeImage(to: rect.size.width, height: rect.size.height)
    
    print("resized image size is \(resizeImage.size)")
    
    // jpegData(compressionQuality: 1.0) converts UIImage to Data
    guard let resizedImageData = resizeImage.jpegData(compressionQuality: 1.0) else {
      return
    }    // create an ImageObject using the image selected
    let imageObject = ImageObject(imageData: resizedImageData, date: Date())
    
    // insert new imageObject into imageObjects
    imageObjects.insert(imageObject, at: 0) // 51
        
    // create an indexPath for insertion into collection view
    let indexPath = IndexPath(row: 0, section: 0)
    
    // insert new cell into collection view
    collectionView.insertItems(at: [indexPath])
    
    // persist imageObject to documents directory
    do {
      try dataPersistence.create(item: imageObject) // end of array in persistence store
    } catch {
      print("saving error: \(error)")
    }
  }
  
  @IBAction func addPictureButtonPressed(_ sender: UIBarButtonItem) {
    // present an action sheet to ther user
    // actions: camera, photo library, cancel
    
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] alertAction in
      self?.showImageController(isCameraSelected: true)
    }
    
    let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] alertAction in
      self?.showImageController(isCameraSelected: false)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    // check if camera is available, if camera is not available and you attempt to show
    // the camera the app will crash
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      alertController.addAction(cameraAction)
    }
    
    alertController.addAction(photoLibraryAction)
    alertController.addAction(cancelAction)
    present(alertController, animated: true)
  }
  
  private func showImageController(isCameraSelected: Bool) {
    // source type default will be .photoLibrary
    imagePickerController.sourceType = .photoLibrary
    
    if isCameraSelected {
      imagePickerController.sourceType = .camera
    }
    present(imagePickerController, animated: true)
  }
  
}

// MARK: - UICollectionViewDataSource
extension ImagesViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageObjects.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // step 4: creating custom delegation - must have an instance of object B
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImageCell else {
      fatalError("could not downcast to an ImageCell")
    }
    let imageObject = imageObjects[indexPath.row]
    cell.configureCell(imageObject: imageObject)
    // step 5: creating custom delegation - set delegate object
    // similar to tableView.delegate = self
    cell.delegate = self
    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ImagesViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let maxWidth: CGFloat = UIScreen.main.bounds.size.width
    let itemWidth: CGFloat = maxWidth * 0.80
    return CGSize(width: itemWidth, height: itemWidth)  }
}

extension ImagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    // we need to access the UIImagePickerController.InfoKey.orginalImage key to get the
    // UIImage that was selected
    guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
      print("image selected not found")
      return
    }
    
    selectedImage = image
    
    dismiss(animated: true)
  }
}

// step 6: creating custom delegation - conform to delegate
extension ImagesViewController: ImageCellDelegate {
  func didLongPress(_ imageCell: ImageCell) {
    
    guard let indexPath = collectionView.indexPath(for: imageCell) else {
      return
    }
    
    // present an action sheet
    
    // actions: delete, cancel
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] alertAction in
      self?.deleteImageObject(indexPath: indexPath)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    present(alertController, animated: true)
  }
  
  private func deleteImageObject(indexPath: IndexPath) {
    dataPersistence.sync(items: imageObjects)
    do {
      imageObjects = try dataPersistence.loadItems()
    } catch {
      print("loading error: \(error)")
    }
    
    // delete imageObject from imageObjects
    imageObjects.remove(at: indexPath.row)
    
    // delete cell from collection view
    collectionView.deleteItems(at: [indexPath])
    
    do {
      // delete image object from documents directory
      try dataPersistence.delete(item: indexPath.row)
    } catch {
      print("error deleting item: \(error)")
    }
  }
}

// more here: https://nshipster.com/image-resizing/
// MARK: - UIImage extension
extension UIImage {
  func resizeImage(to width: CGFloat, height: CGFloat) -> UIImage {
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { (context) in
      self.draw(in: CGRect(origin: .zero, size: size))
    }
  }
}

