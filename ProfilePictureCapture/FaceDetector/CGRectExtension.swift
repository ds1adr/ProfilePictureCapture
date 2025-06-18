//
//  CGRectExtension.swift
//  ProfilePictureCapture
//
//  Created by Wontai Ki on 11/21/24.
//

import UIKit

extension CGRect {
    var center: CGPoint {
        CGPoint(x: origin.x + size.width / 2.0, y: origin.y + size.height / 2.0)
    }
}
