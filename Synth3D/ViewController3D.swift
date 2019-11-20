//
//  ViewController.swift
//  Synth3D
//
//  Created by Alexander Obuschenko on 28/09/2019.
//  Copyright © 2019 mutexre. All rights reserved.
//

import UIKit
import CoreMotion
import SceneKit
import AudioKit
import AudioKitUI

final class ViewController3D: UIViewController
{
    @IBOutlet private weak var sceneView: SCNView!
    
    var viewModel: ViewModel!
    
    private let scene = SCNScene(named: "Items.scnassets/Synth.scn")!
    
    // MARK: Camera
    
    private let cameraNode = SCNNode()
    private let camera = SCNCamera()
    
    private var cameraDistance: Float = 1.1
    private static let defaultCameraEulerAngles = float3(-0.25 * Float.pi, 0, 0)
    private var cameraEulerAngles: float3 = ViewController3D.defaultCameraEulerAngles

    private var enableParallaxUpdates = true
    private var parallaxEffectAngles = float3(0)
    private let parallaxRate: Float = 0.00035
    private let maxParallaxAngle: Float = (3 / 360.0) * 2 * Float.pi
    
    // MARK: Nodes
    
    private var synthesizer: SCNNode!
    private var table: SCNNode!
    private var bodyTop: SCNNode!
    
    private var keyboard: SCNNode!
    private var keys: [SCNNode] = []
    
    private var fadersRoot: SCNNode!
    private var faders: [SCNNode] = []
    
    private var knobsRoot: SCNNode!
    private var knobs: [SCNNode] = []
    
    private var wheelsRoot: SCNNode!
    private var pitchWheel: SCNNode!
    private var modWheel: SCNNode!
    
    private var leds: SCNNode!
    private var led: SCNNode!
    
    private var pressWhite: SCNAction!
    private var pressBlack: SCNAction!
    private var release: SCNAction!
    
    private let whiteMaterial = SCNMaterial()
    private let blackMaterial = SCNMaterial()
    
    private var lcdMaterial: SCNMaterial!

    private let minFaderZ: Float = -0.7
    private let maxFaderZ: Float = +0.7

    private var faderZRange: Float {
        return maxFaderZ - minFaderZ
    }

    private let minKnobAngle = -0.7 * Float.pi
    private let maxKnobAngle = +0.7 * Float.pi
    
    private var knobAngularRange: Float {
        return maxKnobAngle - minKnobAngle
    }
    
    // MARK: Touch support
    
    private var backgroundTouch: UITouch?
    private var touchedKeys: [UITouch : Set<SCNNode>] = [:]
    private var touchedKnobs: [UITouch : SCNNode] = [:]
    private var touchedFaders: [UITouch : SCNNode] = [:]
    
    // MARK: Hit testing
    
    private var keysHitTestOptions: [SCNHitTestOption : Any]!
    private var faderHitTestOptions: [SCNHitTestOption : Any]!
    private var knobHitTestOptions: [SCNHitTestOption : Any]!
    
    private var faderHitVolumes: [SCNNode] = []
    private var knobHitVolumes: [SCNNode] = []
    
    private var showHitVolumes: Bool = false {
        didSet {
            faderHitVolumes.forEach { $0.isHidden = !showHitVolumes }
            knobHitVolumes.forEach { $0.isHidden = !showHitVolumes }
        }
    }
    
    // MARK: LCD Screen
    
    private let lcdScreenSize = CGSize(width: 256, height: 256)
    
    private let firstLinePosition = CGPoint(x: 10, y: 7)
    private let secondLinePositionNormal = CGPoint(x: 10, y: 50)
    private let secondLinePositionSmall = CGPoint(x: 10, y: 70)
    
    private let lineAttrsTop: [NSAttributedString.Key:Any] = [
        NSAttributedString.Key.font: UIFont(name: "DS-Digital-Italic", size: 60)!,
        NSAttributedString.Key.foregroundColor: UIColor(hue: 0, saturation: 0.0, brightness: 0.9, alpha: 1)
    ]
    
    private let lineAttrsNormal: [NSAttributedString.Key:Any] = [
        NSAttributedString.Key.font: UIFont(name: "DS-Digital-Italic", size: 90)!,
        NSAttributedString.Key.foregroundColor: UIColor(hue: 0, saturation: 0.0, brightness: 0.9, alpha: 1)
    ]
    
    private let lineAttrsSmall: [NSAttributedString.Key:Any] = [
        NSAttributedString.Key.font: UIFont(name: "DS-Digital-Italic", size: 70)!,
        NSAttributedString.Key.foregroundColor: UIColor(hue: 0, saturation: 0.0, brightness: 0.9, alpha: 1)
    ]
    
    private let plot = EZAudioPlot(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    
    // MARK: Motion tracking
    
    private let motionManager = CMMotionManager()
    
    private let startMidiNote = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMaterials()
        setupAnimations()
        setupSceneView()
        setupScene()
        setupKeys()
        setupControls()
        setupCamera()
        setupLights()
        setupGyroscope()
        setupRx()
        
        showHitVolumes = false
    }

    private func setupRx()
    {
        viewModel.output.amp.subscribe(onNext: { value in
            self.knobs[0].simdEulerAngles.y = self.minKnobAngle + (1 - value) * self.knobAngularRange
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.filterCutoff.subscribe(onNext: { value in
            self.knobs[1].simdEulerAngles.y = self.minKnobAngle + (1 - value) * self.knobAngularRange
        }).disposed(by: viewModel.disposeBag)

        viewModel.output.filterResonance.subscribe(onNext: { value in
            self.knobs[2].simdEulerAngles.y = self.minKnobAngle + (1 - value) * self.knobAngularRange
        }).disposed(by: viewModel.disposeBag)

        viewModel.output.attack.subscribe(onNext: { value in
            self.faders[0].simdPosition.z = self.minFaderZ + (1 - value) * self.faderZRange
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.decay.subscribe(onNext: { value in
            self.faders[1].simdPosition.z = self.minFaderZ + (1 - value) * self.faderZRange
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.sustain.subscribe(onNext: { value in
            self.faders[2].simdPosition.z = self.minFaderZ + (1 - value) * self.faderZRange
        }).disposed(by: viewModel.disposeBag)
        
        viewModel.output.release.subscribe(onNext: { value in
            self.faders[3].simdPosition.z = self.minFaderZ + (1 - value) * self.faderZRange
        }).disposed(by: viewModel.disposeBag)
        
//        plot.shouldOptimizeForRealtimePlot = false
//        view.addSubview(plot)
//        plot.color = UIColor(white: 1, alpha: 1)
        
//        viewModel.output.audioBuffer.subscribe(onNext: { buf in
//            guard let floatBuf = buf?.floatChannelData?[0] else {
//                return
//            }
//            DispatchQueue.main.async {
//                self.plot.updateBuffer(floatBuf, withBufferSize: 1024)
//                UIGraphicsBeginImageContext(CGSize(width: 64, height: 100))
//                self.plot.layer.render(in: UIGraphicsGetCurrentContext()!)
//                let image = UIGraphicsGetImageFromCurrentImageContext()
//                self.lcdMaterial.emission.contents = image!
//                UIGraphicsEndImageContext()
//            }
//        }).disposed(by: viewModel.disposeBag)
    }

    private func setupSceneView()
    {
//        sceneView.backgroundColor = .orange
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = scene
        sceneView.antialiasingMode = .multisampling4X
//        sceneView.contentScaleFactor *= 2
    }

    private func setupScene()
    {
        let backgroundImage = UIImage(named: "pillars_4k")
        scene.background.contents = backgroundImage
        scene.lightingEnvironment.contents = backgroundImage
        scene.lightingEnvironment.intensity = 1
        
        synthesizer = scene.rootNode.childNode(withName: "synthesizer", recursively: false)!
        table = scene.rootNode.childNode(withName: "table", recursively: false)!
        keyboard = synthesizer.childNode(withName: "keyboard", recursively: false)!
        bodyTop = synthesizer.childNode(withName: "body_top", recursively: false)!

        lcdMaterial = bodyTop.geometry?.materials[2]
        let scale = SCNMatrix4MakeScale(-1, -1, 1)
        lcdMaterial.emission.contentsTransform = SCNMatrix4Translate(scale, 1, 0.55, 0)

//        let blur = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius" : 0.5])!
//        scene.rootNode.filters = [blur]

        let boundingBox = synthesizer.boundingBox
        
        let boundingBoxCenter = float3(
            (boundingBox.min.x + boundingBox.max.x) / 2,
            (boundingBox.min.y + boundingBox.max.y) / 2,
            (boundingBox.min.z + boundingBox.max.z) / 2)
        
        synthesizer.simdPosition = -synthesizer.simdScale * boundingBoxCenter
        table.simdPosition -= synthesizer.simdScale * boundingBoxCenter
    }
    
    private func setupKeys()
    {
        keys = (1 ... 25).map { index in
            keyboard.childNode(withName: "key_\(index)", recursively: false)!
        }
        
//        let pivot = scene.rootNode.childNode(withName: "pivot", recursively: false)!
//        let translation = SCNMatrix4MakeTranslation(0, pivot.position.y, pivot.position.z)
//        let simdPivot = float4x4(translation)
        
        for i in 0 ..< keys.count {
            let key = keys[i]
//            key.simdPivot = simdPivot
            let material = ViewController3D.isBlack(i) ? blackMaterial : whiteMaterial
            key.geometry!.materials = [ material ]
        }
        
        keysHitTestOptions = [
            .rootNode: keyboard,
            .boundingBoxOnly: true,
            .firstFoundOnly : true
        ]
    }
    
    private func setupControls()
    {
        setupFaders()
        setupKnobs()
        setupWheels()
//        led = scene.rootNode.childNode(withName: "leds", recursively: false)!
    }
    
    private static let faderCategoryBit = 0b010
    private static let knobCategoryBit = 0b0100
    
    private func setupFaders()
    {
        fadersRoot = synthesizer.childNode(withName: "faders", recursively: false)!
        
        faders = (1 ... 4).map { index in
            fadersRoot.childNode(withName: "fader_\(index)", recursively: false)!
        }
        
        let hitVolumeGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        
        for i in 0 ..< faders.count
        {
            let fader = faders[i]
            let bb = fader.boundingBox
            
            let hitVolume = SCNNode(geometry: hitVolumeGeometry)
            hitVolume.isHidden = false
            hitVolume.opacity = 0.5
            hitVolume.name = String(i)
            hitVolume.simdTransform = fader.simdTransform
            hitVolume.scale = SCNVector3Make(
                3.75 * (bb.max.x - bb.min.x),
                3 * (bb.max.y - bb.min.y),
                3 * (bb.max.z - bb.min.z))
            hitVolume.categoryBitMask = ViewController3D.faderCategoryBit
            fadersRoot.addChildNode(hitVolume)
            faderHitVolumes.append(hitVolume)
        }
        
        faderHitTestOptions = [
//            .boundingBoxOnly : true,
            .categoryBitMask : ViewController3D.faderCategoryBit,
            .ignoreHiddenNodes : false,
            .firstFoundOnly : true
        ]
    }
    
    private func setupKnobs()
    {
        knobsRoot = synthesizer.childNode(withName: "knobs", recursively: false)!
        
        knobs = (1 ... 3).map { index in
            knobsRoot.childNode(withName: "knob_\(index)", recursively: false)!
        }
        
        let hitVolumeGeometry = SCNCylinder(radius: 0.75, height: 1)

        for i in 0 ..< knobs.count
        {
            let knob = knobs[i]
            let bb = knob.boundingBox
            
            let m = SCNMatrix4MakeTranslation(0.5 * (bb.min.x + bb.max.x), 0, 0.5 * (bb.min.z + bb.max.z))
            knob.simdPivot = float4x4(m)
            
            let hitVolume = SCNNode(geometry: hitVolumeGeometry)
            hitVolume.isHidden = false
            hitVolume.opacity = 0.5
            hitVolume.name = String(i)
            hitVolume.simdPosition = float3(0.5 * (bb.min.x + bb.max.x), 0, 0.5 * (bb.min.z + bb.max.z))
            hitVolume.categoryBitMask = ViewController3D.knobCategoryBit
            knob.addChildNode(hitVolume)
            knobHitVolumes.append(hitVolume)
        }
        
        knobHitTestOptions = [
//            .boundingBoxOnly : true,
            .categoryBitMask : ViewController3D.knobCategoryBit,
            .ignoreHiddenNodes : false,
            .firstFoundOnly : true
        ]
    }
    
    private func setupWheels()
    {
        wheelsRoot = synthesizer.childNode(withName: "wheels", recursively: false)!
        pitchWheel = wheelsRoot.childNode(withName: "pitch", recursively: false)!
        modWheel = wheelsRoot.childNode(withName: "modulation", recursively: false)!
    }
    
    private var synthCenter: float3
    {
        let boundingBox = synthesizer.boundingBox
        
        let boundingBoxCenter = float3(
            (boundingBox.min.x + boundingBox.max.x) / 2,
            (boundingBox.min.y + boundingBox.max.y) / 2,
            (boundingBox.min.z + boundingBox.max.z) / 2)
        
        return synthesizer.simdPosition + boundingBoxCenter
    }
    
    func makeTranslationMatrix(_ tr: float3) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4
        
        matrix[0, 3] = tr.x
        matrix[1, 3] = tr.y
        matrix[2, 3] = tr.z
        
        return matrix.transpose
    }
    
    private func setupCamera()
    {
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        
        cameraNode.camera = camera
        cameraNode.simdPosition = float3(0, 0, 0)
        cameraNode.simdEulerAngles = ViewController3D.defaultCameraEulerAngles
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, -cameraDistance)
        
        camera.focalLength = 40
        camera.zNear = 0.01
        camera.zFar = 10
        
        camera.wantsDepthOfField = true
        camera.fStop = 0.5
        camera.focusDistance = CGFloat(cameraDistance)
        
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = 1
        
//        let camera = scene.rootNode.childNode(withName: "camera", recursively: false)!
//        scene.rootNode.addChildNode(camera)
        
//        camera.camera!.motionBlurIntensity = 1
        
//        let pivot = keyboardScene.rootNode.childNode(withName: "pivot", recursively: false)!
//        let translation = SCNMatrix4MakeTranslation(0, pivot.position.y, pivot.position.z)
//        camera.simdPivot = float4x4(translation)
    }
    
    private func setupLights()
    {
        setupSpotLight1()
        setupSpotLight2()
    }
    
    private func setupSpotLight1()
    {
        let spotLight = scene.rootNode.childNode(withName: "spotLight", recursively: true)!
//        scene.rootNode.addChildNode(spotLight)
        spotLight.light!.color = UIColor(hue: 0.7, saturation: 0.7, brightness: 1, alpha: 1)
        
        let angles = spotLight.eulerAngles
        let angle = (15.0 / 360) * 2 * CGFloat.pi
        let duration: TimeInterval = 6
        
        let rotateLeft = SCNAction.rotateTo(
            x: CGFloat(angles.x) - angle,
            y: CGFloat(angles.y),
            z: CGFloat(angles.z),
            duration: duration)
        
        let rotateRight = SCNAction.rotateTo(
            x: CGFloat(angles.x) + angle,
            y: CGFloat(angles.y),
            z: CGFloat(angles.z),
            duration: duration)
        
        let rotate = SCNAction.sequence([ rotateLeft, rotateRight ])
        let repeatRotation = SCNAction.repeatForever(rotate)
//        spotLight.runAction(repeatRotation)
    }
    
    private func setupSpotLight2()
    {
        let spotLight2 = scene.rootNode.childNode(withName: "spotLight2", recursively: true)!
//        scene.rootNode.addChildNode(spotLight2)
        spotLight2.light!.color = UIColor(hue: 0.1, saturation: 0.7, brightness: 1, alpha: 1)
        
        let angles = spotLight2.eulerAngles
        let angle = (120.0 / 360) * 2 * CGFloat.pi
        let duration: TimeInterval = 9
        
        let rotateLeft = SCNAction.rotateTo(
            x: CGFloat(angles.x),
            y: CGFloat(angles.y) - angle,
            z: CGFloat(angles.z),
            duration: duration)
        
        let rotateRight = SCNAction.rotateTo(
            x: CGFloat(angles.x),
            y: CGFloat(angles.y) + angle,
            z: CGFloat(angles.z),
            duration: duration)
        
        let rotate = SCNAction.sequence([ rotateLeft, rotateRight ])
        let repeatRotation = SCNAction.repeatForever(rotate)
//        spotLight2.runAction(repeatRotation)
    }
    
    private func setupAnimations()
    {
        let angleWhite = CGFloat((5.0 / 360) * 2 * Float.pi)
        let angleBlack = CGFloat((7.0 / 360) * 2 * Float.pi)
        let timingMode: SCNActionTimingMode = .linear

        pressWhite = SCNAction.rotateTo(x: angleWhite, y: 0, z: 0, duration: 0.0)
        pressWhite.timingMode = timingMode

        pressBlack = SCNAction.rotateTo(x: angleBlack, y: 0, z: 0, duration: 0.0)
        pressBlack.timingMode = timingMode
        
        release = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.07)
        release.timingMode = timingMode
    }
    
    private func setupMaterials()
    {
        whiteMaterial.lightingModel = .physicallyBased
        whiteMaterial.metalness.contents = 0
        whiteMaterial.roughness.contents = 0.3
        whiteMaterial.diffuse.contents = UIColor(white: 0.8, alpha: 1)
        whiteMaterial.isDoubleSided = true
        
        blackMaterial.lightingModel = .physicallyBased
        blackMaterial.metalness.contents = 0
        blackMaterial.roughness.contents = 0.3
        blackMaterial.diffuse.contents = UIColor(white: 0.0, alpha: 1)
        blackMaterial.isDoubleSided = true
    }
    
    private func setupGyroscope()
    {
        motionManager.startGyroUpdates(to: .main) { (data: CMGyroData?, error: Error?) in
            guard let data = data, error == nil else {
                print("Gyroscope error \(error)")
                return
            }
            self.updateParallaxAngles(data.rotationRate)
//            print(data)
        }
    }
    
    private func updateParallaxAngles(_ rotationRate: CMRotationRate)
    {
        guard enableParallaxUpdates else {
            return
        }
        
        parallaxEffectAngles.x += parallaxRate * Float(rotationRate.y)
        parallaxEffectAngles.x = max(parallaxEffectAngles.x, -maxParallaxAngle)
        parallaxEffectAngles.x = min(parallaxEffectAngles.x, +maxParallaxAngle)
        
        parallaxEffectAngles.y += parallaxRate * Float(rotationRate.z)
        parallaxEffectAngles.y = max(parallaxEffectAngles.y, -maxParallaxAngle)
        parallaxEffectAngles.y = min(parallaxEffectAngles.y, +maxParallaxAngle)
        
        updateCameraEulerAngles()
    }
    
    private func updateCameraEulerAngles()
    {
        cameraNode.simdEulerAngles = cameraEulerAngles + parallaxEffectAngles
    }
    
    private static func isBlack(_ index: Int) -> Bool {
        let i = index % 12
        return i == 1 || i == 3 || i == 5 || i == 8 || i == 10
    }
    
    private struct LCDTextLine
    {
        var text: NSAttributedString
        var position: CGPoint
        var horizontalAlignment: NSTextAlignment
    }
    
    private func renderLCDScreen(_ textLines: [LCDTextLine]) -> UIImage?
    {
        UIGraphicsBeginImageContext(lcdScreenSize)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: lcdScreenSize))
        
        for line in textLines
        {
            var pos = CGPoint(x: 0, y: line.position.y)
            
            switch line.horizontalAlignment
            {
            case .left:
                pos.x = line.position.x
            
            case .right:
                let boundingRect = line.text.boundingRect(
                    with: .zero,
                    options: NSStringDrawingOptions.usesLineFragmentOrigin,
                    context: nil)
                pos.x = lcdScreenSize.width - boundingRect.size.width - line.position.x
                
            case .center:
                let boundingRect = line.text.boundingRect(
                    with: .zero,
                    options: NSStringDrawingOptions.usesLineFragmentOrigin,
                    context: nil)
                pos.x = 0.5 * (lcdScreenSize.width - boundingRect.size.width)
            
            default: fatalError("LCD screen doesn't support \(line.horizontalAlignment) text alignment")
            }
            
            line.text.draw(at: pos)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension ViewController3D
{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        for touch in touches
        {
            let p = touch.location(in: sceneView)
            
            let knobResults = sceneView.hitTest(p, options: knobHitTestOptions)
            if let node = knobResults.first?.node,
               let name = node.name,
               let knobIndex = Int(name)
            {
                touchedKnobs[touch] = knobs[knobIndex]
                continue
            }
            
            let faderResults = sceneView.hitTest(p, options: faderHitTestOptions)
            if let node = faderResults.first?.node,
               let name = node.name,
               let faderIndex = Int(name)
            {
                touchedFaders[touch] = faders[faderIndex]
                continue
            }
            
            let results = sceneView.hitTest(p, options: keysHitTestOptions)
            let keyNodes = results.compactMap { (result: SCNHitTestResult) -> SCNNode? in
                let node = result.node
                if node.name?.starts(with: "key_") ?? false {
                    return node
                }
                return nil
            }
            
            touchedKeys[touch] = Set(keyNodes)
            for node in keyNodes {
                pressKey(node)
            }
            
            if !keyNodes.isEmpty {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2
                lcdMaterial.emission.intensity = 0.25
                SCNTransaction.commit()
            }
            
            if keyNodes.isEmpty, backgroundTouch == nil {
                backgroundTouch = touch
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesMoved(touches, with: event)
        for touch in touches
        {
            let p = touch.location(in: sceneView)
            var lcdTextLines: [LCDTextLine]?
            
            if touch == backgroundTouch
            {
                let prev = touch.previousLocation(in: sceneView)
                let dx = Float(p.x - prev.x)
                let dy = Float(p.y - prev.y)
                let rotationRate: Float = 0.01
                cameraEulerAngles -= rotationRate * float3(dy, dx, 0)
                cameraEulerAngles.x = simd_clamp(cameraEulerAngles.x, -0.5 * Float.pi, 0)
                updateCameraEulerAngles()
            }
            else if let knob = touchedKnobs[touch]
            {
                let prev = touch.previousLocation(in: sceneView)
                let dy = p.y - prev.y
                
                knob.eulerAngles.y += Float(0.03 * dy)
                knob.eulerAngles.y = simd_clamp(knob.eulerAngles.y, minKnobAngle, maxKnobAngle)
                
                let controlValue = 1 - (knob.eulerAngles.y - minKnobAngle) / knobAngularRange
                
                switch knob.name {
                case "knob_1":
                    viewModel.setAmp(controlValue)
                    let intControlValue = Int((100 * controlValue).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "amp", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: "\(intControlValue)%", attributes: lineAttrsNormal),
                            position: secondLinePositionNormal,
                            horizontalAlignment: .right)
                    ]
                    
                case "knob_2":
                    viewModel.setFilterCutoff(controlValue)
                    let freq = Int((controlValue * 22.05).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "cutoff", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: String(format: "%.2f kHz", freq), attributes: lineAttrsSmall),
                            position: secondLinePositionSmall,
                            horizontalAlignment: .right)
                    ]
                    
                case "knob_3":
                    viewModel.setFilterResonance(controlValue)
                    let db = Int((-20 + controlValue * 60).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "res", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: "\(db)", attributes: lineAttrsNormal),
                            position: secondLinePositionNormal,
                            horizontalAlignment: .right)
                    ]
                    
                default: break
                }
            }
            else if let fader = touchedFaders[touch]
            {
                let prev = touch.previousLocation(in: sceneView)
                let dy = p.y - prev.y

                fader.position.z += Float(0.015 * dy)
                fader.position.z = simd_clamp(fader.position.z, minFaderZ, maxFaderZ)

                let controlValue = 1 - (fader.position.z - minFaderZ) / faderZRange
                let intControlValue = Int((127 * controlValue).rounded(.down))

                switch fader.name {
                case "fader_1":
                    viewModel.setAttack(controlValue)
                    let ms = Int((1000 * controlValue).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "attack", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: "\(ms) ms", attributes: lineAttrsSmall),
                            position: secondLinePositionSmall,
                            horizontalAlignment: .right)
                    ]
                    
                case "fader_2":
                    viewModel.setDecay(controlValue)
                    let ms = Int((1000 * controlValue).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "decay", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: "\(ms) ms", attributes: lineAttrsSmall),
                            position: secondLinePositionSmall,
                            horizontalAlignment: .right)
                    ]
                    
                case "fader_3":
                    viewModel.setSustain(controlValue)
                    let value = Int((100 * controlValue).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "sustain", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: "\(value)%", attributes: lineAttrsSmall),
                            position: secondLinePositionSmall,
                            horizontalAlignment: .right)
                    ]
                    
                case "fader_4":
                    viewModel.setRelease(controlValue)
                    let ms = Int((1000 * controlValue).rounded(.down))
                    lcdTextLines = [
                        LCDTextLine(
                            text: NSAttributedString(string: "release", attributes: lineAttrsTop),
                            position: firstLinePosition,
                            horizontalAlignment: .left),
                        LCDTextLine(
                            text: NSAttributedString(string: "\(ms) ms", attributes: lineAttrsSmall),
                            position: secondLinePositionSmall,
                            horizontalAlignment: .right)
                    ]
                    
                default: break
                }
            }
            else
            {
                let results = sceneView.hitTest(p, options: nil)
                let nodes = results.compactMap { (result: SCNHitTestResult) -> SCNNode? in
                    let node = result.node
                    if node.name?.starts(with: "key_") ?? false {
                        return node
                    }
                    return nil
                }
                
                let oldKeys = touchedKeys[touch]!
                let newKeys = Set(nodes)
                
                let keysToPress = newKeys.subtracting(oldKeys)
                let keysToRelease = oldKeys.subtracting(newKeys)
                
                for node in keysToPress {
                    pressKey(node)
                }
                
                for node in keysToRelease {
                    releaseKey(node)
                }
                
                touchedKeys[touch] = newKeys
            }
            
            if let textLines = lcdTextLines {
                lcdMaterial.emission.contents = renderLCDScreen(textLines)
                lcdMaterial.emission.intensity = 1
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        finishTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        finishTouches(touches)
    }
    
    private func finishTouches(_ touches: Set<UITouch>)
    {
        for touch in touches {
            touchedKeys[touch]?.forEach {
                releaseKey($0)
            }
            touchedKeys.removeValue(forKey: touch)
            touchedKnobs.removeValue(forKey: touch)
            touchedFaders.removeValue(forKey: touch)
            if touch == backgroundTouch {
                returnCameraToInitialPosition()
                backgroundTouch = nil
            }
        }
    }
    
    private func returnCameraToInitialPosition()
    {
        enableParallaxUpdates = false
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.completionBlock = {
            self.enableParallaxUpdates = true
        }
        cameraEulerAngles = ViewController3D.defaultCameraEulerAngles
        updateCameraEulerAngles()
        SCNTransaction.commit()
    }
    
    private func pressKey(_ node: SCNNode) {
        if let keyIndex = Int(node.name!.split(separator: "_")[1]) {
            let action = ViewController3D.isBlack(keyIndex - 1) ? pressBlack : pressWhite
            node.runAction(action!)
            viewModel.play(noteNumber: MIDINoteNumber(startMidiNote + keyIndex))
        }
    }
    
    private func releaseKey(_ node: SCNNode) {
        if let keyIndex = Int(node.name!.split(separator: "_")[1]) {
            node.runAction(release)
            viewModel.stop(noteNumber: MIDINoteNumber(startMidiNote + keyIndex))
        }
    }
}
