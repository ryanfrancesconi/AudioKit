// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

/// Stereo Fader. Similar to AKBooster but with the addition of
/// Automation support.
public class AKFader: AKNode, AKToggleable, AKComponent, AKInput, AKAutomatable {
    public typealias AKAudioUnitType = InternalAU

    public static let ComponentDescription = AudioComponentDescription(effect: "fder")

    public private(set) var internalAU: AKAudioUnitType?

    public private(set) var parameterAutomation: AKParameterAutomation?

    // MARK: - Parameters

    /// Amplification Factor, from 0 ... 4
    open var gain: AUValue = 1 {
        willSet {
            leftGain = gain
            rightGain = gain
        }
    }

    public static let gainRange: ClosedRange<AUValue> = 0.0 ... 4.0

    public static let leftGainDef = AKNodeParameterDef(
        identifier: "leftGain",
        name: "Left Gain",
        address: AKFaderParameter.leftGain.rawValue,
        range: AKFader.gainRange,
        unit: .linearGain,
        flags: .default)

    /// Left Channel Amplification Factor
    @Parameter public var leftGain: AUValue

    public static let rightGainDef = AKNodeParameterDef(
        identifier: "rightGain",
        name: "Right Gain",
        address: AKFaderParameter.rightGain.rawValue,
        range: AKFader.gainRange,
        unit: .linearGain,
        flags: .default)

    /// Right Channel Amplification Factor
    @Parameter public var rightGain: AUValue

    /// Amplification Factor in db
    public var dB: AUValue {
        set { gain = pow(10.0, newValue / 20.0) }
        get { return 20.0 * log10(gain) }
    }

    public static let flipStereoDef = AKNodeParameterDef(
        identifier: "flipStereo",
        name: "Flip Stereo",
        address: AKFaderParameter.flipStereo.rawValue,
        range: 0.0 ... 1.0,
        unit: .boolean,
        flags: .default)

    /// Flip left and right signal
    @Parameter public var flipStereo: Bool = false

    public static let mixToMonoDef = AKNodeParameterDef(
        identifier: "mixToMono",
        name: "Mix To Mono",
        address: AKFaderParameter.mixToMono.rawValue,
        range: 0.0 ... 1.0,
        unit: .boolean,
        flags: .default)

    /// Make the output on left and right both be the same combination of incoming left and mixed equally
    @Parameter public var mixToMono: Bool = false

    // MARK: - Audio Unit

    public class InternalAU: AKAudioUnitBase {
        override public func getParameterDefs() -> [AKNodeParameterDef] {
            return [AKFader.leftGainDef,
                    AKFader.rightGainDef,
                    AKFader.flipStereoDef,
                    AKFader.mixToMonoDef]
        }

        override public func createDSP() -> AKDSPRef {
            return createFaderDSP()
        }
    }

    // MARK: - Initialization

    /// Initialize this fader node
    ///
    /// - Parameters:
    ///   - input: AKNode whose output will be amplified
    ///   - gain: Amplification factor (Default: 1, Minimum: 0)
    ///
    public init(_ input: AKNode? = nil,
                gain: AUValue = 1) {
        super.init(avAudioNode: AVAudioNode())
        self.leftGain = gain
        self.rightGain = gain

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            self.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType
            self.parameterAutomation = AKParameterAutomation(avAudioUnit)

            input?.connect(to: self)
        }
    }

    deinit {
        // AKLog("* { AKFader }")
    }

    override public func detach() {
        super.detach()
        parameterAutomation = nil
    }

    // MARK: - AKAutomatable

    /// Convenience function for adding a pair of points for both left and right addresses
    public func addAutomationPoint(value: AUValue,
                                   at startTime: Double,
                                   rampDuration: Double = 0,
                                   taper taperValue: Float = 1,
                                   skew skewValue: Float = 0) {
        let point = AKParameterAutomationPoint(targetValue: value,
                                               startTime: startTime,
                                               rampDuration: rampDuration,
                                               rampTaper: taperValue,
                                               rampSkew: skewValue)

        parameterAutomation?.add(point: point, to: $leftGain)
        parameterAutomation?.add(point: point, to: $rightGain)
    }

    /// Convenience function for clearing all points for both left and right addresses
    public func clearAutomationPoints() {
        parameterAutomation?.clearAllPoints(of: $leftGain)
        parameterAutomation?.clearAllPoints(of: $rightGain)
    }

    // MARK: - Automation

    public func automateGain(events: [AKAutomationEvent]) {
        $leftGain.automate(events: events)
        $rightGain.automate(events: events)
    }

    public func stopAutomation() {
        $leftGain.stopAutomation()
        $rightGain.stopAutomation()
    }
}
