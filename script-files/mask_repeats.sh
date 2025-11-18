#!/bin/bash

#SBATCH --cpus-per-task=25
#SBATCH --mem=40g
#SBATCH -e "%x.e.%j.txt"
#SBATCH -o "%x.o.%j.txt"
#SBATCH --qos=short

hostname
set -u

###################################################################################################
#extract variables
VARI=$(echo "$1" | sed 's/,/\t/g;s/"//g')
eval "$VARI"

TIME=$(date "+%s")

###################################################################################################
#setup-phase

#create path variables
topOPENdir=$OPENdir
locTMP=${TMPdir}mask_repeats/

#create directories
mkdir $locTMP

#load tools
source ${SCRIPTdir}tools

###################################################################################################

cd ${locTMP}

assemblyNAME=$(basename $assemblyFASTA)
cp $assemblyFASTA ${locTMP}${assemblyNAME}

#mask repeats using Repeatmasker
RepeatMasker -qq -e rmblast -pa $SLURM_CPUS_PER_TASK -dir ${locTMP} -species "Drosophila melanogaster" ${assemblyNAME}
rmsk2bed <${locTMP}${assemblyNAME}.out | bedops --merge - > ${TMPdir}repeats.bed

###################################################################################################
#finish script

#clean up
if [[ $DEBUG == N ]]; then
  rm -rf $locTMP
fi

#report processing time
PROCESSED_TIME=$(echo -e $(date "+%s") $TIME | awk '{ print ($1-$2)/60 }')
echo "mask repeats=" ${PROCESSED_TIME} >>${LOG}time-log.txt

