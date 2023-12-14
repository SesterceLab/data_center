#!/bin/bash
#SBATCH --job-name=tf_mnist
#SBATCH --output=tf_mnist.out
#SBATCH --error=tf_mnist.err
#SBATCH --nodes=2
#SBATCH --gres=gpu:2
#SBATCH --partition=gpu
#SBATCH --time=00:30:00

# Load necessary modules
module load cuda/11.0
module load cudnn/8.0.5-cuda-11.0

# Activate your virtual environment (if applicable)
# source activate your_virtual_environment

# Path to your TensorFlow MNIST script
MNIST_SCRIPT_PATH="/path/to/your/mnist_script.py"

# Specify the number of GPUs per node
GPUS_PER_NODE=2

# Determine the total number of GPUs available
TOTAL_GPUS=$((SLURM_JOB_NUM_NODES * GPUS_PER_NODE))

# Set the batch size and learning rate for training
BATCH_SIZE=64
LEARNING_RATE=0.001

# Calculate the effective batch size per GPU
EFFECTIVE_BATCH_SIZE=$((BATCH_SIZE / TOTAL_GPUS))

# Run the TensorFlow script with Horovod for distributed training
srun -N $SLURM_JOB_NUM_NODES -n $TOTAL_GPUS --mpi=pmi2 \
    python $MNIST_SCRIPT_PATH \
    --batch_size=$EFFECTIVE_BATCH_SIZE \
    --learning_rate=$LEARNING_RATE
