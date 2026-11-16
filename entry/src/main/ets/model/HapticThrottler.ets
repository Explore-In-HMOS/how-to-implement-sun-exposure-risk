import { Constants } from '../common/Constants';
import { RiskLevel } from './RiskLevel';

/**
 * Decides when a risk level deserves a haptic alert:
 * - only HIGH and VERY_HIGH alert;
 * - each level has its own cooldown (HIGH 5 min, VERY_HIGH 2 min), kept
 *   when the level goes down and up again;
 * - a step down never alerts inside the cooldown of the lower level.
 */
export class HapticThrottler {
  private lastAlertAt: Map<RiskLevel, number> = new Map();
  private lastAlertLevel: RiskLevel = RiskLevel.LOW;
  private lastAnyAlertAt: number = 0;

  static cooldown(level: RiskLevel): number {
    return level === RiskLevel.VERY_HIGH ? Constants.VERY_HIGH_ALERT_COOLDOWN_MS : Constants.HIGH_ALERT_COOLDOWN_MS;
  }

  /** Returns true when an alert must be given now, and records it. */
  shouldAlert(level: RiskLevel, now: number): boolean {
    if (level < RiskLevel.HIGH) {
      return false;
    }
    const cooldown = HapticThrottler.cooldown(level);
    const last = this.lastAlertAt.get(level);
    if (last !== undefined && now - last < cooldown) {
      return false;
    }
    if (level < this.lastAlertLevel && this.lastAnyAlertAt > 0 && now - this.lastAnyAlertAt < cooldown) {
      return false;
    }
    this.lastAlertAt.set(level, now);
    this.lastAlertLevel = level;
    this.lastAnyAlertAt = now;
    return true;
  }

  lastAlertTime(): number {
    return this.lastAnyAlertAt;
  }

  reset(): void {
    this.lastAlertAt.clear();
    this.lastAlertLevel = RiskLevel.LOW;
    this.lastAnyAlertAt = 0;
  }
}
