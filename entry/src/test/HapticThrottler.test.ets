import { describe, expect, it } from '@ohos/hypium';
import { HapticThrottler } from '../main/ets/model/HapticThrottler';
import { RiskLevel } from '../main/ets/model/RiskLevel';

const MINUTE: number = 60000;
const T0: number = 1000000;

export default function hapticThrottlerTest() {
  describe('HapticThrottler', () => {
    it('lowAndModerateNeverAlert', 0, () => {
      const throttler = new HapticThrottler();
      expect(throttler.shouldAlert(RiskLevel.LOW, T0)).assertFalse();
      expect(throttler.shouldAlert(RiskLevel.MODERATE, T0)).assertFalse();
    });

    it('highAlertsOncePerFiveMinutes', 0, () => {
      const throttler = new HapticThrottler();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0)).assertTrue();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0 + 4 * MINUTE)).assertFalse();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0 + 5 * MINUTE)).assertTrue();
    });

    it('veryHighAlertsOncePerTwoMinutes', 0, () => {
      const throttler = new HapticThrottler();
      expect(throttler.shouldAlert(RiskLevel.VERY_HIGH, T0)).assertTrue();
      expect(throttler.shouldAlert(RiskLevel.VERY_HIGH, T0 + MINUTE)).assertFalse();
      expect(throttler.shouldAlert(RiskLevel.VERY_HIGH, T0 + 2 * MINUTE)).assertTrue();
    });

    it('cooldownIsKeptWhenLevelDropsAndRises', 0, () => {
      const throttler = new HapticThrottler();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0)).assertTrue();
      expect(throttler.shouldAlert(RiskLevel.MODERATE, T0 + MINUTE)).assertFalse();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0 + 2 * MINUTE)).assertFalse();
    });

    it('escalationToVeryHighAlertsAtOnce', 0, () => {
      const throttler = new HapticThrottler();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0)).assertTrue();
      expect(throttler.shouldAlert(RiskLevel.VERY_HIGH, T0 + 1000)).assertTrue();
    });

    it('stepDownDoesNotAlertInsideCooldown', 0, () => {
      const throttler = new HapticThrottler();
      expect(throttler.shouldAlert(RiskLevel.VERY_HIGH, T0)).assertTrue();
      expect(throttler.shouldAlert(RiskLevel.HIGH, T0 + MINUTE)).assertFalse();
    });
  });
}
