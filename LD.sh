#!/bin/bash
#SBATCH --job-name=scFv47_mm_ld         # job name
#SBATCH --time=2-00:00:00               # max job run time dd-hh:mm:ss
#SBATCH --nodes=2                       # Request 2 nodes
#SBATCH --ntasks-per-node=13            # tasks (commands) per compute node
#SBATCH --mem=64gb                      # total memory per node
#SBATCH --partition=cpu
#SBATCH --output=stdout.%j              # save stdout to file
#SBATCH --error=stderr.%j               # save stderr to file

########## VARIABLES ##################################

module purge
module load GCC/13.2.0  OpenMPI/4.1.6 Rosetta/3.14-mpi

################################### COMMANDS ###################################

# Parse argument (trials)
while getopts ":t:" arg; do
    case $arg in
        t)
            TRIALS=${OPTARG}
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
done

# Move into the LD directory
make ld LD_TRIALS=${TRIALS}
cd ld

# Run rosetta job
jobstats &

# mpirun -np 28 rosetta_scripts.mpi.linuxgccrelease @flags_replica_dock
echo "Running Rosetta job for step LD with $TRIALS trials and decoy strategy $DECOY_STRATEGY"
mpirun -np 28 rosetta_scripts.cxx11threadmpiserialization.linuxgccrelease @flags_replica_dock

jobstats

cd output

for i in {1..8}; do echo decoys_I13R2-scFv47_Hs_000$i\_traj.out; cat decoys_I13R2-scFv47_Hs_000$i\_traj.out | grep SCORE: >> decoys_1.fsc; done;

# score_1_sorted.fsc lowest energy (column 2)
# Extract the 15th column (name) from the first line -- best decoy based on lowest energy
sort -k2n decoys_1.fsc > score_1_sorted.fsc
best_decoy=$(awk '{print $15}' score_1_sorted.fsc | head -n1)

echo "Best decoy selected: $best_decoy"
# Trim best decoy name
trimmed_decoy="${best_decoy%_*_*}"

# Write the best decoy
echo "$best_decoy" > I13R2-scFv47.tag

# Create the PDB file
echo "Extracting PDB file for the best decoy"

extract_pdbs.cxx11threadmpiserialization.linuxgccrelease -in:file:silent decoys_${trimmed_decoy}_traj.out -in:file:tagfile I13R2-scFv47.tag
mv I13R2-scFv47_Hs_*.pdb I13R2-scFv47_Hs.pdb