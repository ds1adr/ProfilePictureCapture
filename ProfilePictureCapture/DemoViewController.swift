//
//  ViewController.swift
//  ProfilePictureCapture
//
//  Created by Wontai Ki on 11/21/24.
//

import UIKit

class DemoViewController: UIViewController {
    
    var imageView = UIImageView(frame: .zero)
    var button = UIButton(type: .system)
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo"
        view.backgroundColor = .white
        
        setupViews()
    }

    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(button)
        
        button.setTitle("Capture", for: .normal)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureButtonClicked(_:)), for: .primaryActionTriggered)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1),
            button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func captureButtonClicked(_ sender: UIButton) {
        let captureViewController = CaptureViewController()
        captureViewController.modalPresentationStyle = .fullScreen
        
        present(captureViewController, animated: true)
    }
}

