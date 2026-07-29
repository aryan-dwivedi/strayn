# Strayn Healthspan Testing Strategy

## Overview

This document outlines the comprehensive testing strategy for the Strayn Healthspan feature, ensuring all calculations are:
- **Deterministic**: Same inputs always produce same outputs
- **Explainable**: Clear rationale for every calculation
- **Testable**: Each component can be tested in isolation

---

## 1. Unit Test Categories

### 1.1 Unlock Logic Tests
**Location**: `HealthspanEngineTests.swift`

| Test Case | Input | Expected Output |
|-----------|-------|-----------------|
| Insufficient days | 20 valid days in 31 | State: `.locked` |
| Exactly 21 days | 21 valid days | State: `.calibrating(.partial)` |
| Partial calibration | 25-29 valid days | State: `.calibrating(.partial)` |
| Full calibration start | 30 valid days | State: `.calibrating(.full)` |
| Full calibration progress | 60 valid days | State: `.calibrating(.full)` |
| Active state | 90+ valid days | State: `.active` |

### 1.2 Strayn Age Calculation Tests

| Test Case | Metric Scenario | Expected Outcome |
|-----------|-----------------|------------------|
| Optimal metrics | RHR=55, HRV=75, VO2=48, Sleep=7.5h | Age < chronological |
| Poor metrics | RHR=78, HRV=35, VO2=32, Sleep=5.5h | Age > chronological |
| Mixed metrics | Some optimal, some poor | Age ≈ chronological |
| Smoothing | Large change from previous | Change ≤ 0.3 years |
| Determinism | Same input twice | Identical output |

### 1.3 Pace of Aging Tests

| Test Case | Pace Value | Expected Zone |
|-----------|------------|---------------|
| Optimal | < 0.5 | `.optimal` |
| Slow | 0.5 - 0.8 | `.slow` |
| Steady | 0.8 - 1.2 | `.steady` |
| Elevated | 1.2 - 1.5 | `.elevated` |
| Accelerated | > 1.5 | `.accelerated` |

### 1.4 Insight Generation Tests

| Test Case | Scenario | Expected |
|-----------|----------|----------|
| Improvement | Strayn Age decreased | Positive insight |
| Decline | Sleep consistency dropped | Warning insight |
| Stability | Metrics stable | Neutral insight |
| Priority | Multiple insights | Sorted by priority |

---

## 2. Integration Test Scenarios

### 2.1 End-to-End Flow
```
User → HealthKit Data → Healthspan Engine → Strayn Age + Pace → UI
```

**Test Steps**:
1. Create mock User with chronological age
2. Create mock DailyRecovery array (6 months)
3. Create mock SleepSession array (6 months)
4. Create mock DailyStrain array (6 months)
5. Call `calculateHealthspan()`
6. Verify all outputs populated
7. Verify state transitions correctly

### 2.2 State Transition Tests
```
locked → calibrating(partial) → calibrating(full) → active
```

**Simulate**:
- Day 1-20: No change (locked)
- Day 21: Unlock to partial calibration
- Day 30: Progress to full calibration
- Day 90: Activate full feature

### 2.3 Weekly Update Cycle Tests
- Verify `shouldUpdate()` returns false before 7 days
- Verify `shouldUpdate()` returns true at 7+ days
- Verify Strayn Age changes are capped at ±0.3 years

---

## 3. Edge Case Tests

### 3.1 Data Quality Scenarios

| Scenario | Data Coverage | Expected Confidence |
|----------|--------------|---------------------|
| Excellent | 80%+ | `.high` |
| Good | 60-80% | `.high` |
| Fair | 40-60% | `.medium` |
| Poor | <40% | `.low` |

### 3.2 Missing Data Handling
- VO2 Max unavailable → Use 3-component weights
- HRV data sparse → Reduce autonomic weight
- Sleep data missing → State = `.insufficientRecentData`

### 3.3 Boundary Values
- Chronological age: 18, 25, 35, 50, 65, 80
- RHR: 40, 55, 70, 85, 100
- HRV: 20, 45, 70, 100, 150
- VO2 Max: 25, 35, 45, 55, 65

---

## 4. Performance Tests

### 4.1 Calculation Time
- 6 months data (~180 days) should process < 100ms
- Mock Healthspan creation should be < 10ms
- Insight generation should be < 50ms

### 4.2 Memory Usage
- No memory leaks in calculation engines
- Proper cleanup of temporary arrays

---

## 5. Mock Data Generators

### 5.1 Available Mocks

```swift
// Full Healthspan mock
HealthspanEngine.createMockHealthspan(
    chronologicalAge: 35,
    straynAgeDelta: -1.2,
    paceOfAging: 0.3,
    state: .active
)

// Strayn Age mock
StraynAgeCalculationEngine.createMockStraynAge(
    chronologicalAge: 35,
    ageDelta: -1.2
)

// Pace of Aging mock
PaceOfAgingEngine.createMockPaceOfAging(pace: 0.5)
```

### 5.2 Scenario Presets

| Preset | Description |
|--------|-------------|
| Elite Athlete | Younger by 5+ years, optimal pace |
| Health Conscious | Younger by 1-2 years, slow pace |
| Average User | On track, steady pace |
| Sedentary | Older by 1-2 years, elevated pace |
| Health Concern | Older by 3+ years, accelerated pace |

---

## 6. Test Execution

### 6.1 Running Tests

```bash
# Run all Healthspan tests
xcodebuild test -scheme strayn -only-testing:straynTests/HealthspanEngineTests

# Run specific test
xcodebuild test -scheme strayn -only-testing:straynTests/HealthspanEngineTests/testStraynAgeWithOptimalMetrics
```

### 6.2 CI/CD Integration
- Tests run on every PR
- Coverage report generated
- Minimum coverage: 80% for engine code

---

## 7. Test Data Fixtures

### 7.1 Standard Test Input
```swift
StraynAgeInputData(
    averageSleepDuration: 7 * 3600,
    sleepConsistencyScore: 70,
    deepSleepPercentage: 0.15,
    remSleepPercentage: 0.20,
    sleepEfficiencyAverage: 0.85,
    weeklyModerateAerobicMinutes: 150,
    weeklyHighIntensityMinutes: 30,
    weeklyStrengthTrainingMinutes: 60,
    dailyStepAverage: 8000,
    stepConsistencyScore: 70,
    restingHeartRateAverage: 62,
    restingHeartRateTrend: .stable,
    vo2Max: 42,
    vo2MaxTrend: .stable,
    cardiacEfficiencyScore: 0.70,
    hrvAverage: 55,
    hrvTrend: .stable,
    averageRecoveryScore: 65,
    recoveryConsistency: 70,
    chronologicalAge: 35,
    biologicalSex: .male,
    height: 175,
    weight: 75,
    leanBodyMass: 58,
    daysWithSleepData: 140,
    daysWithActivityData: 130,
    daysWithHeartRateData: 150,
    totalDaysInWindow: 180
)
```

---

## 8. Regression Tests

### 8.1 Known Good Values
Maintain a set of known good input/output pairs:

```swift
// Archive 2024-01: Standard 35yo male, good health
// Input: [fixture above]
// Expected: StraynAge ≈ 33.5 (±0.5), Pace ≈ 0.85 (±0.1)
```

### 8.2 Version Compatibility
- Test migration from v1 → v2 data format
- Verify historical calculations remain valid

---

## 9. Acceptance Criteria

### 9.1 Feature Complete
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Edge cases handled gracefully
- [ ] Mock data works for all states
- [ ] UI previews render correctly

### 9.2 Quality Metrics
- [ ] Test coverage ≥ 80%
- [ ] Zero crashes with malformed data
- [ ] Deterministic outputs verified
- [ ] Performance within thresholds

---

## 10. Future Test Enhancements

1. **A/B Test Validation**: Verify calculation changes don't affect existing users unexpectedly
2. **Fuzzing**: Random input generation to find edge cases
3. **Snapshot Tests**: UI screenshot comparison for visual regression
4. **Concurrency Tests**: Verify thread safety of shared instances
