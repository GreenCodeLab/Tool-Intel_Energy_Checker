#!/bin/bash

# Directories definitions
# Change the values to run on your own distribution
LIVE_GRAPH_INSTALL_DIR=${HOME}/workspace/LiveGraph.2.0.beta01.Complete
LIVE_GRAPH_JAR_NAME=LiveGraph.2.0.beta01.Complete.jar
IECSDK_INSTALL_DIR=${HOME}/workspace/iecsdk
PL_DIR_NAME=/opt/productivity_link
# Choose the binary you need depending on your architecture
ESRV_BIN_DIR=${IECSDK_INSTALL_DIR}/bin/energy_server/linux/x64
#ESRV_BIN_DIR=${IECSDK_INSTALL_DIR}/bin/energy_server/linux/x86
ESRV_CPU_LIB_DIR=${IECSDK_INSTALL_DIR}/utils/device_driver_kit/build/linux
PL_CSV_LOGGER_DIR=${IECSDK_INSTALL_DIR}/build/linux

OUTPUT_CSV_DIR=/tmp/esrv_csv_log_files

# Cleaning old productivity links & CSV Files
rm -rf ${PL_DIR_NAME}/*
#rm ${OUTPUT_CSV_DIR}/*.csv


#Launching ESRV
${ESRV_BIN_DIR}/esrv --start --library ${ESRV_CPU_LIB_DIR}/esrv_cpu_indexed_simulated_device.so &
sleep 2

# Finding PL Directory
ESRV_PL_DIR_NAME=""
for ESRV_PL_DIR_TEMP_NAME in `/bin/ls -altr /opt/productivity_link | grep esrv | cut -f8 -d" "`
do
  ESRV_PL_DIR_NAME=$ESRV_PL_DIR_TEMP_NAME
done

#echo ESRV_PL_DIR_NAME=${ESRV_PL_DIR_NAME}

# Launching PL CSV Logger & LiveGraph
if [[ ${ESRV_PL_DIR_NAME} != "" ]]
then
  if [[ ! -d ${OUTPUT_CSV_DIR} ]]
  then
    mkdir ${OUTPUT_CSV_DIR}
  fi
  
  OUTPUT_CSV_FILE=${OUTPUT_CSV_DIR}/${ESRV_PL_DIR_NAME}_results.csv
  REGEXP_PL_DIR_NAME=`echo ${PL_DIR_NAME}/${ESRV_PL_DIR_NAME} | sed -e '{s/\//\\\\\//g}'`
  REGEXP_TO_REMOVE="${REGEXP_PL_DIR_NAME}\/\[CHANNEL1\]\ -\ "
  echo REGEXP_PL_DIR_NAME=\"${REGEXP_PL_DIR_NAME}\"
  echo REGEXP_TO_REMOVE=\"${REGEXP_TO_REMOVE}\"
  
  
  # Launching PL CSV Logger
  echo "*********************************************"
  echo "* PL CSV Logger: START                      *"
  echo "*********************************************"
  ${PL_CSV_LOGGER_DIR}/pl_csv_logger ${PL_DIR_NAME}/${ESRV_PL_DIR_NAME}/pl_config.ini --output ${OUTPUT_CSV_FILE} --process &
  
  sleep 2
  
  # Launching LiveGraph
  echo "*********************************************"
  echo "* LiveGraph: START                          *"
  echo "*********************************************"
  java -jar ${LIVE_GRAPH_INSTALL_DIR}/${LIVE_GRAPH_JAR_NAME} -f ${OUTPUT_CSV_FILE} -dfs ESRV-DataFileSettings.lgdfs -gs ESRV-GraphSettings.lggs -dss ESRV-DataSeriesSettings.lgdss
    
else
  echo "Impossible to find the PL Directory of a currently running ESRV instance"
fi

# Stopping ESRV
${ESRV_BIN_DIR}/esrv --stop