#!/usr/bin/bash

#SBATCH --cpus-per-task=30
#SBATCH -e "%x.e.%j-%a.txt"
#SBATCH -o "%x.o.%j-%a.txt"
#SBATCH --qos=short
#SBATCH --partition=m
#SBATCH --time=8:00:00
#SBATCH --mem=100g

TMPDIR=${SCRATCHDIR}

set -u
HOST=$(hostname)
echo $HOST

###################################################################################################
#extract variables if computing on PIWI

#check if host is piwi and process variables accordingly
VARI=$(echo "$1" | sed 's/,/\t/g;s/"//g')
eval "$VARI"

if [[ $VARI == *"COMPUTING=C"* ]]; then
  echo ${JOB_ID+x} >>"${TMPdir}jobIDs.txt"
fi

TIME=$(date "+%s")

source ${SCRIPTdir}tools

###################################################################################################
#setup-phase

locTMP=${TMPdir}map_reads/
mkdir -p ${locTMP}

###################################################################################################
#map reads to assembled genome using minimap2

THREADS=$(( $SLURM_CPUS_PER_TASK * 2 ))

if [[ ! -f ${TMPdir}minimap_index.mmi || $FORCE == Y ]]; then
  minimap2 -d ${TMPdir}minimap_index.mmi ${assemblyFASTA}
fi

MEMavail=$(scontrol show job $SLURM_JOBID  | awk '{ 
  if($0~"TRES="){
    split($1,X,/,|=/) 
    if( X[5]~"G"){
      sub("G","",X[5])
      print X[5]
    }else{
      print 20 
    }
  }}')
MEMORY=$(( ( $MEMavail - 10 ) / $SLURM_CPUS_PER_TASK ))

if [[ ! -f ${TMPdir}aligned.bam || $FORCE == Y ]]; then
  minimap2 -t $THREADS -2 -ax map-ont ${TMPdir}minimap_index.mmi $rawFASTA --secondary=no |
    samtools sort -m ${MEMORY}G -@ $SLURM_CPUS_PER_TASK -o ${TMPdir}aligned.bam -T ${locTMP}tmp.ali
fi

###################################################################################################
#generate histogram for coverage statistic

cd $OPENdir
purge_haplotigs hist -b ${TMPdir}aligned.bam -g $assemblyFASTA -t $SLURM_CPUS_PER_TASK
