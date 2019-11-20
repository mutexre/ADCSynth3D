//
//  SynthModel.swift
//  Synth3D
//
//  Created by Alexander Obuschenko on 12/11/2019.
//  Copyright © 2019 mutexre. All rights reserved.
//

class SynthModel: Codable
{
    var filterCutoff: Float = 0
    var filterResonance: Float = 0
    var amp: Float = 1
    var attack: Float = 1
    var decay: Float = 1
    var sustain: Float = 0.5
    var release: Float = 1
}
