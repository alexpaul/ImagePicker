//
//  ImageCell.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit

// step 1: creating custom delegation - define protocol
protocol ImageCellDelegate: AnyObject { // AnyObject requires ImageCellDelegate only works with class types
  
  // list required functions, initializers, variables
  func didLongPress(_ imageCell: ImageCell)
}

class ImageCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  
  // step 2: creating custom delegation - define optional delegate variable
  weak var delegate: ImageCellDelegate?
  
  // step 1: long press setup
  // setup long press gesture recognizer
  private lazy var longPressGesture: UILongPressGestureRecognizer = {
    let gesture = UILongPressGestureRecognizer()
    gesture.addTarget(self, action: #selector(longPressAction(gesture:)))
    return gesture
  }()
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = 20.0
    backgroundColor = .orange
    
    // step 3: long press setup - added gesture to view
    addGestureRecognizer(longPressGesture)
  }
  
  // step 2: long press setup
  // function gets called when long press is activated
  @objc
  private func longPressAction(gesture: UILongPressGestureRecognizer) {
    if gesture.state == .began { // if gesture is active
      gesture.state = .cancelled
      return
    }
    
    // step 3: creating custom delegation - explicity use
    // delegate object to notify of any updates e.g
    // notifying the ImagesViewController when the user long presses on the cell
    delegate?.didLongPress(self)
    // cell.delegate = self
    // imagesViewController -> didLongPress(:)
  }
  
  public func configureCell(imageObject: ImageObject) {
    // converting Data to UIImage
    guard let image = UIImage(data: imageObject.imageData) else {
      return
    }
    imageView.image = image
  }
}
