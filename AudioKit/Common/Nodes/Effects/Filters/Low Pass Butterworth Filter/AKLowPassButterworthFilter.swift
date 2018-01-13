//
//  AKLowPassButterworthFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

/// These filters are Butterworth second-order IIR filters. They offer an almost
/// flat passband and very good precision and stopband attenuation.
///
open class AKLowPassButterworthFilter: AKNode, AKToggleable, AKComponent, AKInput {
    public typealias AKAudioUnitType = AKLowPassButterworthFilterAudioUnit
    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(effect: "btlp")

    // MARK: - Properties

    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    fileprivate var cutoffFrequencyParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    @objc open dynamic var rampTime: Double = AKSettings.rampTime {
        willSet {
            internalAU?.rampTime = newValue
        }
    }

    /// Cutoff frequency. (in Hertz)
    @objc open dynamic var cutoffFrequency: Double = 1_000.0 {
        willSet {
            if cutoffFrequency == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    cutoffFrequencyParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.cutoffFrequency, value: newValue)
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    @objc open dynamic var isStarted: Bool {
        return internalAU?.isPlaying ?? false
    }

    // MARK: - Initialization

    /// Initialize this filter node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - cutoffFrequency: Cutoff frequency. (in Hertz)
    ///
    @objc public init(
        _ input: AKNode? = nil,
        cutoffFrequency: Double = 1_000.0) {

        self.cutoffFrequency = cutoffFrequency

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
            guard let strongSelf = self else {
                AKLog("Error: self is nil")
                return
            }
            strongSelf.avAudioNode = avAudioUnit
            strongSelf.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType
            input?.connect(to: strongSelf)
        }

        guard let tree = internalAU?.parameterTree else {
            AKLog("Parameter Tree Failed")
            return
        }

        cutoffFrequencyParameter = tree["cutoffFrequency"]

        token = tree.token(byAddingParameterObserver: { [weak self] _, _ in

            guard let _ = self else {
                AKLog("Unable to create strong reference to self")
                return
            } // Replace _ with strongSelf if needed
            DispatchQueue.main.async {
                // This node does not change its own values so we won't add any
                // value observing, but if you need to, this is where that goes.
            }
        })

        self.internalAU?.setParameterImmediately(.cutoffFrequency, value: cutoffFrequency)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    @objc open func start() {
        internalAU?.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    @objc open func stop() {
        internalAU?.stop()
    }
}
