#!/bin/bash

set -e 
####Defining pathways
while getopts i:o:p: option
do
case "${option}"
in
i) INPUT=${OPTARG};;
o) OUTPUT=${OPTARG};;
p) PLIST=${OPTARG};;
esac
done
echo "Welcome to the Automatic Dicom Conversion Tool.."
c="/home/dcmnii"
echo "Output DIR: "${OUTPUT}
echo "Input DIR: "${INPUT}
niidir=${OUTPUT}
dcmdir=${INPUT}
###Create dataset_description.json
jo -p "Name"="Kelseys Data!" "BIDSVersion"="1.0.2" >> ${niidir}/dataset_description.json

####Anatomical Organization####
for subj in ${PLIST}; do
	echo "Processing subject $subj"

###Create structure
mkdir -p ${niidir}/sub-${subj}/ses-1/anat


###Convert dcm to nii
#Only convert the Dicom folder anat
for direcs in anat; do
dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_%f_%p ${dcmdir}/${subj}/${direcs}
done

#Changing directory into the subject folder
cd ${niidir}/sub-${subj}

###Change filenames
##Rename anat files
#Example filename: 2475376_anat_MPRAGE
#BIDS filename: sub-2475376_ses-1_T1w
#Capture the number of anat files to change
anatfiles=$(ls -1 *MPRAGE* | wc -l)
for ((i=1;i<=${anatfiles};i++)); do
Anat=$(ls *MPRAGE*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
tempanat=$(ls -1 $Anat | sed '1q;d') #Capture new file to change
tempanatext="${tempanat##*.}"
tempanatfile="${tempanat%.*}"
mv ${tempanatfile}.${tempanatext} sub-${subj}_ses-1_T1w.${tempanatext}
echo "${tempanat} changed to sub-${subj}_ses-1_T1w.${tempanatext}"
done 

###Organize files into folders
for files in $(ls sub*); do 
Orgfile="${files%.*}"
Orgext="${files##*.}"
Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
if [ $Modality == "T1w" ]; then
	mv ${Orgfile}.${Orgext} ses-1/anat
else
:
fi 
done

####Functional Organization####
#Create subject folder
mkdir -p ${niidir}/sub-${subj}/{ses-1,ses-2}/func

###Convert dcm to nii
for direcs in TfMRI_breathHold_1400 TfMRI_eyeMovementCalibration_1400 TfMRI_eyeMovementCalibration_645 TfMRI_visualCheckerboard_1400 TfMRI_visualCheckerboard_645 session1 session2; do
if [[ $direcs == "session1" || $direcs == "session2" ]]; then
for rest in RfMRI_mx_645 RfMRI_mx_1400 RfMRI_std_2500; do 
dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_${direcs}_%p ${dcmdir}/${subj}/${direcs}/${rest}
done
else
dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_${direcs}_%p ${dcmdir}/${subj}/${direcs}
fi
done

#Changing directory into the subject folder
cd ${niidir}/sub-${subj}

#Rest
#Example filename: 2475376_session1_REST_645_RR
#BIDS filename: sub-2475376_ses-1_task-rest_acq-TR645_bold
#Breakdown rest scans into each TR
for TR in 645 1400 CAP; do 
for corrun in $(ls *REST_${TR}*); do
corrunfile="${corrun%.*}"
corrunfileext="${corrun##*.}"
Sessionnum=$(echo $corrunfile | cut -d '_' -f2)
sesnum=$(echo "${Sessionnum: -1}") 
if [ $sesnum == 2 ]; then 
ses=2
else
	ses=1
fi
if [ $TR == "CAP" ]; then
	TR=2500
else
	:
fi
mv ${corrunfile}.${corrunfileext} sub-${subj}_ses-${ses}_task-rest_acq-TR${TR}_bold.${corrunfileext}
echo "${corrun} changed to sub-${subj}_ses-${ses}_task-rest_acq-TR${TR}_bold.${corrunfileext}"
done
done

###Organize files into folders
for files in $(ls sub*); do 
Orgfile="${files%.*}"
Orgext="${files##*.}"
Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
Sessionnum=$(echo $Orgfile | cut -d '_' -f2)
Difflast=$(echo "${Sessionnum: -1}")
if [[ $Modality == "bold" && $Difflast == 2 ]]; then
	mv ${Orgfile}.${Orgext} ses-2/func
else
if [[ $Modality == "bold" && $Difflast == 1 ]]; then
	mv ${Orgfile}.${Orgext} ses-1/func
fi 
fi
done

###Check func json for required fields
#Required fields for func: 'RepetitionTime','VolumeTiming' or 'SliceTiming', and 'TaskName'
#capture all jsons to test
for sessnum in ses-1 ses-2; do
cd ${niidir}/sub-${subj}/${sessnum}/func #Go into the func folder
for funcjson in $(ls *.json); do 

#Repeition Time exist?
repeatexist=$(cat ${funcjson} | jq '.RepetitionTime')
if [[ ${repeatexist} == "null" ]]; then   
	echo "${funcjson} doesn't have RepetitionTime defined"
else
echo "${funcjson} has RepetitionTime defined"
fi

#VolumeTiming or SliceTiming exist?
#Constraint SliceTiming can't be great than TR
volexist=$(cat ${funcjson} | jq '.VolumeTiming')
sliceexist=$(cat ${funcjson} | jq '.SliceTiming')
if [[ ${volexist} == "null" && ${sliceexist} == "null" ]]; then
echo "${funcjson} doesn't have VolumeTiming or SliceTiming defined"
else
if [[ ${volexist} == "null" ]]; then
echo "${funcjson} has SliceTiming defined"
#Check SliceTiming is less than TR
sliceTR=$(cat ${funcjson} | jq '.SliceTiming[] | select(.>="$repeatexist")')
if [ -z ${sliceTR} ]; then
echo "All SliceTiming is less than TR" #The slice timing was corrected in the newer dcm2niix version called through command line
else
echo "SliceTiming error"
fi
else
echo "${funcjson} has VolumeTiming defined"
fi
fi

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


echo "Task complete, files located in your output folder are ready"