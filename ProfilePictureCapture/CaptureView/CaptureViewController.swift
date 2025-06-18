//
//  CaptureViewController.swift
//  ProfilePictureCapture
//
//  Created by Wontai Ki on 11/21/24.
//

import AVFoundation
import UIKit

protocol CaptureViewControllerDelegate: AnyObject {
    func capture(image: UIImage)
}

class CaptureViewController: UIViewController {
    
    enum Constants {
        static let maxImageFaceDetection = 10
    }
    
    weak var delegate: CaptureViewControllerDelegate?

    var previewView: PreviewView = PreviewView(frame: .zero)
    var buttonTake = UIButton(frame: .zero)
    var buttonCameraDevice = UIButton(frame: .zero)
    var imageViewBoundBoxs = [UIImageView]()
    
    var videoOutput : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    
    var session : AVCaptureSession!
    var frontDevice : AVCaptureDevice?
    var backDevice : AVCaptureDevice?
    
    var deviceInput : AVCaptureDeviceInput!
    
    var capturedImage : UIImage?
    
    var camCIImage: CIImage?
    
    let lock = NSLock()
    
    init(delegate: CaptureViewControllerDelegate? = nil) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeBoundingImages()
        setupViews()
        requireCameraAccess()
    }
    
    private func setupViews() {
        // PreviewView
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(buttonTake)
        buttonTake.contentVerticalAlignment = .fill
        buttonTake.contentHorizontalAlignment = .fill
        buttonTake.translatesAutoresizingMaskIntoConstraints = false
        buttonTake.setImage(UIImage(systemName: "circle.circle.fill"), for: .normal)
        NSLayoutConstraint.activate([
            buttonTake.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonTake.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            buttonTake.widthAnchor.constraint(equalToConstant: 70),
            buttonTake.heightAnchor.constraint(equalToConstant: 70)
        ])
        buttonTake.addTarget(self, action: #selector(takeButtonClicked(_:)), for: .primaryActionTriggered)
        
        view.addSubview(buttonCameraDevice)
        buttonCameraDevice.contentVerticalAlignment = .fill
        buttonCameraDevice.contentHorizontalAlignment = .fill
        buttonCameraDevice.translatesAutoresizingMaskIntoConstraints = false
        buttonCameraDevice.setImage(UIImage(systemName: "camera.rotate.fill"), for: .normal)
        buttonCameraDevice.isHidden = true
        NSLayoutConstraint.activate([
            buttonCameraDevice.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            buttonCameraDevice.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonCameraDevice.widthAnchor.constraint(equalToConstant: 50),
            buttonCameraDevice.heightAnchor.constraint(equalToConstant: 40)
        ])
        buttonCameraDevice.addTarget(self, action: #selector(changeCameraButtonClicked(_:)), for: .primaryActionTriggered)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.session != nil && !self.session.isRunning) {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.session.stopRunning()
        super.viewDidAppear(animated)
    }
    
    private func makeBoundingImages() {
        for _ in 0 ..< Constants.maxImageFaceDetection {
            let iv = UIImageView(image: UIImage(named: "boundbox"))
            self.previewView.addSubview(iv)
            iv.isHidden = true
            self.imageViewBoundBoxs.append(iv)
        }
    }
    
    private func requireCameraAccess() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted : Bool) in
            Task { @MainActor in
                if (granted) {
                    self.initCameraOverlay()
                }
                else {
                    let alert = UIAlertController(title: "Permission Error", message: "App needs camera access to capture and make a profile image.", preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func initCameraOverlay() {
        session = AVCaptureSession()
        
        session.sessionPreset = AVCaptureSession.Preset.high
        self.previewView.session = session
        
        previewView.layer.masksToBounds = true
        
        // Add Camera Input
        let descoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera , .builtInDualCamera], mediaType: AVMediaType.video, position: .unspecified)
        let devices = descoverySession.devices
        for device in devices {
            if (device.position == .back) {
                self.backDevice = device
                do {
                    deviceInput = try AVCaptureDeviceInput(device: device)
                    if session.canAddInput(deviceInput) {
                        session.addInput(deviceInput)
                    }
                }
                catch {
                    
                }
            }
            if (device.position == .front) {
                // Do something
                self.frontDevice = device
            }
            buttonCameraDevice.isHidden = frontDevice == nil || backDevice == nil
        }
        
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.ds1adr.samplebuffer", attributes: []))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Start the session running to start the flow of data
        DispatchQueue.global().async(execute: { [weak self] in
            self?.session.startRunning()
        })
    }
    
    @objc func changeCameraButtonClicked(_ button : UIButton) {
        button.isEnabled = false
        let currentPosition = deviceInput.device.position
        
        switch currentPosition {
        case .front:
            guard let backDevice else { return }
            do {
                session.removeInput(deviceInput)
                deviceInput = try AVCaptureDeviceInput(device: backDevice)
                
                if session.canAddInput(deviceInput) {
                    session.addInput(deviceInput)
                }
            }
            catch {
                
            }
        case .back:
            guard let frontDevice else { return }
            do {
                session.removeInput(deviceInput)
                deviceInput = try AVCaptureDeviceInput(device: frontDevice)
                
                if session.canAddInput(deviceInput) {
                    session.addInput(deviceInput)
                }
            }
            catch {
                
            }
        default:
            break
        }
        button.isEnabled = true
    }
    
    @objc func takeButtonClicked(_ button : UIButton) {
        // TODO: with camCIImage
        guard let camCIImage, let faces = FaceDetector.detectFace(withCIImage: camCIImage) else {
            return
        }
        
        var minX: CGFloat = camCIImage.extent.width
        var maxX: CGFloat = 0
        var minY: CGFloat = camCIImage.extent.height
        var maxY: CGFloat = 0
        
        if faces.count == 1, let face = faces.first {
            let bounds = face.bounds
            minX = max(0, bounds.center.x - bounds.width)
            maxX = min(camCIImage.extent.width, bounds.center.x + bounds.width)
            minY = max(0, bounds.center.y - bounds.height)
            maxY = min(camCIImage.extent.height, bounds.center.y + bounds.height)
            
            let croppedImage = camCIImage.cropped(to: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY))
            let image = UIImage(ciImage: croppedImage)
            delegate?.capture(image: image)
        } else {
            faces.forEach { face in
                if let face = face as? CIFaceFeature {
                    let bounds = face.bounds
                    minX = min(minX, bounds.origin.x)
                    maxX = max(maxX, bounds.origin.x + bounds.width)
                    minY = min(minY, bounds.origin.y)
                    maxY = max(maxY, bounds.origin.y + bounds.height)
                }
            }
            let length = max(maxX - minX, maxY - minY)
            let center = CGPoint(x: (minX + maxX)/2, y: (minY + maxY)/2)
            
            let boundOrigin = CGPoint(x: max(0, center.x - length * 1.2 / 2), y: max(0, center.y - length * 1.2 / 2))
            let size = CGSize(width: length * 1.2, height: length * 1.2)
            
            let croppedImage = camCIImage.cropped(to: CGRect(origin: boundOrigin, size: size))
            let image = UIImage(ciImage: croppedImage)
            delegate?.capture(image: image)
        }
        dismiss(animated: true)
    }
}

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cameraPosition = deviceInput.device.position
        
        let ciImage = cameraImage.oriented(forExifOrientation: cameraPosition == .back ? 6 : 5)
        self.camCIImage = ciImage
        
        self.detectFace(ciImage: ciImage)
    }
    
    private func detectFace(ciImage: CIImage) {
        DispatchQueue.global().async {
            if self.lock.try() {
                let imageWidth = ciImage.extent.width
                let imageHeight = ciImage.extent.height
                
                if let faces = FaceDetector.detectFace(withCIImage: self.camCIImage!) {
                    DispatchQueue.main.async { [unowned self] in
                        var currentImageIndex = 0
                        
                        for feature in faces {
                            if let face = feature as? CIFaceFeature,
                               (face.hasLeftEyePosition  && face.hasRightEyePosition && face.hasMouthPosition) {
                                
                                let mag = self.previewView.frame.size.width / imageWidth

                                let lp = imageHeight - face.leftEyePosition.y
                                let rp = imageHeight - face.rightEyePosition.y
                                let mp = imageHeight - face.mouthPosition.y
                                
                                let distance = 4*abs(face.rightEyePosition.x - face.leftEyePosition.x)*mag
                                var x = (face.leftEyePosition.x + face.rightEyePosition.x)/2

                                // TODO: Y position has offset
                                let center = CGPoint(x: x * mag, y: mp * mag) //((lp + rp)/2.0 + mp)*mag/2.0 )
                                
                                let iv = self.imageViewBoundBoxs[currentImageIndex]
                                
                                iv.frame = CGRect(x: center.x - distance/2.0, y: center.y - distance/2.0 , width: distance, height: distance)
                                iv.isHidden = false
                            }
                            
                            currentImageIndex += 1
                            if currentImageIndex >= Constants.maxImageFaceDetection {
                                break
                            }
                        }
                        if currentImageIndex < Constants.maxImageFaceDetection {
                            for i in currentImageIndex ..< Constants.maxImageFaceDetection {
                                imageViewBoundBoxs[i].isHidden = true
                            }
                        }
                    }
                }
                self.lock.unlock()
            }
        }

    }
}
