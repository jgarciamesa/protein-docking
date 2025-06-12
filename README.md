# Protein Docking Pipeline

A comprehensive protein docking workflow using Rosetta's replica exchange Monte Carlo sampling for global and local docking simulations. This pipeline implements a multi-stage approach to predict protein-protein interactions with high accuracy.

## Table of Contents

- [Overview](#overview)
- [Workflow Architecture](#workflow-architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Pipeline Stages](#pipeline-stages)
- [Configuration Files](#configuration-files)
- [Execution Scripts](#execution-scripts)
- [Usage](#usage)
- [Parameters and Tuning](#parameters-and-tuning)
- [Output Analysis](#output-analysis)

## Overview

This project implements a sophisticated protein docking pipeline designed to predict the binding conformation of protein complexes. The workflow uses Rosetta's molecular modeling suite with replica exchange Monte Carlo (REMC) sampling to explore conformational space efficiently.

**Target System**: The pipeline is configured for docking scFv47 antibody fragment with IL-13 receptor (I13R2), but can be adapted for other protein-protein docking problems.

## Workflow Architecture

The pipeline consists of four main stages executed sequentially:

1. **Global Docking 1 (GD1)**: Initial global search with full randomization
2. **Global Docking 2 (GD2)**: Refined global search with partial randomization
3. **Global Docking 3 (GD3)**: Final global refinement with spin sampling
4. **Local Docking (LD)**: High-resolution local refinement with backbone flexibility

Each stage feeds its best-scoring decoy to the next stage, progressively refining the docking solution.

## Prerequisites

### Software Requirements
- **Rosetta 3.14+ with MPI support**
- **SLURM job scheduler**
- **GCC 13.2.0+**
- **OpenMPI 4.1.6+**

### Hardware Requirements
- **2 compute nodes minimum**
- **13 tasks per node (26 total MPI processes)**
- **64GB RAM per node**
- **2-day maximum runtime per stage**

## Project Structure

```
protein-docking/
├── README.md                    # This documentation
├── Makefile                     # Build system for stage directories
├── run_jobs.sh                  # Master job submission script
├── GD.sh                        # Global docking execution script
├── LD.sh                        # Local docking execution script
├── gd_template/                 # Template for global docking stages
│   ├── dock.xml                 # Rosetta protocol definition
│   ├── flags_replica_dock       # Rosetta command-line flags
│   ├── hamiltonians_cen.txt     # Temperature replica exchange settings
│   └── muds_2021.wts           # Scoring function weights
├── ld_template/                 # Template for local docking stage
│   ├── dock.xml                 # Local docking protocol
│   ├── flags_replica_dock       # Local docking flags
│   ├── hamiltonians_cen.txt     # Temperature settings
│   ├── muds_2021.wts           # Scoring weights
│   └── run_ld_AlphaRED         # Additional local docking script
├── protein_complex/             # Input protein structures
│   ├── I13R2-scFv47_Hs.pdb     # Starting complex structure
│   └── I13R2-IL13_AFm.pdb      # Native reference structure
└── [Generated directories]      # Created during execution
    ├── gd1/                     # Global docking stage 1 results
    ├── gd2/                     # Global docking stage 2 results
    ├── gd3/                     # Global docking stage 3 results
    └── ld/                      # Local docking results
```

## Pipeline Stages

### Stage 1: Global Docking 1 (GD1)
**Purpose**: Perform initial global search with maximum conformational sampling.

**Key Parameters**:
- **Trials**: 2,500,000 Monte Carlo steps
- **Randomization**: Both proteins fully randomized (`randomize1="true" randomize2="true"`)
- **Input**: Original protein complex structure
- **Perturbation**: Large rigid-body movements (rotation: 2°, translation: 1Å)

**Protocol Details**:
- Uses centroid-mode representation for speed
- Hamiltonian replica exchange with 3 temperature replicas
- Rigid-body docking only (no backbone flexibility)
- Records trajectories every 1000 steps

### Stage 2: Global Docking 2 (GD2)
**Purpose**: Refine the global search by fixing one protein's orientation.

**Key Parameters**:
- **Trials**: 2,500,000 Monte Carlo steps
- **Randomization**: First protein randomized, second fixed (`randomize1="true" randomize2="false"`)
- **Input**: Best decoy from GD1
- **Perturbation**: Same as GD1

**Rationale**: By fixing one protein, the search space is reduced, allowing more thorough sampling of the remaining degrees of freedom.

### Stage 3: Global Docking 3 (GD3)
**Purpose**: Final global refinement with rotational sampling only.

**Key Parameters**:
- **Trials**: 2,500,000 Monte Carlo steps
- **Randomization**: No translation, only rotation (`randomize1="false" randomize2="false" spin="true"`)
- **Input**: Best decoy from GD2
- **Perturbation**: Pure rotational movements

**Rationale**: Fine-tune the relative orientation while maintaining the approximate binding interface identified in previous stages.

### Stage 4: Local Docking (LD)
**Purpose**: High-resolution refinement with backbone flexibility.

**Key Parameters**:
- **Trials**: 1,000,000 Monte Carlo steps
- **Input**: Best decoy from GD3
- **Perturbation**: Reduced rigid-body movements
- **Flexibility**: Backbone and side-chain flexibility based on B-factors

## Configuration Files

### dock.xml Files
These define the Rosetta protocols for each stage:

**Global Docking Protocol**:
- Centroid-mode scoring for efficiency
- Rigid-body perturbations only
- Hamiltonian replica exchange
- Metropolis-Hastings sampling

**Local Docking Protocol**:
- Full-atom scoring for accuracy
- Backbone flexibility in low-confidence regions
- B-factor-based residue selection
- Combined rigid-body and local moves

### flags_replica_dock Files
Command-line parameters for Rosetta execution:

**Key Settings**:
- **Output**: Silent file format for efficiency
- **Trajectories**: 8 independent runs per stage
- **Replicas**: 3 temperature replicas per trajectory
- **Partners**: Chain definitions (A_BC for this system)
- **Scoring**: muds_2021 score function optimized for docking

### hamiltonians_cen.txt
Temperature replica exchange settings:
- **3 temperature levels**: 0.8, 1.5, 3.0 kT
- **Repulsive scaling**: Gradual softening (1.0 → 0.75 → 0.5)
- **Exchange frequency**: Every 1000 steps

## Execution Scripts

### Makefile
Generates stage-specific directories from templates with proper parameter substitution:

```bash
# Create global docking stage 1
make gd1 GD_TRIALS=2500000

# Create local docking stage
make ld LD_TRIALS=1000000
```

**Template Substitutions**:
- **TRIALS**: Number of Monte Carlo steps
- **Input/Output paths**: Absolute paths for file I/O
- **Perturbation parameters**: Randomization settings for each stage

**Syntax**
Sed is a powerful command-line utility for text manipulation. It allows you to search, replace, and transform text files using regular expressions.

The files `dock.xml` and `flags_replica_dock` contain placeholders for the actual values that are used by sed to perform the desired text manipulations. For example, the `dock.xml` file contains placeholders for the number of Monte Carlo steps (`TRIALS`), which are replaced with the actual values `${TRIALS}` when the script is executed:

```bash
sed -i 's/TRIALS/${TRIALS}/g' dock.xml
```

### GD.sh - Global Docking Script
SLURM batch script for global docking stages with advanced post-processing:

**Command-line Arguments**:
- `-s STEP`: Stage number (1, 2, or 3)
- `-t TRIALS`: Number of Monte Carlo trials
- `-d STRATEGY`: Decoy selection strategy (1 or 2)
- `-n TOP_N`: Number of top decoys for strategy 2

**Decoy Selection Strategies**:
1. **Strategy 1**: Select lowest RMSD decoy from all results
2. **Strategy 2**: Select lowest energy decoy from top N lowest RMSD decoys

**Post-processing Steps**:
1. Aggregate all trajectory scores into single file
2. Sort by RMSD and energy criteria
3. Extract best decoy based on selection strategy
4. Generate PDB file for next stage
5. Clean up intermediate files

### LD.sh - Local Docking Script
SLURM batch script for local docking with simplified decoy selection:

**Features**:
- Energy-based decoy selection only
- Reduced computational requirements
- Full-atom output for final analysis

### run_jobs.sh - Master Execution Script
Coordinates the entire pipeline with proper job dependencies:

```bash
# Submit all stages with dependencies
./run_jobs.sh
```

**Dependency Chain**:
GD1 → GD2 → GD3 → LD

Each job waits for successful completion of the previous stage before starting.

## Usage

### Quick Start
```bash
# Clone or download the project
cd protein-docking

# Submit the entire pipeline
./run_jobs.sh
```

### Manual Execution
```bash
# Run individual stages
sbatch GD.sh -s 1 -t 2500000 -d 1
sbatch GD.sh -s 2 -t 2500000 -d 1  # After GD1 completes
sbatch GD.sh -s 3 -t 2500000 -d 1  # After GD2 completes
sbatch LD.sh -t 1000000             # After GD3 completes
```

### Custom Parameters
```bash
# Use different trial numbers
sbatch GD.sh -s 1 -t 5000000 -d 2 -n 10

# Modify Makefile defaults
make gd1 GD_TRIALS=5000000
```

## Parameters and Tuning

### Trial Numbers
**Default Values**:
- Global Docking: 2,500,000 trials per stage
- Local Docking: 1,000,000 trials

**Tuning Guidelines**:
- Increase for more thorough sampling
- Decrease for faster testing
- Scale with system complexity

### Decoy Selection Strategies
**Strategy 1** (Default): Pure RMSD-based selection
- Best for initial exploration
- May select high-energy conformations

**Strategy 2**: Energy-filtered RMSD selection
- More physically reasonable
- Requires TOP_N parameter

## Output Analysis

### Key Output Files
Each stage produces:
- **Silent files**: Compressed trajectory data (`decoys_*_traj.out`)
- **Score files**: Energy and RMSD data (`decoys_1.fsc`, `score_*_sorted.fsc`)
- **PDB files**: Final selected structures (`I13R2-scFv47_Hs.pdb`)
- **Log files**: Detailed execution logs

### Score File Format
Columns include:
- **Column 2**: Total energy
- **Column 12**: Interface RMSD
- **Column 15**: Decoy name/identifier

### Visualization
```bash
# Extract final structure
cd ld/output
# Final docked complex is in I13R2-scFv47_Hs.pdb

# Compare with native structure
# Native reference: ../../protein_complex/I13R2-IL13_AFm.pdb
```
