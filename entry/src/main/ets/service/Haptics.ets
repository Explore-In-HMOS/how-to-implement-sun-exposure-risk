import { vibrator } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

export class Haptics {
  /** Plays the preset effect when the device supports it, otherwise a 300 ms vibration. */
  static alert(): string {
    const effectId: string = vibrator.HapticFeedback.EFFECT_HARD;
    let supported = false;
    try {
      supported = vibrator.isSupportEffectSync(effectId);
    } catch (err) {
      hilog.warn(Constants.LOG_DOMAIN, Constants.LOG_TAG, 'isSupportEffectSync failed: %{public}s', JSON.stringify(err));
    }
    const effect: vibrator.VibrateEffect = supported ?
      { type: 'preset', effectId: effectId, count: 2 } :
      { type: 'time', duration: Constants.ALERT_FALLBACK_MS };
    try {
      vibrator.startVibration(effect, { id: 0, usage: 'notification' }).catch((err: Error) => {
        hilog.warn(Constants.LOG_DOMAIN, Constants.LOG_TAG, 'Vibration failed: %{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.warn(Constants.LOG_DOMAIN, Constants.LOG_TAG, 'Vibration failed: %{public}s', JSON.stringify(err));
    }
    return supported ? `preset ${effectId}` : `${Constants.ALERT_FALLBACK_MS} ms vibration`;
  }
}
