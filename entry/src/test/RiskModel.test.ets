import { describe, expect, it } from '@ohos/hypium';
import { RiskLevel } from '../main/ets/model/RiskLevel';
import { RiskModel } from '../main/ets/model/RiskModel';

export default function riskModelTest() {
  describe('RiskModel', () => {
    it('normalizeClampsToZeroAndOne', 0, () => {
      expect(RiskModel.normalize(-5, 0, 10)).assertEqual(0);
      expect(RiskModel.normalize(15, 0, 10)).assertEqual(1);
      expect(RiskModel.normalize(5, 0, 10)).assertEqual(0.5);
    });

    it('scoreIsZeroInTheDarkAndCold', 0, () => {
      expect(RiskModel.score(0, 15, 0)).assertEqual(0);
    });

    it('scoreIsHundredInFullSunAndHeat', 0, () => {
      expect(RiskModel.score(100000, 40, 0)).assertEqual(100);
    });

    it('scoreUsesLightAndTemperatureWeights', 0, () => {
      expect(RiskModel.score(50000, 27.5, 0)).assertEqual(50);
      expect(RiskModel.score(100000, 15, 0)).assertEqual(70);
    });

    it('exposureGainIsTwoPercentPerMinuteUpToForty', 0, () => {
      expect(RiskModel.exposureGain(10)).assertEqual(0.2);
      expect(RiskModel.exposureGain(20)).assertEqual(0.4);
      expect(RiskModel.exposureGain(90)).assertEqual(0.4);
      expect(RiskModel.exposureGain(-3)).assertEqual(0);
    });

    it('exposureIncreasesTheScore', 0, () => {
      expect(RiskModel.score(50000, 27.5, 10)).assertEqual(60);
    });

    it('scoreIsLimitedToHundred', 0, () => {
      expect(RiskModel.score(100000, 40, 20)).assertEqual(100);
    });

    it('missingTemperatureUsesLightOnly', 0, () => {
      expect(RiskModel.score(50000, NaN, 0)).assertEqual(50);
    });

    it('missingLightUsesTemperatureOnly', 0, () => {
      expect(RiskModel.score(NaN, 27.5, 0)).assertEqual(50);
    });

    it('noInputGivesNaN', 0, () => {
      expect(Number.isNaN(RiskModel.score(NaN, NaN, 5))).assertTrue();
    });

    it('rawLevelUsesBounds', 0, () => {
      expect(RiskModel.rawLevel(24.9)).assertEqual(RiskLevel.LOW);
      expect(RiskModel.rawLevel(25)).assertEqual(RiskLevel.MODERATE);
      expect(RiskModel.rawLevel(50)).assertEqual(RiskLevel.HIGH);
      expect(RiskModel.rawLevel(75)).assertEqual(RiskLevel.VERY_HIGH);
    });

    it('firstLevelHasNoHysteresis', 0, () => {
      expect(RiskModel.nextLevel(26, undefined)).assertEqual(RiskLevel.MODERATE);
    });

    it('goingUpNeedsBoundPlusThree', 0, () => {
      expect(RiskModel.nextLevel(27, RiskLevel.LOW)).assertEqual(RiskLevel.LOW);
      expect(RiskModel.nextLevel(28, RiskLevel.LOW)).assertEqual(RiskLevel.MODERATE);
    });

    it('goingDownNeedsBoundMinusThree', 0, () => {
      expect(RiskModel.nextLevel(22, RiskLevel.MODERATE)).assertEqual(RiskLevel.MODERATE);
      expect(RiskModel.nextLevel(21.9, RiskLevel.MODERATE)).assertEqual(RiskLevel.LOW);
    });

    it('levelCanJumpSeveralSteps', 0, () => {
      expect(RiskModel.nextLevel(90, RiskLevel.LOW)).assertEqual(RiskLevel.VERY_HIGH);
      expect(RiskModel.nextLevel(5, RiskLevel.VERY_HIGH)).assertEqual(RiskLevel.LOW);
    });
  });
}
