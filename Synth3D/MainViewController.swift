//
//  MainViewController.swift
//  Synth3D
//
//  Created by Alexander Obuschenko on 15/11/2019.
//  Copyright © 2019 mutexre. All rights reserved.
//

import UIKit

final class MainViewController: UIViewController
{
    @IBOutlet private weak var view3d: UIView!
    @IBOutlet private weak var view2d: UIView!
    @IBOutlet private weak var modeButton: UIButton!
    
    let viewModel = ViewModel()

    private enum Mode {
        case view2D, view3D
    }
    
    private let modeButtonImage2D = UIImage(named: "square_white")
    private let modeButtonImage3D = UIImage(named: "cube")
    
    private var mode: Mode = .view3D {
        didSet {
            switch mode {
            case .view2D:
                view2d.isHidden = false
                view3d.isHidden = true
                modeButton.setImage(modeButtonImage3D, for: .normal)
            case .view3D:
                view2d.isHidden = true
                view3d.isHidden = false
                modeButton.setImage(modeButtonImage2D, for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mode = .view3D
    }
    
    @IBAction private func modeButtonTap(_ sender: UIButton)
    {
        if mode == .view2D {
            mode = .view3D
        } else {
            mode = .view2D
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        super.prepare(for: segue, sender: sender)
        
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier
        {
        case "ViewController2D":
            if let vc = segue.destination as? ViewController2D {
                vc.viewModel = viewModel
            }

        case "ViewController3D":
            if let vc = segue.destination as? ViewController3D {
                vc.viewModel = viewModel
            }
        
        default: break
        }
    }
}
