// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#include "AKMetalBarDSP.hpp"
#include "ParameterRamper.hpp"

#import "AKSoundpipeDSPBase.hpp"

class AKMetalBarDSP : public AKSoundpipeDSPBase {
private:
    sp_bar *bar;
    ParameterRamper leftBoundaryConditionRamp;
    ParameterRamper rightBoundaryConditionRamp;
    ParameterRamper decayDurationRamp;
    ParameterRamper scanSpeedRamp;
    ParameterRamper positionRamp;
    ParameterRamper strikeVelocityRamp;
    ParameterRamper strikeWidthRamp;

public:
    AKMetalBarDSP() {
        parameters[AKMetalBarParameterLeftBoundaryCondition] = &leftBoundaryConditionRamp;
        parameters[AKMetalBarParameterRightBoundaryCondition] = &rightBoundaryConditionRamp;
        parameters[AKMetalBarParameterDecayDuration] = &decayDurationRamp;
        parameters[AKMetalBarParameterScanSpeed] = &scanSpeedRamp;
        parameters[AKMetalBarParameterPosition] = &positionRamp;
        parameters[AKMetalBarParameterStrikeVelocity] = &strikeVelocityRamp;
        parameters[AKMetalBarParameterStrikeWidth] = &strikeWidthRamp;
    }

    void init(int channelCount, double sampleRate) override {
        AKSoundpipeDSPBase::init(channelCount, sampleRate);
        sp_bar_create(&bar);
        sp_bar_init(sp, bar, 3, 0.0001);
    }

    void deinit() override {
        AKSoundpipeDSPBase::deinit();
        sp_bar_destroy(&bar);
    }

    void reset() override {
        AKSoundpipeDSPBase::reset();
        if (!isInitialized) return;
        sp_bar_init(sp, bar, 3, 0.0001);
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);

            bar->bcL = leftBoundaryConditionRamp.getAndStep();
            bar->bcR = rightBoundaryConditionRamp.getAndStep();
            bar->T30 = decayDurationRamp.getAndStep();
            bar->scan = scanSpeedRamp.getAndStep();
            bar->pos = positionRamp.getAndStep();
            bar->vel = strikeVelocityRamp.getAndStep();
            bar->wid = strikeWidthRamp.getAndStep();
            float temp = 0;
            for (int channel = 0; channel < channelCount; ++channel) {
                float *out = (float *)outputBufferLists[0]->mBuffers[channel].mData + frameOffset;

                if (isStarted) {
                    if (channel == 0) {
                        sp_bar_compute(sp, bar, nil, &temp);
                    }
                    *out = temp;
                } else {
                    *out = 0.0;
                }
            }
        }
    }
};

extern "C" AKDSPRef createMetalBarDSP() {
    return new AKMetalBarDSP();
}
