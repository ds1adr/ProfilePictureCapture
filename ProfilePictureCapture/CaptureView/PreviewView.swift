//
//  PreviewView.swift
//  ProfilePictureCapture
//
//  Created by Wontai Ki on 11/21/24.
//

import AVFoundation
import UIKit

class PreviewView: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
