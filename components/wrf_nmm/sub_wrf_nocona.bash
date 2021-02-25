#!/bin/bash
#SBATCH --chdir=./
#SBATCH --job-name=laura_nmm
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --partition nocona
#SBATCH --account=default
#SBATCH --nodes=3 --ntasks=384
#SBATCH --mem-per-cpu=3G
#SBATCH --array=1-1:1
#SBATCH --account=default

# Set some variables for later
nproc=384  # should be the same as ntasks above
dir=/lustre/scratch/twixtrom/nist_wrf_sims/hurricane_laura/nmm  # empty directory for running WRF in, use $SCRATCH
savedir=/lustre/scratch/twixtrom/NIST_project/hurricane_laura/nmm
indata=${dir}/data  # location of inital and boundary condition data. Should be unset if WPS is already completed.
image=/home/twixtrom/software/containers/wrfv4-nmm-nocona.img  # set location and same of WRF container
wps_nml=/lustre/scratch/twixtrom/nist_wrf_sims/hurricane_laura/nmm/namelist.wps  # set location of WPS namelist. Set WPS_GEOG=/data/WPS_GEOG
wrf_nml=/lustre/scratch/twixtrom/nist_wrf_sims/hurricane_laura/nmm/namelist.input  # set location of WRF namelist
vtable=Vtable.GFS  # set Vtable name appropriate for input data
# met_em=  #  Set location of met_em files if WPS is already completed
user=`whoami`
jid=${SLURM_JOB_ID}
# Create run and save directories if not already done
mkdir -p ${savedir}
mkdir -p ${dir}

# Load MPI
module load gcc openmpi

# $HOME is mounted by default, set environment variable to also bind $WORK and $SCRATCH
export WORK=/lustre/work/${user}
export SCRATCH=/lustre/scratch/${user}
export SINGULARITY_BIND="${WORK},${SCRATCH}"

# Run WPS inside the container
singularity exec ${image} ${dir}/run_wps.bash dir=${dir} wps_nml=${wps_nml} indata=${indata} vtable=${vtable}

cd ${dir}/WPS
mpirun -np ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/WPS/ungrib.exe
mpirun -np ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/WPS/geogrid.exe
mpirun -np ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/WPS/metgrid.exe

# Move metgrid files to save directory
mkdir -p ${dir}/metgrid
mv ${dir}/WPS/met*.nc ${dir}/metgrid
met_dir=${dir}/metgrid

# Clean WPS
rm -r ${dir}/WPS

# Run WRF
cd ${dir}
singularity exec ${image} ${dir}/run_wrf.bash dir=${dir} wrf_nml=${wrf_nml} indata=${indata} met=${met_dir} vtable=${vtable}

# run real.exe
cd ${dir}/run
mpirun -np ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/run/real.exe
cat ${dir}/run/rsl.out.* > ${dir}/rslout_real.log
cat ${dir}/run/rsl.error.* > ${dir}/rslerror_real.log
rm ${dir}/run/rsl.*

# run wrf.exe
mpirun -np ${nproc} -machinefile ${dir}/machinefile.${jid}_1 singularity exec ${image} ${dir}/run/wrf.exe
cat ${dir}/run/rsl.out.* > ${dir}/rslout_wrf.log
cat ${dir}/run/rsl.error.* > ${dir}/rslerror_wrf.log
rm ${dir}/run/rsl.*

# Copy output to save directory
cp ${dir}/run/rsl*.log ${savedir}
cp ${dir}/run/wrfout* ${savedir}

# Clean WRF from run directory
rm -rf ${dir}/run
