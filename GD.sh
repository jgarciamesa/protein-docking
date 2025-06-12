#!/bin/bash
#SBATCH --job-name=scFv47_mm_gd         # job name
#SBATCH --time=2-00:00:00               # max job run time dd-hh:mm:ss
#SBATCH --nodes=2                       # Request 2 nodes
#SBATCH --ntasks-per-node=13            # tasks (commands) per compute node
#SBATCH --mem=64gb                      # total memory per node
#SBATCH --output=stdout.%j              # save stdout to file
#SBATCH --error=stderr.%j               # save stderr to file

########## VARIABLES ##################################

module purge
module load GCC/13.2.0  OpenMPI/4.1.6 Rosetta/3.14-mpi

################################### COMMANDS ###################################

# Parse arguments (step and trials)
while getopts ":s:t:d:n:" arg; do
    case $arg in
        s)
            STEP=${OPTARG} # step number
            ;;
        t)
            TRIALS=${OPTARG} # number of trials
            ;;
        d)
            DECOY_STRATEGY=${OPTARG} # decoy selection strategy
            ;;
        n)
            TOP_N=${OPTARG} # number of top decoys to select from
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
done

make gd${STEP} GD_TRIALS=${TRIALS}
cd gd${STEP}

# Run rosetta job
jobstats &

echo "Running Rosetta job for step $STEP with $TRIALS trials and decoy strategy $DECOY_STRATEGY"
mpirun -np 26 rosetta_scripts.mpi.linuxgccrelease @flags_replica_dock


jobstats

##### Post-processing #####

# Select best decoy following email steps
echo "Post-processing results for step $STEP"
cd output

for i in {1..8}; do echo decoys_I13R2-scFv47_Hs_000$i\_traj.out; cat decoys_I13R2-scFv47_Hs_000$i\_traj.out | grep SCORE: >> decoys_1.fsc; done;

if [[ "$DECOY_STRATEGY" == "1" ]]; then
    # Extract the 15th column (name) from the first line -- best decoy based on RSMD
    sort -k12n -k2n decoys_1.fsc | tail -n+9 > score_1_sorted.fsc
    best_decoy=$(awk '{print $15}' score_1_sorted.fsc | head -n1)
elif [[ "$DECOY_STRATEGY" == "2" ]]; then
    # New strategy
    # Select the best decoy based on the lowest energy of the top N decoys from score_2_sorted.fsc
    # 1. Extract the top N decoys without the headers (fist 8 lines)
    # 2. Sort the decoys by RSMD
    # 3. Select lowest energy (column 2)
    sort -k12n -k2n decoys_1.fsc | tail -n+9 > score_2_sorted.fsc
    best_decoy=$(head -n ${TOP_N} score_2_sorted.fsc | sort -k2n | awk '{print $15}' | head -n1)
else
    echo "Invalid decoy selection strategy"
    exit 1
fi

echo "Best decoy selected: $best_decoy"
# Trim best decoy name
trimmed_decoy="${best_decoy%_*_*}"

# Write the best decoy
echo "$best_decoy" > I13R2-scFv47.tag

# Create the PDB file
echo "Extracting PDB file for the best decoy"
# extract_pdbs.mpi.linuxgccrelease -in:file:silent decoys_I13R2-scFv47_AFm_0004_traj.out -in:file:tagfile I13R2-scFv47.tag
extract_pdbs.mpi.linuxgccrelease -in:file:silent decoys_${trimmed_decoy}_traj.out -in:file:tagfile I13R2-scFv47.tag
mv I13R2-scFv47_Hs_*.pdb I13R2-scFv47_Hs.pdb

# Delete output files
rm decoys_*_traj.out