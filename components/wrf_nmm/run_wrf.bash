#!/bin/sh
# Runscript for executing WPS/WRF within a singularity containers
# Maintained by Tyler Wixtrom <tyler.wixtrom@ttu.edu>

# Parse input arguments
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            dir)                  dir=${VALUE} ;;
            wrf_nml)          wrf_nml=${VALUE} ;;
            met)                  met=${VALUE} ;;
            vtable)            vtable=${VALUE} ;;
            *)
    esac


done

# Copy WRF run directory and executables
cd ${dir}
mkdir ${dir}/run
cd ${dir}/run
ln -sf /comsoftware/wrf/WRF-${WRF_VERSION}/run/* ${dir}/run
ln -sf /comsoftware/wrf/WRF-${WRF_VERSION}/main/*.exe ${dir}/run

# Link met_em files
ln -sf ${met}/met*.nc ${dir}/run

# copy in supplied namelist
rm ${dir}/run/namelist.input
cp ${wrf_nml} ${dir}/run/namelist.input
