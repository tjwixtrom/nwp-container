#!/bin/sh
# Runscript for executing WPS/WRF within a singularity containers
# Maintained by Tyler Wixtrom <tyler.wixtrom@ttu.edu>

# Parse input arguments
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            nproc)              nproc=${VALUE} ;;
            dir)                  dir=${VALUE} ;;
            wps_nml)          wps_nml=${VALUE} ;;
            wrf_nml)          wrf_nml=${VALUE} ;;
            indata)            indata=${VALUE} ;;
            met_em)            met_em=${VALUE} ;;
            vtable)            vtable=${VALUE} ;;
            *)
    esac


done

# Check if WPS is already completed. Controlled by met_em parameter. If a path is supplied,
# it is assumed that this directory contains already completed met_em files. If not,
# WPS is run within the container to generate WRF input.
if [ -n "$indata" ]; then
  # run WPS
  cp -r /comsoftware/wrf/WPS-${WPS_VERSION} ${dir}
  cp ${wps_nml} ${dir}/WPS-${WPS_VERSION}/namelist.wps
  mkdir -p ${dir}/WPS-${WPS_VERSION}/data
  cp ${indata}/* ${dir}/WPS-${WPS_VERSION}/data
  cd ${dir}/WPS-${WPS_VERSION}
  /bin/csh ${dir}/WPS-${WPS_VERSION}/link_grib.csh ${dir}/WPS-${WPS_VERSION}/data/*
  cp ${dir}/WPS-${WPS_VERSION}/ungrib/Variable_Tables/${vtable} ${dir}/WPS-${WPS_VERSION}/Vtable
  ${dir}/WPS-${WPS_VERSION}/ungrib.exe
  ${dir}/WPS-${WPS_VERSION}/geogrid.exe
  ${dir}/WPS-${WPS_VERSION}/metgrid.exe
  met_em_dir=${dir}/WPS-${WPS_VERSION}
else
  # don't run WPS and assume met_em file location is supplied
  met_em_dir=${met_em}
fi

# Copy WRF run directory and executables
cd ${dir}
cp -r /comsoftware/wrf/WRF-${WRF_VERSION}/run ${dir}
cp /comsoftware/wrf/WRF-${WRF_VERSION}/main/*.exe ${dir}/run

cd ${dir}/run

# Link met_em files
ln -sf ${met_em_dir}/met_em* ${dir}/run

# copy in supplied namelist
cp ${wrf_nml} ${dir}/run/namelist.input

# run real.exe
mpirun -np ${nproc} ${dir}/run/real.exe
cat ${dir}/run/rsl.out.* > ${dir}/rslout_real.log
cat ${dir}/run/rsl.error.* > ${dir}rslerror_real.log
rm ${dir}/run/rsl.*

# run wrf.exe
mpirun -np ${nproc} ${dir}/run/wrf.exe
cat ${dir}/run/rsl.out.* > ${dir}rslout_wrf.log
cat ${dir}/run/rsl.error.* > ${dir}rslerror_wrf.log
rm ${dir}/run/rsl.*
