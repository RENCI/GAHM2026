# SeparateEnvHur Output Documentation Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the nonexistent `separated.mat` example and make all affected active README and class-help examples match the default Florence configuration and actual output writers.

**Architecture:** Treat the current default configuration, `SeparateEnvHur` writer, and `fromSepEnvHur` loader as the source of truth. Use the concrete default file `output/FLORENCE_AL06_2018.mat` in executable examples and explain the generic `<output_dir>/<storm_name>_<storm_designation>_<storm_year>.mat` rule nearby.

**Tech Stack:** Markdown, MATLAB help comments, ripgrep, MATLAB R2026b, Git.

## Global Constraints

- Only active README files and plotting-class help text may change.
- Runtime MATLAB behavior, configuration values, generated outputs, and historical planning documents are out of scope.
- Preserve unrelated workspace changes, including current modifications to `config/config_GAHM2026_default.m`, `run_GAHM2026.m`, and `util/writeGAHM2026NetCdf.m`.
- The default SeparateEnvHur artifact is `output/FLORENCE_AL06_2018.mat` and contains the top-level variable `env_vals`.
- The default gridded GAHM artifact is `output/FLORENCE_2018.nc`.

---

### Task 1: Correct active output and default-config examples

**Files:**
- Modify: `README.md:13-181,279-300`
- Modify: `documentation/README_config.md:1-6,280-286`
- Modify: `SeparateEnvHur/README.md:31-73`
- Modify: `PlotEvalScripts/README.md:249-258`
- Modify: `PlotEvalScripts/@GAHM2026Plotter/README.md:29-35`
- Modify: `PlotEvalScripts/@GAHM2026Plotter/GAHM2026Plotter.m:63-66`

**Interfaces:**
- Consumes: `SeparateEnvHur` output naming and `GAHM2026Plotter.fromSepEnvHur` file/struct input contract.
- Produces: copy-pasteable default Florence examples plus the generic storm output naming rule.

- [ ] **Step 1: Record the stale-reference audit before editing**

Run:

```bash
rg -n 'separated\.mat|FLORENCE_2018_AL06\.mat|FLORENCE_2018\.mat|FLORENCE_AL062018_2018\.mat|config/config_GAHM2026\.m|config/config_Florence\.m' \
  README.md documentation/README_config.md SeparateEnvHur/README.md \
  PlotEvalScripts/README.md PlotEvalScripts/@GAHM2026Plotter/README.md \
  PlotEvalScripts/@GAHM2026Plotter/GAHM2026Plotter.m
```

Expected: the command reports the known placeholder, stale Florence output names, and stale default/storm config names.

- [ ] **Step 2: Correct the top-level README default workflow**

In `README.md`:

- Keep the no-argument `run_GAHM2026` default example and remove the nonexistent `config_Florence` example.
- Keep the standalone `SeparateEnvHur("config/config_GAHM2026_default")` example and remove the nonexistent Florence config call.
- Replace the directory-tree `config_Florence.m` entry with the existing `config_Ian.m` storm-specific example.
- Use `output/FLORENCE_AL06_2018.mat` for the SeparateEnvHur file in prose, the workflow diagram, and the intermediate-output section.
- Replace the linkage example with the actual derivation:

```matlab
env_info.file_name = fullfile("output", ...
    sprintf("%s_%s_%d", storm_name, storm_designation, storm_year));
% Default: output/FLORENCE_AL06_2018
```

- Explain that SeparateEnvHur appends `.mat` and saves `env_vals` there.
- Correct the default NetCDF description to `output/<storm>_<year>.nc`, with `output/FLORENCE_2018.nc` as the example.

- [ ] **Step 3: Correct the detailed configuration and SeparateEnvHur READMEs**

In `documentation/README_config.md`:

- Change the default config references to `config/config_GAHM2026_default.m`.
- In the new-storm instructions, copy from `config/config_GAHM2026_default.m`.

In `SeparateEnvHur/README.md`:

- Use `config/config_GAHM2026_default.m` for the default config and executable examples.
- Remove the nonexistent `config_Florence` example.
- Set the direct-struct example designation to `AL06`.
- Document the generic output as `<output_dir>/<STORM_NAME>_<DESIGNATION>_<YEAR>.mat` and the default as `output/FLORENCE_AL06_2018.mat`.

- [ ] **Step 4: Replace every plotting placeholder with the real default file**

Use this executable example in both plotting READMEs and the class help text:

```matlab
obj = GAHM2026Plotter.fromSepEnvHur("output/FLORENCE_AL06_2018.mat");
```

In `PlotEvalScripts/README.md`, retain the explanation that callers may alternatively pass a preloaded `env_vals` struct and state the generic filename rule.

- [ ] **Step 5: Verify stale active references are gone**

Run:

```bash
if rg -n 'separated\.mat|FLORENCE_2018_AL06\.mat|FLORENCE_2018\.mat|FLORENCE_AL062018_2018\.mat|config/config_GAHM2026\.m|config/config_Florence\.m' \
  README.md documentation/README_config.md SeparateEnvHur/README.md \
  PlotEvalScripts/README.md PlotEvalScripts/@GAHM2026Plotter/README.md \
  PlotEvalScripts/@GAHM2026Plotter/GAHM2026Plotter.m; then
  exit 1
fi
```

Expected: exit status 0 with no matches.

Run:

```bash
rg -n 'output/FLORENCE_AL06_2018\.mat|<output_dir>.*<storm_name>.*<storm_designation>.*<storm_year>|output/FLORENCE_2018\.nc|config_GAHM2026_default' \
  README.md documentation/README_config.md SeparateEnvHur/README.md \
  PlotEvalScripts/README.md PlotEvalScripts/@GAHM2026Plotter/README.md \
  PlotEvalScripts/@GAHM2026Plotter/GAHM2026Plotter.m
```

Expected: the concrete default examples and generic naming/default-config references appear in their intended sections.

- [ ] **Step 6: Verify the documented plotting call and diff scope**

Run:

```bash
'/Applications/MATLAB_R2026b.app/bin/matlab' -batch \
  'addpath("PlotEvalScripts"); obj = GAHM2026Plotter.fromSepEnvHur("output/FLORENCE_AL06_2018.mat"); assert(obj.Source == "sepenvhur");'
git diff --check
git status --short
```

Expected: MATLAB exits successfully, `git diff --check` prints nothing, and only the six intended active documentation/help files are new changes from this task. Pre-existing unrelated modifications and untracked files remain unchanged.

- [ ] **Step 7: Commit the cleanup without staging unrelated work**

Run:

```bash
git add README.md documentation/README_config.md SeparateEnvHur/README.md \
  PlotEvalScripts/README.md PlotEvalScripts/@GAHM2026Plotter/README.md \
  PlotEvalScripts/@GAHM2026Plotter/GAHM2026Plotter.m
git diff --cached --check
git diff --cached --name-only
git commit -m "Correct SeparateEnvHur output examples"
```

Expected: the staged-file list contains exactly the six intended files and the commit succeeds.
