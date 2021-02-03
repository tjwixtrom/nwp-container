#!/bin/bash
#SBATCH --chdir=./
#SBATCH --job-name=wrf_test
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --partition nocona
#SBATCH --account=default
#SBATCH --nodes=1 --ntasks=64
#SBATCH --time=10:00:00
#SBATCH --mem-per-cpu=3G
#SBATCH --array=1-1:1

# Set some variables for later
nproc=64  # should be the same as ntasks above
dir=/lustre/scratch/twixtrom/wrf_test  # empty directory for running WRF in, use $SCRATCH
savedir=/lustre/scratch/twixtrom/wrf_save
indata=${dir}/data  # location of inital and boundary condition data. Should be unset if WPS is already completed.
image=/home/twixtrom/software/containers/wrfv4.img  # set location and same of WRF container
wps_nml=/lustre/scratch/twixtrom/wrf_test/namelist.wps  # set location of WPS namelist. Set WPS_GEOG=/data/WPS_GEOG
wrf_nml=/lustre/scratch/twixtrom/wrf_test/namelist.input  # set location of WRF namelist
vtable=Vtable.GFS  # set Vtable name appropriate for input data
# met_em=  #  Set location of met_em files if WPS is already completed
user=`whoami`

# Create run and save directories if not already done
mkdir -p ${savedir}
mkdir -p ${dir}

# $HOME is mounted by default, set environment variable to also bind $WORK and $SCRATCH
export WORK=/lustre/work/${user}
export SCRATCH=/lustre/scratch/${user}
export SINGULARITY_BIND="${WORK},${SCRATCH}"

# Launch the container and execute the supplied script
cd ${dir}
singularity exec ${image} ${dir}/run_wrf.bash nproc=${nproc} dir=${dir} wps_nml=${wps_nml} wrf_nml=${wrf_nml} indata=${indata} met_em=${met_em} vtable=${vtable}

# Copy output to save directory
cp ${dir}/run/rsl*.log ${savedir}
cp ${dir}/run/wrfout* ${savedir}

# Clean WRF and WPS from run directory
rm -rf ${dir}/WPS*
rm -rf ${dir}/run
