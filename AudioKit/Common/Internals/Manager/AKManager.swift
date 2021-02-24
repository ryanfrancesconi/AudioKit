// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreAudioKit
#endif

#if !os(macOS)
import UIKit
#endif
import Dispatch

public typealias AKCallback = () -> Void

/// Function type for MIDI callbacks
public typealias AKMIDICallback = (MIDIByte, MIDIByte, MIDIByte) -> Void

/// Top level AudioKit managing class
public class AKManager: NSObject {
    #if !os(macOS)
    public static let deviceSampleRate = AVAudioSession.sharedInstance().sampleRate
    #else
    public static let deviceSampleRate: Double = 48_000
    #endif

    // MARK: - Internal audio engine mechanics

    /// Reference to the AV Audio Engine
    public static var engine: AVAudioEngine {
        get {
            // Access a few attributes immediately so things are initialized properly
            #if !os(tvOS)
            if AKSettings.audioInputEnabled {
                _ = _engine.inputNode
            }
            #endif
            _ = AKManager.deviceSampleRate
            return _engine
        }
        set {
            _engine = newValue
        }
    }

    internal static var _engine = AVAudioEngine()

    /// Reference to singleton MIDI

    #if !os(tvOS)
    public static let midi = AKMIDI()
    #endif

//    static var finalMixer: AKMixer? {
//        didSet {
//            if let mixer = finalMixer {
//                for connection in internalConnections {
//                    connection >>> mixer
//                }
//                // Once the connections are made, we no longer need them.
//                internalConnections.removeAll()
//            }
//        }
//    }

    /// internalConnections are used for not-strictly audio processing nodes that need
    /// a mechanism to pull samples (ie. the sequencer)
    static var internalConnections: [AKNode] = []

    // MARK: - Device Management

    /// An audio output operation that most applications will need to use last
    public static var output: AKNode? {
        didSet {
            #if !os(macOS)
            do {
                try updateSessionCategoryAndOptions()
            } catch {
                AKLog("Could not set session category: \(error)")
            }
            #endif

            // if the assigned output is already a mixer, avoid creating an additional mixer and just use
            // that input as the finalMixer
//            if output?.avAudioNode.isKind(of: AVAudioMixerNode.self) == true {
//                finalMixer = output
//
//            } else {
//                // otherwise at this point create the finalMixer and add the input to it
//                let mixer = AKMixer()
//                output?.connect(to: mixer)
//                finalMixer = mixer
//            }
            guard let output = output else { return }
            engine.connect(output.avAudioNode, to: engine.outputNode, format: AKSettings.audioFormat)
        }
    }

    #if os(macOS)
    /// Enumerate the list of available devices.
    public static var devices: [AKDevice]? {
        return AudioDeviceUtils.devices().map { id in
            AKDevice(deviceID: id)
        }
    }
    #endif

    /// Enumerate the list of available input devices.
    public static var inputDevices: [AKDevice]? {
        #if os(macOS)
        return AudioDeviceUtils.devices().compactMap { (id: AudioDeviceID) -> AKDevice? in
            if AudioDeviceUtils.inputChannels(id) > 0 {
                return AKDevice(deviceID: id)
            }
            return nil
        }
        #else
        var returnDevices = [AKDevice]()
        if let devices = AVAudioSession.sharedInstance().availableInputs {
            for device in devices {
                if device.dataSources == nil || device.dataSources?.isEmpty == true {
                    returnDevices.append(AKDevice(portDescription: device))

                } else if let dataSources = device.dataSources {
                    for dataSource in dataSources {
                        returnDevices.append(AKDevice(name: device.portName,
                                                      deviceID: "\(device.uid) \(dataSource.dataSourceName)"))
                    }
                }
            }
            return returnDevices
        }
        return nil
        #endif
    }

    /// Enumerate the list of available output devices.
    public static var outputDevices: [AKDevice]? {
        #if os(macOS)
        return AudioDeviceUtils.devices().compactMap { (id: AudioDeviceID) -> AKDevice? in
            if AudioDeviceUtils.outputChannels(id) > 0 {
                return AKDevice(deviceID: id)
            }
            return nil
        }
        #else
        let devs = AVAudioSession.sharedInstance().currentRoute.outputs
        if devs.isNotEmpty {
            var outs = [AKDevice]()
            for dev in devs {
                outs.append(AKDevice(name: dev.portName, deviceID: dev.uid))
            }
            return outs
        }
        return nil
        #endif
    }

    /// The current input device, if available.
    ///
    /// Note that on macOS, this will always be the same as `outputDevice`
    public static var inputDevice: AKDevice? {
        #if os(macOS)
        return AKDevice(deviceID: engine.getDevice())
        #else
        if let portDescription = AVAudioSession.sharedInstance().preferredInput {
            return AKDevice(portDescription: portDescription)
        } else {
            let inputDevices = AVAudioSession.sharedInstance().currentRoute.inputs
            if inputDevices.isNotEmpty {
                for device in inputDevices {
                    return AKDevice(portDescription: device)
                }
            }
        }
        return nil
        #endif
    }

    /// The current output device, if available.
    ///
    /// Note that on macOS, this will always be the same as `inputDevice`
    public static var outputDevice: AKDevice? {
        #if os(macOS)
        return AKDevice(deviceID: engine.getDevice())
        #else
        let devs = AVAudioSession.sharedInstance().currentRoute.outputs
        if devs.isNotEmpty {
            return AKDevice(name: devs[0].portName, deviceID: devs[0].uid)
        }
        return nil
        #endif
    }

    /// Change the preferred input device, giving it one of the names from the list of available inputs.
    public static func setInputDevice(_ input: AKDevice) throws {
        #if os(macOS)
        try AKTry {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster)
            var devid = input.deviceID
            AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &devid)
        }
        #else
        // Set the port description first eg iPhone Microphone / Headset Microphone etc
        guard let portDescription = input.portDescription else {
            throw AKError.DeviceNotFound
        }
        try AVAudioSession.sharedInstance().setPreferredInput(portDescription)

        // Set the data source (if any) eg. Back/Bottom/Front microphone
        guard let dataSourceDescription = input.dataSource else {
            return
        }
        try AVAudioSession.sharedInstance().setInputDataSource(dataSourceDescription)
        #endif
    }

    /// Change the preferred output device, giving it one of the names from the list of available output.
    public static func setOutputDevice(_ output: AKDevice) throws {
        #if os(macOS)
        engine.setDevice(id: output.deviceID)
        #endif
    }

    // MARK: - Disconnect node inputs

    /// Disconnect all inputs
//    public static func disconnectAllInputs() {
//        guard let finalMixer = finalMixer else { return }
//
//        engine.disconnectNodeInput(finalMixer.avAudioNode)
//    }
}
