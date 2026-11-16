import { describe, expect, it } from '@ohos/hypium';
import { ExposureTracker } from '../main/ets/model/ExposureTracker';

const SECOND: number = 1000;
const T0: number = 1000000;

/** Feeds one tick per second with the same lux value. */
function feed(tracker: ExposureTracker, lux: number, start: number, seconds: number): number {
  for (let i = 0; i < seconds; i++) {
    tracker.update(lux, start + i * SECOND);
  }
  return start + seconds * SECOND;
}

export default function exposureTrackerTest() {
  describe('ExposureTracker', () => {
    it('highLightAccumulatesExposure', 0, () => {
      const tracker = new ExposureTracker();
      feed(tracker, 30000, T0, 61);
      // The first tick only sets the time base: 60 ticks of 1 s are counted.
      expect(tracker.minutes()).assertEqual(1);
    });

    it('shortDipDoesNotReset', 0, () => {
      const tracker = new ExposureTracker();
      let t = feed(tracker, 30000, T0, 61);
      t = feed(tracker, 5000, t, 30);
      feed(tracker, 30000, t, 1);
      expect(tracker.minutes() >= 1).assertTrue();
    });

    it('sixtySecondsInShadeResets', 0, () => {
      const tracker = new ExposureTracker();
      const t = feed(tracker, 30000, T0, 61);
      feed(tracker, 5000, t, 61);
      expect(tracker.minutes()).assertEqual(0);
    });

    it('longGapAddsNothing', 0, () => {
      const tracker = new ExposureTracker();
      tracker.update(30000, T0);
      tracker.update(30000, T0 + 10 * SECOND);
      expect(tracker.minutes()).assertEqual(0);
    });
  });
}
