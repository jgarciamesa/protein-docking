#!/bin/bash

GD1_TRIALS=2500000
GD2_TRIALS=2500000
GD3_TRIALS=2500000
LD_TRIALS=1000000

# For global docking:
#  Decoy strategy 1: -d 1 (lowest score)
#  Decoy strategy 2: -d 2 -n 8 (lowest score from top 8 using distance)

# Step 1: Global docking 1
JOB1_ID=$(sbatch --parsable GD.sh -s 1 -t $GD1_TRIALS -d 1)
# Step 2: Global docking 2
JOB2_ID=$(sbatch --parsable --dependency=afterok:$JOB1_ID GD.sh -s 2 -t $GD2_TRIALS -d 1)
# Step 3: Global docking 3
JOB3_ID=$(sbatch --parsable --dependency=afterok:$JOB2_ID GD.sh -s 3 -t $GD3_TRIALS -d 1)
# Steps 4 & 5: Local docking and refinement
sbatch --dependency=afterok:$JOB3_ID LD.sh -t $LD_TRIALS
