//
//  FaceDetector.swift
//  PooCamera
//
//  Created by Won Tai Ki on 9/10/17.
//  Copyright © 2017 KiWontai. All rights reserved.
//

import UIKit
import AVFoundation

class FaceDetector {
    
    static func detectFace(withCIImage ciImage: CIImage) -> [CIFeature]? {
        let option = [CIDetectorAccuracy : CIDetectorAccuracyHigh]
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: option)
        
        return detector?.features(in: ciImage)
    }
    
}
