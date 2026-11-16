import { Constants } from '../common/Constants';

/**
 * Accumulates continuous high-light time. Short dips below the threshold
 * (a passing cloud, an arm movement) do not reset it; 60 s below does.
 * Time is added per tick, so exposure stops while the app does not run.
 */
export class ExposureTracker {
  private exposureMs: number = 0;
  private belowMs: number = 0;
  private lastTickAt: number = 0;

  update(lux: number, now: number): void {
    const elapsed = this.lastTickAt === 0 ? 0 : now - this.lastTickAt;
    this.lastTickAt = now;
    if (elapsed <= 0 || elapsed > Constants.EXPOSURE_MAX_TICK_MS) {
      return;
    }
    if (!Number.isNaN(lux) && lux >= Constants.HIGH_LIGHT_LUX) {
      this.exposureMs += elapsed;
      this.belowMs = 0;
      return;
    }
    if (this.exposureMs === 0) {
      return;
    }
    this.belowMs += elapsed;
    if (this.belowMs >= Constants.EXPOSURE_RESET_MS) {
      this.exposureMs = 0;
      this.belowMs = 0;
    }
  }

  /** Call when the app goes to the background, so the next tick does not count the gap. */
  pause(): void {
    this.lastTickAt = 0;
  }

  minutes(): number {
    return this.exposureMs / 60000;
  }

  reset(): void {
    this.exposureMs = 0;
    this.belowMs = 0;
    this.lastTickAt = 0;
  }
}
