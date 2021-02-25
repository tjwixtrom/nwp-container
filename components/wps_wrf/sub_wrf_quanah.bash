#!/bin/bash
#SBATCH --chdir=./
#SBATCH --job-name=wrf_test
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --partition quanah
#SBATCH --account=default
#SBATCH --nodes=10 --ntasks=360
#SBATCH --time=10:00:00
#SBATCH --mem-per-cpu=5G
#SBATCH --array=1-1:1
#SBATCH --account=default

# Set some variables for later
nproc=360  # should be the same as ntasks above
dir=/lustre/scratch/twixtrom/wrf_test  # empty directory for running WRF in, use $SCRATCH
savedir=/lustre/scratch/twixtrom/wrf_save
indata=${dir}/data  # location of inital and boundary condition data. Should be unset if WPS is already completed.
image=/home/twixtrom/software/containers/wrfv4-quanah.img  # set location and same of WRF container
wps_nml=/lustre/scratch/twixtrom/wrf_test/namelist.wps  # set location of WPS namelist. Set WPS_GEOG=/data/WPS_GEOG
wrf_nml=/lustre/scratch/twixtrom/wrf_test/namelist.input  # set location of WRF namelist
vtable=Vtable.GFS  # set Vtable name appropriate for input data
# met_em=  #  Set location of met_em files if WPS is already completed
user=`whoami`
jid=${SLURM_JOB_ID}
# Create run and save directories if not already done
mkdir -p ${savedir}
mkdir -p ${dir}

# Load MPI
module load singularity
module load gnu7 openmpi3/3.0.0

# $HOME is mounted by default, set environment variable to also bind $WORK and $SCRATCH
export WORK=/lustre/work/${user}
export SCRATCH=/lustre/scratch/${user}
export SINGULARITY_BIND="${WORK},${SCRATCH}"

# Launch the container and execute the supplied script
cd ${dir}
singularity exec ${image} ${dir}/run_wrf.bash jid=${jid} nproc=${nproc} dir=${dir} wps_nml=${wps_nml} wrf_nml=${wrf_nml} indata=${indata} met_em=${met_em} vtable=${vtable}

# run real.exe
cd ${dir}/run
mpirun -n ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/run/real.exe
cat ${dir}/run/rsl.out.* > ${dir}/rslout_real.log
cat ${dir}/run/rsl.error.* > ${dir}/rslerror_real.log
rm ${dir}/run/rsl.*

# run wrf.exe
mpirun -n ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/run/wrf.exe
cat ${dir}/run/rsl.out.* > ${dir}/rslout_wrf.log
cat ${dir}/run/rsl.error.* > ${dir}/rslerror_wrf.log
rm ${dir}/run/rsl.*

# Copy output to save directory
cp ${dir}/run/rsl*.log ${savedir}
cp ${dir}/run/wrfout* ${savedir}

# Clean WRF and WPS from run directory
rm -rf ${dir}/WPS*
rm -rf ${dir}/run
