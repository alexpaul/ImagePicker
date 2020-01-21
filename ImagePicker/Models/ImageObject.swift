//
//  ImageObject.swift
//  ImagePicker
//
//  Created by Alex Paul on 1/20/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation

struct ImageObject: Codable {
  let imageData: Data
  let date: Date
  let identifier = UUID().uuidString
}
