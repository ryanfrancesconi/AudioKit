// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import Foundation

extension AKManager {
    /// Start up the audio engine
    public static func start() throws {
        if output == nil {
            AKLog("No output node has been set yet, no processing will happen.")
        }
        // Start the engine.
        try AKTry {
            engine.prepare()
        }

        try AKTry {
            try engine.start()
        }
        shouldBeRunning = true
    }

    /// Stop the audio engine
    public static func stop() throws {
        // Stop the engine.
        try AKTry {
            engine.stop()
        }
        shouldBeRunning = false
    }

    public static func shutdown() throws {
        engine = AVAudioEngine()
        // finalMixer = nil
        output = nil
        shouldBeRunning = false
    }
}
