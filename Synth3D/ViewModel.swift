//
//  ViewModel.swift
//  Synth3D
//
//  Created by Alexander Obuschenko on 12/11/2019.
//  Copyright © 2019 mutexre. All rights reserved.
//

import RxSwift
import RxCocoa
import AudioKit

final class ViewModel
{
    struct Output {
        var amp = BehaviorRelay<Float>(value: 0)
        var attack = BehaviorRelay<Float>(value: 0)
        var decay = BehaviorRelay<Float>(value: 0)
        var sustain = BehaviorRelay<Float>(value: 0)
        var release = BehaviorRelay<Float>(value: 0)
        var filterCutoff = BehaviorRelay<Float>(value: 0)
        var filterResonance = BehaviorRelay<Float>(value: 0)
        var audioBuffer = BehaviorRelay<AVAudioPCMBuffer?>(value: nil)
    }
    
    let output = Output()
    
    var state = SynthModel() {
        didSet {
            output.amp.accept(state.amp)
            synthEngine.setAmp(state.amp)
            
            output.attack.accept(state.attack)
            synthEngine.setAttack(state.attack)
            
            output.decay.accept(state.decay)
            synthEngine.setDecay(state.decay)
            
            output.sustain.accept(state.sustain)
            synthEngine.setSustain(state.sustain)
            
            output.release.accept(state.release)
            synthEngine.setRelease(state.release)
            
            output.filterCutoff.accept(state.filterCutoff)
            synthEngine.setFilterCutoff(state.filterCutoff)
            
            output.filterResonance.accept(state.filterResonance)
            synthEngine.setFilterResonance(state.filterResonance)
        }
    }
    
    let disposeBag = DisposeBag()
    
    private let synthEngine = SynthEngine()
    
    func setAmp(_ value: Float) {
        state.amp = value
        synthEngine.setAmp(value)
        output.amp.accept(value)
    }
    
    func setAttack(_ value: Float) {
        state.attack = value
        synthEngine.setAttack(value)
        output.attack.accept(value)
    }
    
    func setDecay(_ value: Float) {
        state.decay = value
        synthEngine.setDecay(value)
        output.decay.accept(value)
    }
    
    func setSustain(_ value: Float) {
        state.sustain = value
        synthEngine.setSustain(value)
        output.sustain.accept(value)
    }
    
    func setRelease(_ value: Float) {
        state.release = value
        synthEngine.setRelease(value)
        output.release.accept(value)
    }
    
    func setFilterCutoff(_ value: Float) {
        state.filterCutoff = value
        synthEngine.setFilterCutoff(value)
        output.filterCutoff.accept(value)
    }
    
    func setFilterResonance(_ value: Float) {
        state.filterResonance = value
        synthEngine.setFilterResonance(value)
        output.filterResonance.accept(value)
    }
    
    func play(noteNumber: MIDINoteNumber) {
        synthEngine.play(noteNumber: noteNumber, velocity: 100, frequency: 440)
    }

    func stop(noteNumber: MIDINoteNumber) {
        synthEngine.stop(noteNumber: noteNumber)
    }
}
