//
//  SynthEngine.swift
//  Synth3D
//
//  Created by Alexander Obuschenko on 12/11/2019.
//  Copyright © 2019 mutexre. All rights reserved.
//

import AudioKit

final class SynthEngine
{
    private var osc: AKOscillatorBank!
    private let filter = AKLowPassFilter()
    private let delay = AKDelay()
    private let reverb = AKReverb2()
    private let gain = AKBooster()
    private let tuningTable = AKTuningTable()
    
    init()
    {
        let wave = AKTable(.sawtooth, phase: 0, count: 128 * 1024)
        
        osc = AKOscillatorBank(waveform: wave)
        osc.attackDuration = 0.02
        osc.decayDuration = 0.1
        osc.sustainLevel = 0.5
        osc.releaseDuration = 0.1
        
        delay.time = 0.25
        delay.dryWetMix = 0.25
        reverb.dryWetMix = 0.5
        
        osc >>> filter >>> delay >>> reverb >>> gain
        
        AudioKit.output = gain
        do {
            try AudioKit.start()
        } catch let e {
            print("Unable to start AudioKit: \(e)")
        }
        
//        tuningTable.equalTemperament(notesPerOctave: 19)
    }
    
    private func printDevices()
    {
        print("Input devices:")
        AudioKit.inputDevices?.forEach { print($0) }
        
        print("Output devices:")
        AudioKit.outputDevices?.forEach { print($0) }
        
        if let device = AudioKit.inputDevices?[0] {
            try! AudioKit.setInputDevice(device)
        }
        
        if let device = AudioKit.outputDevices?[0] {
            try! AudioKit.setOutputDevice(device)
        }
    }
    
    func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, frequency: Double)
    {
        let freq = tuningTable.frequency(forNoteNumber: noteNumber)
        osc.play(noteNumber: noteNumber, velocity: velocity, frequency: freq)
    }

    func stop(noteNumber: MIDINoteNumber)
    {
        osc.stop(noteNumber: noteNumber)
    }
    
    func setAmp(_ value: Float) {
        gain.gain = Double(value)
    }
    
    func setAttack(_ value: Float) {
        osc.attackDuration = Double(value)
    }
    
    func setDecay(_ value: Float) {
        osc.decayDuration = Double(value)
    }
    
    func setSustain(_ value: Float) {
        osc.sustainLevel = Double(value)
    }
    
    func setRelease(_ value: Float) {
        osc.releaseDuration = Double(value)
    }
    
    func setFilterCutoff(_ value: Float) {
        filter.cutoffFrequency = value * 22050
    }
    
    func setFilterResonance(_ value: Float) {
        filter.resonance = -20 + 60 * Double(value)
    }
    
    func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block tapBlock: @escaping AVAudioNodeTapBlock)
    {
        AudioKit.output?.avAudioUnitOrNode.installTap(onBus: bus, bufferSize: bufferSize, format: format, block: tapBlock)
    }
    
    func removeTap(onBus bus: AVAudioNodeBus)
    {
        AudioKit.output?.avAudioUnitOrNode.removeTap(onBus: bus)
    }
}
