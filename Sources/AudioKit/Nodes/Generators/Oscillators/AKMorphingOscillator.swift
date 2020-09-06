// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import CAudioKit

/// This is an oscillator with linear interpolation that is capable of morphing
/// between an arbitrary number of wavetables.
/// 
public class AKMorphingOscillator: AKNode, AKComponent, AKToggleable {

    public static let ComponentDescription = AudioComponentDescription(generator: "morf")

    public typealias AKAudioUnitType = InternalAU

    public private(set) var internalAU: AKAudioUnitType?

    // MARK: - Parameters

    fileprivate var waveformArray = [AKTable]()

    public static let frequencyDef = AKNodeParameterDef(
        identifier: "frequency",
        name: "Frequency (in Hz)",
        address: akGetParameterAddress("AKMorphingOscillatorParameterFrequency"),
        range: 0.0 ... 22_050.0,
        unit: .hertz,
        flags: .default)

    /// Frequency (in Hz)
    @Parameter public var frequency: AUValue

    public static let amplitudeDef = AKNodeParameterDef(
        identifier: "amplitude",
        name: "Amplitude (typically a value between 0 and 1).",
        address: akGetParameterAddress("AKMorphingOscillatorParameterAmplitude"),
        range: 0.0 ... 1.0,
        unit: .hertz,
        flags: .default)

    /// Amplitude (typically a value between 0 and 1).
    @Parameter public var amplitude: AUValue

    public static let indexDef = AKNodeParameterDef(
        identifier: "index",
        name: "Index of the wavetable to use (fractional are okay).",
        address: akGetParameterAddress("AKMorphingOscillatorParameterIndex"),
        range: 0.0 ... 1_000.0,
        unit: .hertz,
        flags: .default)

    /// Index of the wavetable to use (fractional are okay).
    @Parameter public var index: AUValue

    public static let detuningOffsetDef = AKNodeParameterDef(
        identifier: "detuningOffset",
        name: "Frequency offset (Hz)",
        address: akGetParameterAddress("AKMorphingOscillatorParameterDetuningOffset"),
        range: -1_000.0 ... 1_000.0,
        unit: .hertz,
        flags: .default)

    /// Frequency offset in Hz.
    @Parameter public var detuningOffset: AUValue

    public static let detuningMultiplierDef = AKNodeParameterDef(
        identifier: "detuningMultiplier",
        name: "Frequency detuning multiplier",
        address: akGetParameterAddress("AKMorphingOscillatorParameterDetuningMultiplier"),
        range: 0.9 ... 1.11,
        unit: .generic,
        flags: .default)

    /// Frequency detuning multiplier
    @Parameter public var detuningMultiplier: AUValue

    // MARK: - Audio Unit

    public class InternalAU: AKAudioUnitBase {

        public override func getParameterDefs() -> [AKNodeParameterDef] {
            [AKMorphingOscillator.frequencyDef,
             AKMorphingOscillator.amplitudeDef,
             AKMorphingOscillator.indexDef,
             AKMorphingOscillator.detuningOffsetDef,
             AKMorphingOscillator.detuningMultiplierDef]
        }

        public override func createDSP() -> AKDSPRef {
            akCreateDSP("AKMorphingOscillatorDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this Morpher node
    ///
    /// - Parameters:
    ///   - waveformArray: An array of exactly four waveforms
    ///   - frequency: Frequency (in Hz)
    ///   - amplitude: Amplitude (typically a value between 0 and 1).
    ///   - index: Index of the wavetable to use (fractional are okay).
    ///   - detuningOffset: Frequency offset in Hz.
    ///   - detuningMultiplier: Frequency detuning multiplier
    ///
    public init(
        waveformArray: [AKTable] = [AKTable(.triangle), AKTable(.square), AKTable(.sine), AKTable(.sawtooth)],
        frequency: AUValue = 440,
        amplitude: AUValue = 0.5,
        index: AUValue = 0.0,
        detuningOffset: AUValue = 0,
        detuningMultiplier: AUValue = 1
    ) {
        super.init(avAudioNode: AVAudioNode())

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            guard let audioUnit = avAudioUnit.auAudioUnit as? AKAudioUnitType else {
                fatalError("Couldn't create audio unit")
            }
            self.internalAU = audioUnit

            for (i, waveform) in waveformArray.enumerated() {
                self.internalAU?.setWavetable(waveform.content, index: i)
            }
            self.waveformArray = waveformArray 
            self.frequency = frequency
            self.amplitude = amplitude
            self.index = index
            self.detuningOffset = detuningOffset
            self.detuningMultiplier = detuningMultiplier
        }

    }
}