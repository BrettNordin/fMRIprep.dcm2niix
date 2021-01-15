#!/bin/bash

set -e
####Defining pathways
while getopts i:o:p:c: option
do
    case "${option}"
        in
        i) INPUT=${OPTARG};;
        o) OUTPUT=${OPTARG};;
        p) PLIST=${OPTARG};;
        c) COMPR=${OPTARG};;
    esac
done

if [ -z ${INPUT} ]
then
    echo "-i cannot be blank"
    exit 0
fi
if [ -z ${OUTPUT} ]
then
    echo "-o cannot be blank"
    exit 0
fi

echo "Welcome to the Automatic Dicom Conversion Tool.."
echo "Output DIR: "${OUTPUT}
echo "Input DIR: "${INPUT}
niidir=${OUTPUT}
dcmdir=${INPUT}
###Create dataset_description.json
jo -p "Name"="Data!" "BIDSVersion"="1.0.2" >> ${niidir}/dataset_description.json

#Check to see if decompression is needed.
if [ -z ${COMPR} ]
then
    echo "Root Compression Check Disabled"
else
    if [ ${COMPR}=="y" ]
    then
        for dies in "${dcmdir}/*"; do
            tar zxvf $dies -C ${dcmdir}/*
        done
    fi
fi

#See if user specified participants. If not run em all!
if [ -z ${PLIST} ]
then
	echo "No participants Defined, Running all participants"
    for subj in $(ls ${dcmdir}/); do
		subb=$subj 
		if [[ $subj == *"sub-"* ]]; then
            echo "Processing subject $subj"
        else
            subj="sub-${subj}"
            echo "Processing subject $subj"
        fi
        mkdir -p ${niidir}/${subj}/anat
        mkdir -p ${niidir}/${subj}/func
		cd ${dcmdir}/${subb}
        for direcs in T1; do
            #Extract the compressed dicom
            for fil in "${dcmdir}/${subb}/${direcs}/*.tgz"; do
                tar zxvf $fil -C ${dcmdir}/${subb}/${direcs}
            done
            dcm2niix -o ${niidir}/${subj} -f ${subj}_%f_%p ${dcmdir}/${subb}/${direcs}
        done
        #Changing directory into the subject folder
        cd ${niidir}/${subj}
        #Move the files arround
        mv ${niidir}/${subj}/*.nii ${niidir}/${subj}/anat/${subj}_T1w.nii
        mv ${niidir}/${subj}/*.json ${niidir}/${subj}/anat/${subj}_T1w.json

        #Func Conversion
        cd ${dcmdir}/${subb}
        for direcs in fMRI; do
            #Extract the compressed dicom
            for fil in "${dcmdir}/${subb}/${direcs}/*.tgz"; do
                tar zxvf $fil -C ${dcmdir}/${subb}/${direcs}
            done
            dcm2niix -o ${niidir}/${subj} -f ${subj}_%f_%p ${dcmdir}/${subb}/${direcs}
        done
        #Changing directory into the subject folder
        cd ${niidir}/${subj}
        #Move the files arround
        mv ${niidir}/${subj}/*.nii ${niidir}/${subj}/func/${subj}_task-rest_run-01_bold.nii
        mv ${niidir}/${subj}/*.json ${niidir}/${subj}/func/${subj}_task-rest_run-01_bold.json
        
        ###Check func json for required fields
        cd ${niidir}/${subj}/func #Go into the func folder
        for funcjson in $(ls ${niidir}/${subj}/func/*.json); do
            #Does TaskName exist?
            taskexist=$(cat ${funcjson} | jq '.TaskName')
            if [ "$taskexist" == "null" ]; then
                jsonname="${funcjson%.*}"
                taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
                jq '. |= . + {"TaskName":"'${taskfield}'"}' ${funcjson} > tasknameadd.json
                rm ${funcjson}
                mv tasknameadd.json ${funcjson}
                echo "TaskName was added to ${jsonname} and matches the tasklabel in the filename"
            else
                Taskquotevalue=$(jq '.TaskName' ${funcjson})
                Taskvalue=$(echo $Taskquotevalue | cut -d '"' -f2)
                jsonname="${funcjson%.*}"
                taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
                if [ $Taskvalue == $taskfield ]; then
                    echo "TaskName is present and matches the tasklabel in the filename"
                else
                    echo "TaskName and tasklabel do not match"
                fi
            fi
        done
    done
else
    for subj in ${PLIST}; do
        if [[ $subj == *"sub-"* ]]; then
            echo "Processing subject $subj"
        else
            subj="sub-${subj}"
            echo "Processing subject $subj"
        fi
        ###Create structure
        mkdir -p ${niidir}/${subj}/anat
        mkdir -p ${niidir}/${subj}/func
        
        #Anat Conversion
        cd ${dcmdir}/${subj}
        for direcs in T1; do
            #Extract the compressed dicom
            for fil in "${dcmdir}/${subj}/${direcs}/*.tgz"; do
                tar zxvf $fil -C ${dcmdir}/${subj}/${direcs}
            done
            dcm2niix -o ${niidir}/${subj} -f ${subj}_%f_%p ${dcmdir}/${subj}/${direcs}
        done
        #Changing directory into the subject folder
        cd ${niidir}/${subj}
        #Move the files arround
        mv ${niidir}/${subj}/*.nii ${niidir}/${subj}/anat/${subj}_T1w.nii
        mv ${niidir}/${subj}/*.json ${niidir}/${subj}/anat/${subj}_T1w.json
        
        #Func Conversion
        cd ${dcmdir}/${subj}
        for direcs in fMRI; do
            #Extract the compressed dicom
            for fil in "${dcmdir}/${subj}/${direcs}/*.tgz"; do
                tar zxvf $fil -C ${dcmdir}/${subj}/${direcs}
            done
            dcm2niix -o ${niidir}/${subj} -f ${subj}_%f_%p ${dcmdir}/${subj}/${direcs}
        done
        #Changing directory into the subject folder
        cd ${niidir}/${subj}
        #Move the files arround
        mv ${niidir}/${subj}/*.nii ${niidir}/${subj}/func/${subj}_task-rest_run-01_bold.nii
        mv ${niidir}/${subj}/*.json ${niidir}/${subj}/func/${subj}_task-rest_run-01_bold.json
        
        ###Check func json for required fields
        cd ${niidir}/${subj}/func #Go into the func folder
        for funcjson in $(ls ${niidir}/${subj}/func/*.json); do
            #Does TaskName exist?
            taskexist=$(cat ${funcjson} | jq '.TaskName')
            if [ "$taskexist" == "null" ]; then
                jsonname="${funcjson%.*}"
                taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
                jq '. |= . + {"TaskName":"'${taskfield}'"}' ${funcjson} > tasknameadd.json
                rm ${funcjson}
                mv tasknameadd.json ${funcjson}
                echo "TaskName was added to ${jsonname} and matches the tasklabel in the filename"
            else
                Taskquotevalue=$(jq '.TaskName' ${funcjson})
                Taskvalue=$(echo $Taskquotevalue | cut -d '"' -f2)
                jsonname="${funcjson%.*}"
                taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
                if [ $Taskvalue == $taskfield ]; then
                    echo "TaskName is present and matches the tasklabel in the filename"
                else
                    echo "TaskName and tasklabel do not match"
                fi
            fi
        done
    done
fi

echo "Task complete, files located in your output folder are ready"
