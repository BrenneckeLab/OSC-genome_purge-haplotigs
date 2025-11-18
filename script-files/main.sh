#!/usr/bin/bash

#SBATCH --cpus-per-task=4
#SBATCH -e "%x.e.%j.txt"
#SBATCH -o "%x.o.%j.txt"
#SBATCH --time=24:00:00
#SBATCH --qos=medium
#SBATCH --mem=15g

set -u
###################################################################################################
#extract variables
VARI=$1
splitVARI=$(echo "$1" | sed 's/,/\t/g;s/"//g')
eval "$splitVARI"
echo $1 | tr ',' '\n'

TIME=$(date "+%s")

printf "start of pipeline\n\n" >"${LOG}time-log.txt"

###################################################################################################
#setup-phase

TMPdirRAW=$TMPdir
echo $TMPdir
source ${SCRIPTdir}tools

###################################################################################################
###################################################################################################
###################################################################################################
#racon polishing
if [[ ! -f ${OPENdir}/aligned.bam.histogram.png || $FORCE == Y ]]; then
  COMMAND="${SCRIPTdir}map_with_minimap2.sh"
  
  if [[ $COMPUTING == C ]]; then
    sbatch --wait $COMMAND ${VARI} &
  else
    #Simulate arrayID by adding it manually to VARI
    $COMMAND ${VARI}
  fi
fi

###################################################################################################
#mask repeats for purging
if [[ ! -s ${TMPdir}repeats.bed ]]; then
  #detect misassemblies
  COMMAND="${SCRIPTdir}mask_repeats.sh"
  
  if [[ $COMPUTING == C ]]; then
    sbatch --wait $COMMAND ${VARI} &
  else
    #Simulate arrayID by adding it manually to VARI
    VARI="${VARI}"
    $COMMAND  ${VARI}
  fi
fi
 wait
###################################################################################################
if [[ -z $lowCUTOFF || -z $midCUTOFF || -z $highCUTOFF ]]; then
  printf"
  please restart the script providing the cutoff values determined
  from the graph in ${OPENdir}/aligned.bam.histogram.png"
  exit
else
  #purge haplotigs based on cutoff values
  rm -rf ${OPENdir}purging
  mkdir -p ${OPENdir}purging
  cd ${OPENdir}purging
  purge_haplotigs cov -i ${OPENdir}aligned.bam.gencov -l $lowCUTOFF -m $midCUTOFF -h $highCUTOFF
  purge_haplotigs purge -g $assemblyFASTA -c ${OPENdir}purging/coverage_stats.csv -r ${TMPdir}repeats.bed -o purged_
  purge_haplotigs clip -p ${OPENdir}purging/purged_.fasta -h ${OPENdir}purging/purged_.haplotigs.fasta 
  if [[ -f ${OPENdir}purging/clip.fasta ]]; then
    mv ${OPENdir}purging/clip.fasta ${OPENdir}${purgingNAME}_purged_and_clipped.fasta
  else
    mv  ${OPENdir}purging/purged_.fasta ${OPENdir}${purgingNAME}_purged_and_clipped.fasta
  fi
fi



exit
