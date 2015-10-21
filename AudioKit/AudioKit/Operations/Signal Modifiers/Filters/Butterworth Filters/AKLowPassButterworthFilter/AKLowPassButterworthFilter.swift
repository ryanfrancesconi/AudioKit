//
//  AKLowPassButterworthFilter.swift
//  AudioKit
//
//  Autogenerated by scripts by Aurelius Prochazka. Do not edit directly.
//  Copyright (c) 2015 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/** These filters are Butterworth second-order IIR filters. They offer an almost flat passband and very good precision and stopband attenuation. */
public class AKLowPassButterworthFilter: AKOperation {

    // MARK: - Properties

    /** The underlying AudioUnit */
    private var internalAU: AKLowPassButterworthFilterAudioUnit?

    /** A generic parameter observer token */
    private var token: AUParameterObserverToken?

    /** Cutoff frequency. (in Hertz) */
    var cutoffFrequencyParameter: AUParameter?

    /** Cutoff frequency. (in Hertz) */
    public var cutoffFrequency: Float = 1000 {
        didSet {
            cutoffFrequencyParameter?.setValue(cutoffFrequency, originator: token!)
        }
    }

    // MARK: - Initializers

    /** Initialize this filter operation */
    public init(_ input: AKOperation) {
        super.init()

        var description = AudioComponentDescription()
        description.componentType         = kAudioUnitType_Effect
        description.componentSubType      = 0x62746c70 /*'btlp'*/
        description.componentManufacturer = 0x41754b74 /*'AuKt'*/
        description.componentFlags        = 0
        description.componentFlagsMask    = 0

        AUAudioUnit.registerSubclass(
            AKLowPassButterworthFilterAudioUnit.self,
            asComponentDescription: description,
            name: "Local AKLowPassButterworthFilter",
            version: UInt32.max)

        AVAudioUnit.instantiateWithComponentDescription(description, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitEffect = avAudioUnit else { return }

            self.output = avAudioUnitEffect
            self.internalAU = avAudioUnitEffect.AUAudioUnit as? AKLowPassButterworthFilterAudioUnit
            AKManager.sharedInstance.engine.attachNode(self.output!)
            AKManager.sharedInstance.engine.connect(input.output!, to: self.output!, format: nil)
        }

        guard let tree = internalAU?.parameterTree else { return }

        cutoffFrequencyParameter = tree.valueForKey("cutoffFrequency") as? AUParameter

        token = tree.tokenByAddingParameterObserver {
            address, value in

            dispatch_async(dispatch_get_main_queue()) {
                if address == self.cutoffFrequencyParameter!.address {
                    self.cutoffFrequency = value
                }
            }
        }

    }
}
