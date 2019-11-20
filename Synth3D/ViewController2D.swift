//
//  ViewController2D.swift
//  Synth3D
//
//  Created by Alexander Obuschenko on 12/11/2019.
//  Copyright © 2019 mutexre. All rights reserved.
//

import UIKit

final class ViewController2D: UIViewController
{
    @IBOutlet private weak var volumeSlider: UISlider!
    @IBOutlet private weak var volumeLabel: UILabel!
    
    @IBOutlet private weak var cutoffSlider: UISlider!
    @IBOutlet private weak var cutoffLabel: UILabel!
    
    @IBOutlet private weak var resonanceSlider: UISlider!
    @IBOutlet private weak var resonanceLabel: UILabel!
    
    @IBOutlet private weak var attackSlider: UISlider!
    @IBOutlet private weak var attackLabel: UILabel!
    
    @IBOutlet private weak var decaySlider: UISlider!
    @IBOutlet private weak var decayLabel: UILabel!
    
    @IBOutlet private weak var sustainSlider: UISlider!
    @IBOutlet private weak var sustainLabel: UILabel!
    
    @IBOutlet private weak var releaseSlider: UISlider!
    @IBOutlet private weak var releaseLabel: UILabel!

    var viewModel: ViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRx()
    }

    private func setupRx()
    {
        viewModel.output.amp.subscribe(onNext: { value in
            self.volumeSlider.value = value
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.filterCutoff.subscribe(onNext: { value in
            self.cutoffSlider.value = value
        }).disposed(by: viewModel.disposeBag)

        viewModel.output.filterResonance.subscribe(onNext: { value in
            self.resonanceSlider.value = value
        }).disposed(by: viewModel.disposeBag)

        viewModel.output.attack.subscribe(onNext: { value in
            self.attackSlider.value = value
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.decay.subscribe(onNext: { value in
            self.decaySlider.value = value
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.sustain.subscribe(onNext: { value in
            self.sustainSlider.value = value
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.release.subscribe(onNext: { value in
            self.releaseSlider.value = value
        }).disposed(by: viewModel.disposeBag)
    }
    
    @IBAction private func volumeSliderChanged(_ sender: UISlider) {
        viewModel.setAmp(sender.value)
    }
    
    @IBAction private func cutoffSliderChanged(_ sender: UISlider) {
        viewModel.setFilterCutoff(sender.value)
    }
    
    @IBAction private func resonanceSliderChanged(_ sender: UISlider) {
        viewModel.setFilterResonance(sender.value)
    }
    
    @IBAction private func attackSliderChanged(_ sender: UISlider) {
        viewModel.setAttack(sender.value)
    }
    
    @IBAction private func decaySliderChanged(_ sender: UISlider) {
        viewModel.setDecay(sender.value)
    }
    
    @IBAction private func sustainSliderChanged(_ sender: UISlider) {
        viewModel.setSustain(sender.value)
    }
    
    @IBAction private func releaseSliderChanged(_ sender: UISlider) {
        viewModel.setRelease(sender.value)
    }
}
