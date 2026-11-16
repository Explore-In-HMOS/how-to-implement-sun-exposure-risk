import exposureTrackerTest from './ExposureTracker.test';
import hapticThrottlerTest from './HapticThrottler.test';
import riskModelTest from './RiskModel.test';

export default function testsuite() {
  riskModelTest();
  hapticThrottlerTest();
  exposureTrackerTest();
}
