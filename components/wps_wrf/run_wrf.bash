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
	    jid)                  jid=${VALUE} ;;
            *)
    esac


done

# Check if WPS is already completed. Controlled by met_em parameter. If a path is supplied,
# it is assumed that this directory contains already completed met_em files. If not,
# WPS is run within the container to generate WRF input.
if [ -n "$indata" ]; then
  # run WPS
  mkdir ${dir}/WPS
  cd ${dir}/WPS
  ln -sf /comsoftware/wrf/WPS-${WPS_VERSION}/* ${dir}/WPS
  rm ${dir}/WPS/namelist.wps
  cp ${wps_nml} ${dir}/WPS/namelist.wps
  mkdir -p ${dir}/WPS/data
  cp ${indata}/* ${dir}/WPS/data
  /bin/csh ${dir}/WPS/link_grib.csh ${dir}/WPS/data/*
  ln -sf ${dir}/WPS/ungrib/Variable_Tables/${vtable} ${dir}/WPS/Vtable
  ${dir}/WPS/ungrib.exe
  ${dir}/WPS/geogrid.exe
  ${dir}/WPS/metgrid.exe
  met_em_dir=${dir}/WPS
else
  # don't run WPS and assume met_em file location is supplied
  met_em_dir=${met_em}
fi

# Copy WRF run directory and executables
cd ${dir}
mkdir ${dir}/run
cd ${dir}/run
ln -sf /comsoftware/wrf/WRF-${WRF_VERSION}/run/* ${dir}/run
ln -sf /comsoftware/wrf/WRF-${WRF_VERSION}/main/*.exe ${dir}/run

# Link met_em files
ln -sf ${met_em_dir}/met_em* ${dir}/run

# copy in supplied namelist
rm ${dir}/run/namelist.input
cp ${wrf_nml} ${dir}/run/namelist.input
