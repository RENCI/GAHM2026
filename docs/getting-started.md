---
layout: default
title: Getting Started
nav_order: 2
permalink: /getting-started/
---

# Getting Started

## Requirements

- MATLAB with:
  - Mapping Toolbox
  - Optimization Toolbox
  - Signal Processing Toolbox
- A Git checkout of GAHM2026 and network access for the default IBTrACS and ERA5 inputs.

Clone the repository, then start MATLAB with the repository root as the working directory:

```bash
git clone https://github.com/RENCI/GAHM2026.git
cd GAHM2026
```

## Run the default example

The default configuration runs Hurricane Florence for 14 September 2018, 00:00 through 12:00:

```matlab
R = run_GAHM2026;
```

If the configured IBTrACS CSV is missing, the driver downloads it automatically. Because the default uses
`env_info.type = 3`, the driver also runs SeparateEnvHur automatically when
`output/FLORENCE_AL06_2018.mat` is absent. Generated outputs are ignored by Git and are not distributed in the
repository.

The run stops rather than overwrite an existing gridded result. Before rerunning, rename or remove
`output/FLORENCE_2018.nc`. A successful default run produces:

- `output/FLORENCE_AL06_2018.mat` — SeparateEnvHur environmental/hurricane intermediate data;
- `output/FLORENCE_2018.nc` — combined tropical-cyclone wind and pressure output.

## Make a quick plot

`run_GAHM2026` adds the plotting directory to the MATLAB path. Plot the first wind-speed timestep from the returned
result:

```matlab
plotter = GAHM2026Plotter(R);
figureHandle = plotter.contourMap("mvelcon", 1, 1);
```

## Next steps

- [Configuration]({{ '/configuration/' | relative_url }})
- [Outputs]({{ '/outputs/' | relative_url }})
- [SeparateEnvHur]({{ '/separate-env-hur/' | relative_url }})
- [Plotting and Diagnostics]({{ '/plotting/' | relative_url }})

See the [project README](https://github.com/RENCI/GAHM2026/blob/main/README.md) for the repository-level workflow.
