import { Constants } from '../common/Constants';
import { LogEntry, Logger, LogLevel } from '../common/Logger';
import { ExposureTracker } from '../model/ExposureTracker';
import { HapticThrottler } from '../model/HapticThrottler';
import { RiskLevel, RiskLevelInfo } from '../model/RiskLevel';
import { RiskModel } from '../model/RiskModel';
import { Haptics } from '../service/Haptics';
import { ChannelMode, FusedReading, SensorFusion } from '../service/SensorFusion';

@Component
struct ToggleRow {
  @Prop label: Resource;
  @Prop isOn: boolean;
  onToggle: (isOn: boolean) => void = () => {};

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor(Color.White)
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor($r('app.color.success'))
        .onChange((isOn: boolean) => this.onToggle(isOn))
    }
    .width('78%')
    .height(40)
  }
}

@Entry
@Component
struct Index {
  @State score: number = NaN;
  @State level: RiskLevel = RiskLevel.LOW;
  @State hasLevel: boolean = false;
  @State lux: number = NaN;
  @State tempC: number = NaN;
  @State lightMode: ChannelMode = ChannelMode.OFF;
  @State tempMode: ChannelMode = ChannelMode.OFF;
  @State exposureMinutes: number = 0;
  @State lastAlertAt: number = 0;
  @State now: number = Date.now();
  @State simulate: boolean = false;
  @State simLux: number = Constants.SIM_DEFAULT_LUX;
  @State simTempC: number = Constants.SIM_DEFAULT_TEMP_C;
  @State logs: LogEntry[] = [];

  private fusion: SensorFusion = new SensorFusion((message: string, level: LogLevel) => this.addLog(message, level));
  private exposure: ExposureTracker = new ExposureTracker();
  private throttler: HapticThrottler = new HapticThrottler();
  private tickerId: number = -1;
  private visible: boolean = false;

  onPageShow(): void {
    this.visible = true;
    this.startSensors();
    this.tickerId = setInterval(() => this.tick(), Constants.UI_TICK_MS);
  }

  onPageHide(): void {
    this.visible = false;
    this.stopAll();
    this.addLog('Hidden: sensors stopped, exposure paused');
  }

  aboutToDisappear(): void {
    this.stopAll();
  }

  private stopAll(): void {
    if (this.tickerId !== -1) {
      clearInterval(this.tickerId);
      this.tickerId = -1;
    }
    this.fusion.stop();
    this.exposure.pause();
  }

  private startSensors(): void {
    this.fusion.simLux = this.simLux;
    this.fusion.simTempC = this.simTempC;
    this.fusion.start(this.simulate);
    const reading = this.fusion.read(Date.now());
    if (!this.simulate && reading.lightMode === ChannelMode.UNSUPPORTED &&
      reading.tempMode === ChannelMode.UNSUPPORTED) {
      this.addLog('No light or temperature sensor: simulated data is used', LogLevel.WARN);
      this.simulate = true;
      this.fusion.start(true);
    }
    this.updateModes(this.fusion.read(Date.now()));
  }

  /** One fusion and model pass per second: the UI never updates faster than 1 Hz. */
  private tick(): void {
    if (!this.visible) {
      return;
    }
    const now = Date.now();
    const reading = this.fusion.read(now);
    this.exposure.update(reading.lux, now);
    const score = RiskModel.score(reading.lux, reading.tempC, this.exposure.minutes());

    this.now = now;
    this.lux = reading.lux;
    this.tempC = reading.tempC;
    this.exposureMinutes = this.exposure.minutes();
    this.updateModes(reading);
    this.score = score;
    if (Number.isNaN(score)) {
      return;
    }

    const next = RiskModel.nextLevel(score, this.hasLevel ? this.level : undefined);
    if (!this.hasLevel || next !== this.level) {
      this.addLog(`Risk level ${RiskLevelInfo.label(next)} (score ${score.toFixed(1)})`,
        next >= RiskLevel.HIGH ? LogLevel.WARN : LogLevel.INFO);
      this.getUIContext().animateTo({ duration: 600, curve: Curve.EaseInOut }, () => {
        this.level = next;
        this.hasLevel = true;
      });
    }
    if (this.throttler.shouldAlert(next, now)) {
      const how = Haptics.alert();
      this.lastAlertAt = now;
      this.addLog(`Haptic alert for ${RiskLevelInfo.label(next)}: ${how}`, LogLevel.WARN);
    }
  }

  private updateModes(reading: FusedReading): void {
    this.lightMode = reading.lightMode;
    this.tempMode = reading.tempMode;
  }

  private onSimChange(isOn: boolean): void {
    this.simulate = isOn;
    this.addLog(`Simulated data ${isOn ? 'ON' : 'OFF'}`);
    this.exposure.reset();
    if (this.visible) {
      this.startSensors();
    }
  }

  private addLog(message: string, level: LogLevel = LogLevel.INFO): void {
    const entry = Logger.log(message, level);
    this.logs = [entry, ...this.logs].slice(0, Constants.LOG_LIMIT);
  }

  // ---------- View helpers ----------

  private levelColor(): string {
    return this.hasLevel ? RiskLevelInfo.color(this.level) : '#3A3A3C';
  }

  private luxText(): string {
    if (Number.isNaN(this.lux)) {
      return 'Light —';
    }
    return `Light ${Math.round(this.lux).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')} lx`;
  }

  private tempText(): string {
    return Number.isNaN(this.tempC) ? 'Temp —' : `Temp ${this.tempC.toFixed(1)} °C`;
  }

  private lastAlertText(): string {
    if (this.lastAlertAt === 0) {
      return 'No alert yet';
    }
    const minutes = Math.floor((this.now - this.lastAlertAt) / 60000);
    return minutes < 1 ? 'Last alert just now' : `Last alert ${minutes} min ago`;
  }

  private isPartial(): boolean {
    const hasLight = !Number.isNaN(this.lux);
    const hasTemp = !Number.isNaN(this.tempC);
    return hasLight !== hasTemp;
  }

  private logColor(level: LogLevel): ResourceColor {
    switch (level) {
      case LogLevel.ERROR:
        return $r('app.color.error');
      case LogLevel.WARN:
        return $r('app.color.warning');
      default:
        return '#AEAEB2';
    }
  }

  // ---------- Layout ----------

  @Builder
  dial() {
    Stack() {
      Column()
        .width('100%')
        .aspectRatio(1)
        .borderRadius(1000)
        .backgroundColor(this.levelColor())
        .opacity(0.18)

      Progress({ value: Number.isNaN(this.score) ? 0 : this.score, total: 100, type: ProgressType.Ring })
        .width('96%')
        .aspectRatio(1)
        .color(this.levelColor())
        .backgroundColor('#26FFFFFF')
        .style({ strokeWidth: 12, enableSmoothEffect: true })

      Column({ space: 2 }) {
        Text(this.hasLevel ? RiskLevelInfo.label(this.level) : 'NO DATA')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.levelColor())
        Text(Number.isNaN(this.score) ? '--' : `${Math.round(this.score)}`)
          .fontSize(44)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
        Text(this.luxText())
          .fontSize(13)
          .fontColor('#E5E5EA')
        Text(this.tempText())
          .fontSize(13)
          .fontColor('#E5E5EA')
        Text(`Exposure ${Math.floor(this.exposureMinutes)} min`)
          .fontSize(13)
          .fontColor('#E5E5EA')
        Text(this.hasLevel ? RiskLevelInfo.advice(this.level) : '')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.levelColor())
          .margin({ top: 2 })
        Text(this.lastAlertText())
          .fontSize(11)
          .fontColor($r('app.color.neutral'))
      }
    }
    .width('100%')
    .aspectRatio(1)
  }

  @Builder
  simControls() {
    Text($r('app.string.sim_light'))
      .fontSize(12)
      .fontColor($r('app.color.neutral'))
    Row({ space: 4 }) {
      Slider({ value: this.simLux, min: 0, max: Constants.LUX_MAX, step: 1000 })
        .layoutWeight(1)
        .selectedColor($r('app.color.warning'))
        .onChange((value: number) => {
          this.simLux = value;
          this.fusion.simLux = value;
        })
      Text(`${Math.round(this.simLux / 1000)}k`)
        .width(36)
        .fontSize(12)
        .fontColor(Color.White)
    }
    .width('76%')

    Text($r('app.string.sim_temperature'))
      .fontSize(12)
      .fontColor($r('app.color.neutral'))
    Row({ space: 4 }) {
      Slider({ value: this.simTempC, min: 10, max: 45, step: 0.5 })
        .layoutWeight(1)
        .selectedColor($r('app.color.warning'))
        .onChange((value: number) => {
          this.simTempC = value;
          this.fusion.simTempC = value;
        })
      Text(`${this.simTempC.toFixed(1)}`)
        .width(36)
        .fontSize(12)
        .fontColor(Color.White)
    }
    .width('76%')
  }

  build() {
    Scroll() {
      Column({ space: 6 }) {
        this.dial()

        if (this.isPartial()) {
          Text($r('app.string.partial_fusion'))
            .width('76%')
            .padding(8)
            .fontSize(12)
            .fontColor(Color.Black)
            .textAlign(TextAlign.Center)
            .borderRadius(12)
            .backgroundColor($r('app.color.warning'))
        }
        Text($r('app.string.estimate_note'))
          .width('76%')
          .fontSize(11)
          .fontColor($r('app.color.neutral'))
          .textAlign(TextAlign.Center)

        ToggleRow({
          label: $r('app.string.simulated_data'),
          isOn: this.simulate,
          onToggle: (isOn: boolean) => this.onSimChange(isOn)
        })
        if (this.simulate) {
          this.simControls()
        }

        Text(`light: ${this.lightMode} · temp: ${this.tempMode}`)
          .fontSize(12)
          .fontColor(this.simulate ? $r('app.color.warning') : $r('app.color.neutral'))

        Text($r('app.string.event_log'))
          .fontSize(13)
          .fontColor($r('app.color.neutral'))
          .margin({ top: 6 })
        ForEach(this.logs, (entry: LogEntry) => {
          Text(`${entry.time}  ${entry.message}`)
            .width('76%')
            .fontSize(11)
            .fontColor(this.logColor(entry.level))
        }, (entry: LogEntry) => entry.id.toString())
      }
      .width('100%')
      .padding({ bottom: 56 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(Color.Black)
  }
}
