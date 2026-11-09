# HABB447 Industrial Biotech Project

A data-driven bioprocess simulation and fermentation analysis project for HABB447 Industrial Biotechnology. The work investigates process behaviour over time, explores relationships among key variables, and presents a practical interpretation of fermentation performance using a simulated production dataset.

## Overview

This project combines process modelling, exploratory analysis, and data visualisation to evaluate how fermentation conditions change over time and how operational variables interact. The final report summarises key trends in glucose, pH, temperature, and system diagnostics in a format suitable for academic presentation and review.

## Full rendered reports

- [Open the knitted report](knit.html)
- [Open the Quarto report](bioprocess_simulation.html)

## Research focus

This project explores how a fermentation process behaves under simulated industrial conditions. The analysis focuses on the interaction between key process variables, identifying operational trends and evaluating how those variables contribute to overall bioprocess performance.

## Methodology

- Simulated fermentation data was generated to model realistic process variation over time.
- Time-series visualisation was used to explore how glucose concentration, pH, and temperature evolve during production.
- Relationship analysis was applied to identify patterns and dependencies between process variables.
- Diagnostics were reviewed to assess model quality and interpret the effectiveness of the simulation workflow.

## Key outcomes

- The project identified clear temporal patterns in fermentation behaviour and process stability.
- Variable interactions highlighted the importance of monitoring glucose, pH, and temperature jointly during production.
- Diagnostic plots showed how the model and process data can be interpreted for practical decision-making.
- The final output provides a clear summary of the simulated bioprocess in a presentation-ready academic format.

## Key findings at a glance

### Fermentation dynamics

![Glucose and pH over time](bioprocess_simulation_files/figure-html/glucose_time_ph-1.png)

### Temperature and process relationships

![Temperature, pH and glucose interaction](bioprocess_simulation_files/figure-html/temp_ph_glucose-1.png)

### Relationships among variables

![Interactions among key process variables](bioprocess_simulation_files/figure-html/individual_relationships-1.png)

### Model diagnostics

![Model performance and diagnostics](bioprocess_simulation_files/figure-html/random_forest-1.png)

### Process evaluation

![Overall process diagnostics](bioprocess_simulation_files/figure-html/diagnostics-1.png)

## Repository contents

- `app.R` — interactive Shiny application
- `bioengineering_pipeline.R` — process analysis workflow
- `simulated_fermentation_data.csv` — simulated fermentation dataset
- `knit.Rmd` and `bioprocess_simulation.qmd` — report source files
- `trial.qmd` — supporting analysis notebook/report

## Run locally

Open the project in RStudio, source the analysis scripts, and render the report to reproduce the figures and document output.

## Project purpose

The aim of this project is to simulate and assess bioprocess behaviour in a controllable, reproducible environment. It is intended to support interpretation of fermentation performance and to demonstrate the use of data-driven methods in industrial biotechnology.
