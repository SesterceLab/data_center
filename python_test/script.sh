#!/bin/bash
#SBATCH -n 4 #core
#SBATCH -N 2 #node
#SBATCH -t 0-0:2 #time D-HH:MM
#SBATCH -p debug # partition
#SBATCH --mem=2000 #  ram
#SBATCH -o myjob.o # 
#SBATCH -e myjob.e # 
#SBATCH --mail-type=ALL # 
#SBATCH --mail-user=honbo@sesterce.com # 
#SBATCH --gres=gpu:0 #
srun python3 /storage/test.py
