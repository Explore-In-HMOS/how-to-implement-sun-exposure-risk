import { sensor } from '@kit.SensorServiceKit';
import { Constants } from '../common/Constants';
import { LogLevel } from '../common/Logger';

export enum ChannelMode {
  OFF = 'off',
  REAL = 'real',
  SIM = 'sim',
  UNSUPPORTED = 'unsupported'
}

class Sample {
  time: number;
  value: number;

  constructor(time: number, value: number) {
    this.time = time;
    this.value = value;
  }
}

/** Moving average over a time window. A value older than MAX_SAMPLE_AGE_MS counts as missing. */
class Channel {
  mode: ChannelMode = ChannelMode.OFF;
  private samples: Sample[] = [];

  add(value: number, now: number): void {
    this.samples.push(new Sample(now, value));
    this.prune(now);
  }

  /** NaN when there is no fresh sample. */
  average(now: number): number {
    this.prune(now);
    if (this.samples.length === 0 || now - this.samples[this.samples.length - 1].time > Constants.MAX_SAMPLE_AGE_MS) {
      return NaN;
    }
    let sum = 0;
    this.samples.forEach((sample: Sample) => {
      sum += sample.value;
    });
    return sum / this.samples.length;
  }

  clear(): void {
    this.samples = [];
  }

  private prune(now: number): void {
    while (this.samples.length > 0 && now - this.samples[0].time > Constants.AVERAGE_WINDOW_MS) {
      this.samples.shift();
    }
  }
}

export class FusedReading {
  lux: number = NaN;
  tempC: number = NaN;
  lightMode: ChannelMode = ChannelMode.OFF;
  tempMode: ChannelMode = ChannelMode.OFF;

  isPartial(): boolean {
    return Number.isNaN(this.lux) !== Number.isNaN(this.tempC);
  }

  isEmpty(): boolean {
    return Number.isNaN(this.lux) && Number.isNaN(this.tempC);
  }
}

/**
 * Fuses AMBIENT_LIGHT and AMBIENT_TEMPERATURE. Sensor callbacks only fill
 * the buffers; the page reads one fused value per UI tick. A missing sensor
 * is reported as UNSUPPORTED. In simulation mode both channels take their
 * values from `simLux` and `simTempC`.
 */
export class SensorFusion {
  simLux: number = Constants.SIM_DEFAULT_LUX;
  simTempC: number = Constants.SIM_DEFAULT_TEMP_C;
  private simPhase: number = 0;
  private light: Channel = new Channel();
  private temperature: Channel = new Channel();
  private simTimerId: number = -1;
  private onLog: (message: string, level: LogLevel) => void;
  private lightCallback = (data: sensor.LightResponse): void => {
    this.light.add(data.intensity, Date.now());
  };
  private temperatureCallback = (data: sensor.AmbientTemperatureResponse): void => {
    this.temperature.add(data.temperature, Date.now());
  };

  constructor(onLog: (message: string, level: LogLevel) => void) {
    this.onLog = onLog;
  }

  start(simulate: boolean): void {
    this.stop();
    if (simulate) {
      this.light.mode = ChannelMode.SIM;
      this.temperature.mode = ChannelMode.SIM;
      this.simTimerId = setInterval(() => this.simTick(), Constants.SIM_INTERVAL_MS);
      this.onLog('Simulated light and temperature started', LogLevel.INFO);
      return;
    }
    const options: sensor.Options = { interval: Constants.SENSOR_INTERVAL_NS };
    this.light.mode = this.subscribe(sensor.SensorId.AMBIENT_LIGHT, 'AMBIENT_LIGHT', () => {
      sensor.on(sensor.SensorId.AMBIENT_LIGHT, this.lightCallback, options);
    });
    this.temperature.mode = this.subscribe(sensor.SensorId.AMBIENT_TEMPERATURE, 'AMBIENT_TEMPERATURE', () => {
      sensor.on(sensor.SensorId.AMBIENT_TEMPERATURE, this.temperatureCallback, options);
    });
  }

  stop(): void {
    if (this.light.mode === ChannelMode.REAL) {
      this.unsubscribe('AMBIENT_LIGHT', () => sensor.off(sensor.SensorId.AMBIENT_LIGHT, this.lightCallback));
    }
    if (this.temperature.mode === ChannelMode.REAL) {
      this.unsubscribe('AMBIENT_TEMPERATURE',
        () => sensor.off(sensor.SensorId.AMBIENT_TEMPERATURE, this.temperatureCallback));
    }
    if (this.simTimerId !== -1) {
      clearInterval(this.simTimerId);
      this.simTimerId = -1;
    }
    this.light.mode = ChannelMode.OFF;
    this.temperature.mode = ChannelMode.OFF;
    this.light.clear();
    this.temperature.clear();
  }

  read(now: number): FusedReading {
    const reading = new FusedReading();
    reading.lux = this.light.average(now);
    reading.tempC = this.temperature.average(now);
    reading.lightMode = this.light.mode;
    reading.tempMode = this.temperature.mode;
    return reading;
  }

  private subscribe(id: sensor.SensorId, name: string, subscribeFn: () => void): ChannelMode {
    try {
      sensor.getSingleSensorSync(id);
    } catch (err) {
      this.onLog(`${name} is not available on this device`, LogLevel.WARN);
      return ChannelMode.UNSUPPORTED;
    }
    try {
      subscribeFn();
      this.onLog(`sensor.on(${name})`, LogLevel.INFO);
      return ChannelMode.REAL;
    } catch (err) {
      this.onLog(`sensor.on(${name}) failed: ${JSON.stringify(err)}`, LogLevel.ERROR);
      return ChannelMode.UNSUPPORTED;
    }
  }

  private unsubscribe(name: string, unsubscribeFn: () => void): void {
    try {
      unsubscribeFn();
      this.onLog(`sensor.off(${name})`, LogLevel.INFO);
    } catch (err) {
      this.onLog(`sensor.off(${name}) failed: ${JSON.stringify(err)}`, LogLevel.ERROR);
    }
  }

  private simTick(): void {
    const now = Date.now();
    // Small noise, so the moving average has something to smooth.
    this.simPhase++;
    const n1 = Math.sin(this.simPhase * 1.7) * 0.5 + Math.sin(this.simPhase * 0.31) * 0.5;
    const n2 = Math.sin(this.simPhase + 1.1);
    this.light.add(Math.max(0, this.simLux * (1 + n1 * 0.05)), now);
    this.temperature.add(this.simTempC + n2 * 0.2, now);
  }
}
