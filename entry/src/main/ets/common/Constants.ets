export class Constants {
  // Normalization ranges of the risk model.
  static readonly LUX_MAX: number = 100000;
  static readonly TEMP_MIN_C: number = 15;
  static readonly TEMP_MAX_C: number = 40;
  static readonly LIGHT_WEIGHT: number = 0.7;
  static readonly TEMP_WEIGHT: number = 0.3;

  // Exposure: continuous light at or above this level counts as sun exposure.
  static readonly HIGH_LIGHT_LUX: number = 20000;
  // Each minute of exposure adds 2% to the score, up to +40%.
  static readonly EXPOSURE_GAIN_PER_MIN: number = 0.02;
  static readonly EXPOSURE_GAIN_MAX: number = 0.4;
  // Exposure resets after this long below HIGH_LIGHT_LUX (the user moved to the shade).
  static readonly EXPOSURE_RESET_MS: number = 60000;
  // A tick longer than this (app was suspended) does not add exposure.
  static readonly EXPOSURE_MAX_TICK_MS: number = 2000;

  // Score bounds of the levels MODERATE, HIGH, VERY_HIGH.
  static readonly LEVEL_BOUNDS: number[] = [25, 50, 75];
  static readonly HYSTERESIS: number = 3;

  // Haptic alert cooldowns per level.
  static readonly HIGH_ALERT_COOLDOWN_MS: number = 5 * 60000;
  static readonly VERY_HIGH_ALERT_COOLDOWN_MS: number = 2 * 60000;
  static readonly ALERT_FALLBACK_MS: number = 300;

  // Sensor fusion.
  static readonly SENSOR_INTERVAL_NS: number = 200000000;
  static readonly AVERAGE_WINDOW_MS: number = 5000;
  static readonly MAX_SAMPLE_AGE_MS: number = 3000;
  static readonly SIM_INTERVAL_MS: number = 200;
  static readonly UI_TICK_MS: number = 1000;

  static readonly SIM_DEFAULT_LUX: number = 45000;
  static readonly SIM_DEFAULT_TEMP_C: number = 29;

  static readonly LOG_LIMIT: number = 20;
  static readonly LOG_DOMAIN: number = 0x0019;
  static readonly LOG_TAG: string = 'SunGuard';
}
