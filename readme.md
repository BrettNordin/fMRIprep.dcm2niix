# BrettNordin/fMRIprep.dcm2niix
fMRIprep.dcm2niix is designed to convert DICOM format to the NIfTI format.

## Installation
The repository has been desgined to run either in Docker or Singularity:

[Docker Link](https://hub.docker.com/repository/docker/brettnordin/fmriprep.dcm2nii)

[Singularity Link](https://cloud.sylabs.io/library/brettnordin/default/dcm2niix)

## Docker Usage
    
    docker run --rm -it -v /Volumes/DriveA/InputData:/input -v /Volumes/DriveA/OutputData:/output brettnordin/fmriprep.dcm2nii:latest -i /input -o /output
Please replace "/Volumes/DriveA/InputData" and "/Volumes/DriveA/OutputData" with the correct directory locations for your project.

Additonal options:

    -p "sub-1 sub-2"    Specify specific participants to run, seperated by a space and encapsuated by quotation marks. Excluding this option will run all participants located in the input folder.
    
    -c Y    Specifying "-c Y" enables root decompression. Only enable this if the root subject folder in the input files in compressed (.tgz only)

## Singularity Usage
    singularity run --cleanenv -B /Volumes/DriveA/InputData:/input -B /Volumes/DriveA/OutputData:/output library://brettnordin/default/dcm2niix -i /input -o /output 
Please replace "/Volumes/DriveA/InputData" and "/Volumes/DriveA/OutputData" with the correct directory locations for your project.

Additonal options:

     -p "sub-1 sub-2"    Specify specific participants to run, seperated by a space and encapsuated by quotation marks. Excluding this option will run all participants located in the input folder.
     
    -c Y    Specifying "-c Y" enables root decompression. Only enable this if the root subject folder in the input files in compressed (.tgz only)

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Whats included:
Base image: [ubuntu:bionic-20201119](https://uec-images.ubuntu.com/bionic/current/)

Apt-Package jo: [jo Github](https://github.com/jpmens/jo)

Apt-Package jq: [jq Github](https://github.com/stedolan/jq)

Apt-Package pigz: [pigz Github](https://github.com/madler/pigz)

Apt-Package dcm2niix: [dcm2niix Github](https://github.com/rordenlab/dcm2niix)
