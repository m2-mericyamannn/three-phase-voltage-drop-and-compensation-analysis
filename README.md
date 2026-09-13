# Three-Phase Voltage Drop and Compensation Analysis

MATLAB and Simulink project for studying voltage drop in a balanced three-phase low-voltage feeder and the effect of reactive-power compensation.

The project compares steady-state Simulink results with the conventional analytical voltage-drop calculation for different cable cross-sections, feeder lengths, and load power factors. A second model adds a shunt capacitor bank and evaluates compensation to unity power factor.

## Requirements

- MATLAB
- Simulink
- Simscape Electrical with Specialized Power Systems

The project was verified with MATLAB R2024a. The Simulink models use `powergui` and Specialized Power Systems three-phase blocks.

## Project files

| File | Purpose |
| --- | --- |
| `MATLAB/voltage_drop_analysis.m` | Runs the complete voltage-drop sweep for 4, 6, and 10 mm² cables; 20–100 m feeder lengths; and power factors of 0.8, 0.9, and 1.0. It prints detailed and summary results and creates comparison plots. |
| `MATLAB/voltage_drop_single_scenario.m` | Runs one configurable voltage-drop case. Edit `selected_cable_index`, `selected_line_length_m`, and `selected_power_factor` near the top of the script. |
| `MATLAB/compensation_analysis.m` | Runs two compensated cases with initial power factors of 0.8 and 0.9, calculates the required capacitor-bank rating, and simulates the compensated feeder. |
| `MATLAB/compensation_single_scenario.m` | Runs one compensated case. Set `scenario_number` to `1` for an initial power factor of 0.8 or `2` for 0.9. |
| `MATLAB/report_plots.m` | Creates four report-ready plots from variables produced by `voltage_drop_analysis.m`. Run it in the same MATLAB session after the analysis script. |
| `SIMULINK/three_phase_voltage_drop.slx` | Three-phase source, feeder impedance, load, measurement, and RMS-output model used by the voltage-drop scripts. |
| `SIMULINK/three_phase_voltage_drop_with_compensation.slx` | Extended feeder model with a shunt capacitor bank, used by the compensation scripts. |

## Running the project

Open MATLAB in the repository root and run one of the scripts, for example:

```matlab
run(fullfile(pwd, 'MATLAB', 'voltage_drop_single_scenario.m'))
```

For the complete uncompensated study and the report figures:

```matlab
run(fullfile(pwd, 'MATLAB', 'voltage_drop_analysis.m'))
run(fullfile(pwd, 'MATLAB', 'report_plots.m'))
```

For compensation studies:

```matlab
run(fullfile(pwd, 'MATLAB', 'compensation_single_scenario.m'))
% or
run(fullfile(pwd, 'MATLAB', 'compensation_analysis.m'))
```

Each script determines the project root from its own location and adds the uppercase `SIMULINK` directory to the MATLAB path, so it can also be launched directly from the MATLAB Editor.

## Default study parameters

- Source voltage: 400 V line-to-line RMS
- Frequency: 50 Hz
- Three-phase active load power: 15 kW
- Cable resistance: 4.61, 3.08, and 1.83 Ω/km for 4, 6, and 10 mm² conductors
- Cable reactance: 0.08 Ω/km
- Voltage-drop sweep lengths: 20, 40, 60, 80, and 100 m
- Compensation case: 100 m, 6 mm² feeder
- Simulation stop time: 0.6 s

The analytical phase-voltage drop is calculated as

```text
Delta V = I (R cos(phi) + X sin(phi)) length
```

where `R` and `X` are specified per kilometre and the length is expressed in kilometres. For unity-power-factor compensation, the capacitor bank supplies the initial inductive reactive power of the load. The scripts report equivalent per-phase capacitance for both star and delta connections.

## Why the theoretical and simulated results differ

The reported error is a comparison difference, not a MATLAB execution error. The analytical calculation assumes that the load continues to draw its nominal 15 kW and therefore calculates a fixed current from `I = P / (sqrt(3) V_ll cos(phi))`. The Simulink `Three-Phase Series RLC Load`, however, represents an equivalent constant impedance at its nominal voltage. When feeder voltage drop lowers the load-terminal voltage, this impedance draws less current and less active power. The simulated voltage drop is consequently slightly lower than the analytical estimate.

For the report's 6 mm², 80 m, and `cos(phi) = 0.8` example, the theoretical current is 27.063 A while the simulated current is 26.434 A; the load therefore draws about 14.31 kW instead of 15 kW. This produces 5.344 V simulated drop versus 5.439 V theoretical drop, or approximately 1.746% relative error. The difference generally grows for longer feeders and smaller cable cross-sections because the load-terminal voltage moves farther away from its nominal value. A smaller secondary difference also comes from using the conventional approximate voltage-drop equation instead of solving the complete nonlinear network operating point.

The scripts calculate the reported comparison error as:

```text
error (%) = abs(simulated drop - theoretical drop) / abs(theoretical drop) * 100
```

## Simulink interface

The scripts provide these variables to the models through the MATLAB base workspace:

- `V_ll`, `f`: source line-to-line voltage and frequency
- `P_load`, `Q_load`: three-phase load active and reactive power
- `R_line`, `L_line`: per-phase feeder resistance and inductance
- `Q_cap`: capacitor-bank reactive power, used only by the compensation model
- `sim_stop_time`: requested simulation duration

Both models return timeseries with the same names:

- `Vsource_rms`: source phase-voltage RMS
- `Vload_rms`: load phase-voltage RMS
- `Iload_rms`: load-current RMS

The scripts use the final 50 Hz cycle to calculate steady-state RMS values.
