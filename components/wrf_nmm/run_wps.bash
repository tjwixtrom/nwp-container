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
            wps_nml)          wps_nml=${VALUE} ;;
            indata)            indata=${VALUE} ;;
            vtable)            vtable=${VALUE} ;;
            *)
    esac

done

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
