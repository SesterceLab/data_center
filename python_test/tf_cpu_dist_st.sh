#!/bin/bash
#SBATCH --job-name=tf_distributed
#SBATCH --output=tf_distributed.out
#SBATCH --error=tf_distributed.err
#SBATCH --nodes=2
#SBATCH --ntasks=2

# Activate your virtual environment (if applicable)
# source activate your_virtual_environment

# Load necessary modules and activate TensorFlow environment
#module load cuda/11.0
#source activate your_tensorflow_environment

# Run the TensorFlow script with Slurm
srun -N 2 -n 2 python3 /storage/tf_cpu_dist_st.py
