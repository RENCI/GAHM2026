# Revert Grid Interpolation Orientation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the pre-`2e7956d` grid interpolation behavior that matches all 68 saved regression checks.

**Architecture:** Surgically remove target-grid transposes from the shared field interpolation helper and blending-mask interpolation calls. Preserve every unrelated part of `2e7956d`, later NWS13 work, existing baselines, and unrelated workspace changes.

**Tech Stack:** MATLAB, `griddedInterpolant`, MATLAB Unit Test framework, Git.

## Global Constraints

- Do not revert the whole `2e7956d` commit.
- Do not regenerate or modify baseline files.
- Do not modify NWS13 files or unrelated workspace changes.
- Require all 68 existing baseline comparisons to pass.

---

### Task 1: Restore Pre-Change Interpolation Calls

**Files:**
- Modify: `util/interpFieldToGrid.m:15-23`
- Modify: `GAHM2026.m:615-622`

**Interfaces:**
- Consumes: existing `longrid` and `latgrid` target meshgrid arrays.
- Produces: interpolated fields and masks with the orientation represented by the August 5 baselines.

- [ ] **Step 1: Confirm the existing regression fails**

Run:

```bash
/Applications/MATLAB_R2025b.app/bin/matlab -batch "addpath('tools'); run_tests"
```

Expected: 56 checks pass and 12 env_type=3 gridded-field checks fail.

- [ ] **Step 2: Restore field interpolation calls**

In `util/interpFieldToGrid.m`, replace the three target-grid evaluations with:

```matlab
out.VelU = FU(longrid, latgrid);
out.VelV = FV(longrid, latgrid);
out.Press = FP(longrid, latgrid);
```

- [ ] **Step 3: Restore blending-mask interpolation calls**

In `GAHM2026.m`, replace the two target-grid evaluations with:

```matlab
Reggrid_out(i).Mask1 = FM1(longrid, latgrid);
Reggrid_out(i).Mask2 = FM2(longrid, latgrid);
```

- [ ] **Step 4: Run Code Analyzer**

Run:

```bash
/Applications/MATLAB_R2025b.app/bin/matlab -batch "issues=checkcode('util/interpFieldToGrid.m','-struct'); assert(isempty(issues)); issues=checkcode('GAHM2026.m','-struct'); fprintf('GAHM2026.m: %d pre-existing issue(s)\n',numel(issues))"
```

Expected: exit code 0, no issues in `interpFieldToGrid.m`, and only the pre-existing preallocation issues in `GAHM2026.m`.

- [ ] **Step 5: Run focused tests**

Run:

```bash
/Applications/MATLAB_R2025b.app/bin/matlab -batch "r=[runtests(fullfile('tools','testMergeFeatures.m')),runtests(fullfile('tools','testNws13CombineRanks.m'))]; assertSuccess(r)"
```

Expected: all 58 focused tests pass.

- [ ] **Step 6: Run the full baseline suite**

Run:

```bash
/Applications/MATLAB_R2025b.app/bin/matlab -batch "addpath('tools'); run_tests"
```

Expected: all 68 baseline comparisons pass with zero failures.

- [ ] **Step 7: Commit only the interpolation files and plan**

```bash
git add GAHM2026.m util/interpFieldToGrid.m docs/superpowers/plans/2026-08-13-revert-interpolation-orientation.md
git commit -m "Revert grid interpolation orientation change"
```
