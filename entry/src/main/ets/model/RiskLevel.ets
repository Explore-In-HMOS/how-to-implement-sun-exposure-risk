export enum RiskLevel {
  LOW = 0,
  MODERATE = 1,
  HIGH = 2,
  VERY_HIGH = 3
}

export class RiskLevelInfo {
  static label(level: RiskLevel): string {
    switch (level) {
      case RiskLevel.MODERATE:
        return 'MODERATE';
      case RiskLevel.HIGH:
        return 'HIGH';
      case RiskLevel.VERY_HIGH:
        return 'VERY HIGH';
      default:
        return 'LOW';
    }
  }

  static color(level: RiskLevel): string {
    switch (level) {
      case RiskLevel.MODERATE:
        return '#FFD60A';
      case RiskLevel.HIGH:
        return '#FF9F0A';
      case RiskLevel.VERY_HIGH:
        return '#FF453A';
      default:
        return '#30D158';
    }
  }

  static advice(level: RiskLevel): string {
    switch (level) {
      case RiskLevel.MODERATE:
        return 'Use sunscreen outside';
      case RiskLevel.HIGH:
        return 'Move to the shade';
      case RiskLevel.VERY_HIGH:
        return 'Avoid the sun now';
      default:
        return 'No protection needed';
    }
  }
}
