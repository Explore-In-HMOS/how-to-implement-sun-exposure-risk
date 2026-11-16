import { Constants } from '../common/Constants';
import { RiskLevel } from './RiskLevel';

const LEVELS: RiskLevel[] = [RiskLevel.LOW, RiskLevel.MODERATE, RiskLevel.HIGH, RiskLevel.VERY_HIGH];

/**
 * Pure functions of the tiered risk model. No sensor or UI code here, so
 * every rule can be unit tested.
 *
 * score = (0.7 * light + 0.3 * temperature) * 100 * (1 + exposure gain)
 * light       = lux normalized to 0..100 000 lx
 * temperature = °C normalized to 15..40 °C
 * exposure gain = 2% per minute of continuous high light, max 40%
 * A missing input (NaN) is left out and the other weight becomes 1.
 */
export class RiskModel {
  static normalize(value: number, min: number, max: number): number {
    return Math.min(Math.max((value - min) / (max - min), 0), 1);
  }

  static exposureGain(exposureMinutes: number): number {
    return Math.min(Math.max(exposureMinutes, 0) * Constants.EXPOSURE_GAIN_PER_MIN, Constants.EXPOSURE_GAIN_MAX);
  }

  /** Returns NaN when both inputs are missing. */
  static score(lux: number, tempC: number, exposureMinutes: number): number {
    const hasLight = !Number.isNaN(lux);
    const hasTemp = !Number.isNaN(tempC);
    if (!hasLight && !hasTemp) {
      return NaN;
    }
    let base = 0;
    if (hasLight && hasTemp) {
      base = Constants.LIGHT_WEIGHT * RiskModel.normalize(lux, 0, Constants.LUX_MAX) +
        Constants.TEMP_WEIGHT * RiskModel.normalize(tempC, Constants.TEMP_MIN_C, Constants.TEMP_MAX_C);
    } else if (hasLight) {
      base = RiskModel.normalize(lux, 0, Constants.LUX_MAX);
    } else {
      base = RiskModel.normalize(tempC, Constants.TEMP_MIN_C, Constants.TEMP_MAX_C);
    }
    const score = base * 100 * (1 + RiskModel.exposureGain(exposureMinutes));
    return Math.min(Math.round(score * 10) / 10, 100);
  }

  /** Lower score bound of a level index (0 = LOW ... 3 = VERY_HIGH). */
  static bound(index: number): number {
    return index === 0 ? 0 : Constants.LEVEL_BOUNDS[index - 1];
  }

  /** Level without hysteresis. */
  static rawLevel(score: number): RiskLevel {
    let index = 0;
    while (index < LEVELS.length - 1 && score >= RiskModel.bound(index + 1)) {
      index++;
    }
    return LEVELS[index];
  }

  /**
   * Level with hysteresis: to go up into a level, the score must be at least
   * bound + 3; to go down out of a level, it must be below bound - 3.
   */
  static nextLevel(score: number, current: RiskLevel | undefined): RiskLevel {
    if (current === undefined) {
      return RiskModel.rawLevel(score);
    }
    let index = LEVELS.indexOf(current);
    while (index < LEVELS.length - 1 && score >= RiskModel.bound(index + 1) + Constants.HYSTERESIS) {
      index++;
    }
    while (index > 0 && score < RiskModel.bound(index) - Constants.HYSTERESIS) {
      index--;
    }
    return LEVELS[index];
  }
}
