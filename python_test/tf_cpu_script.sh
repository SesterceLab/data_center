#!/bin/bash
#SBATCH --job-name=tf_mnist_cpu
#SBATCH --output=tf_mnist_cpu.out
#SBATCH --error=tf_mnist_cpu.err
#SBATCH --nodes=2
#SBATCH --cpus-per-task=2  # Number of CPU cores per task
#SBATCH --partition=debug
#SBATCH --time=00:30:00

# Activate your virtual environment (if applicable)
# source activate your_virtual_environment

# Path to your TensorFlow MNIST script
MNIST_SCRIPT_PATH="/storage/tf_cpu_dist.py"

# Run the TensorFlow script with Horovod for distributed training
mpirun -np $SLURM_NTASKS python $MNIST_SCRIPT_PATH
