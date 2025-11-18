###############################################################################################
set -u 

 # Argument = -i input -c chunksize -D blast-database -v
usage()
{
  cat << EOF
  usage: $0 options
  
  ###############################################################################
  This tool calculates read counts on a template of choice. It reportes the 
  counts for both, the sense and the antisense strand.
  
  usage: [PATH]/selectUTRs [options] -F 
  
  OPTIONS:
      -h  Show this message
      -A  assembly fasta file to be purged
          results will be depostied into the very same directory of the fasta file in a new subfolder
      -N  Name for the purging run
      -r  raw-reads used for assembly (will be used genome-purging)
      -L  low cutoff - depending on coverage graph 
      -M  middle cutoff - depending on coverage graph 
      -H  high cutoff - depending on coverage graph 
      -C  set flag for local processing (use only if multiple cores available)
      -D  sed debug mode - does not trigger git commit
      -F  force regeneration of all steps
EOF
}

assemblyFASTA=
purgingNAME=
rawFASTA=
lowCUTOFF=
midCUTOFF=
highCUTOFF=
COMPUTING=C
DEBUG=N
FORCE=

while getopts ÒhA:N:G:r:L:M:H:P:CDaF,Ó OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    A)
      assemblyFASTA=$OPTARG
      ;;
    N)
      purgingNAME=$OPTARG
      ;;
    r)
      rawFASTA=$OPTARG
      ;;
    L)
      lowCUTOFF=$OPTARG
      ;;
    M)
      midCUTOFF=$OPTARG
      ;;
    H)
      highCUTOFF=$OPTARG
      ;;
    C)
      COMPUTING=L
      ;;
    D)
      DEBUG=Y
      ;;
    F)
      FORCE=Y
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

###################################################################################################
#fixed variables
rawTMP=

#extract base-path from input fasta
if [[ -z $purgingNAME ]]; then
  #usage
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
  printf "       Please provide purgingNAME in option N!\n"
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
  exit
fi
if [[ -z $rawFASTA ]]; then
  #usage
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
  printf "       Please provide rawFASTA used for assembly in option r!\n"
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
  exit
fi

#extract base-path from input fasta
if [[ -z $assemblyFASTA ]]; then
  #usage
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
  printf "       Please provide assemblyFASTA in option A!\n"
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
  exit
else
  ASSEMBLYdir=$(dirname $assemblyFASTA)
  ASSEMBLYbasename=$(basename $ASSEMBLYdir)
  ASSEMBLYname=$(basename $assemblyFASTA)
  ASSEMBLYname="${ASSEMBLYname%.*}"

  TMPdir="${rawTMP}/${ASSEMBLYbasename}_${ASSEMBLYname}/${purgingNAME}/"
  OPENdir="${ASSEMBLYdir}/purge_${purgingNAME}/"
fi


if [[ -f ${OPENdir}/aligned.bam.histogram.png && (-z $lowCUTOFF || -z $midCUTOFF || -z $highCUTOFF ) ]]; then
  #usage
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
  printf "       Please provide all 3 cutoff values in options L, M, H !\n"
  printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
  exit
else
  HISTswitch=Y
fi


#@!@#
#separator for printing of settings to log
###################################################################################################
#variable-setup
DATE_OF_DAY=$(date +%F)
FULL_DATE=$(date)
#DATE_OF_DAY=2017-02-14

mkdir -p $OPENdir

VERSION=$( ls -l ${OPENdir} | wc -l )
VERSION="V$VERSION"


SINGULARITYdir=${rawTMP}singu/


if [[ $FORCE == Y ]]; then
  rm -rf $TMPdir
  rm -rf $OPENdir
  rm -rf $SINGULARITYdir
fi

mkdir -p $OPENdir
mkdir -p $TMPdir
mkdir -p $SINGULARITYdir

###################################################################################################
#preset scripts

#determine script-location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

SCRIPTdirRAW="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SCRIPTdirRAW="${SCRIPTdirRAW}/"
SCRIPTdir="${SCRIPTdirRAW}script-files/"
UTILITYdir="${SCRIPTdirRAW}utility-files/"

#move scripts to TMP-directory
rm -rf ${TMPdir}script-files
cp -r ${SCRIPTdir} ${TMPdir}script-files
SCRIPTdir=${TMPdir}script-files/

mv ${TMPdir}script-files/main.sh ${TMPdir}script-files/Purge-${purgingNAME}

###############################################################################################
#download all singularity images required

cd ${SINGULARITYdir}

wget -O minimap2.app https://brenneckelab.imba.oeaw.ac.at/Publication_Data/2025_Handler_OSC-genome/Apptainer/minimap2.app
wget -O purge_haplotigs.app https://brenneckelab.imba.oeaw.ac.at/Publication_Data/2025_Handler_OSC-genome/Apptainer/purge_haplotigs.app
wget -O basicTools.app https://brenneckelab.imba.oeaw.ac.at/Publication_Data/2025_Handler_OSC-genome/Apptainer/basicTools.app
wget -O repeatmasker.app https://brenneckelab.imba.oeaw.ac.at/Publication_Data/2025_Handler_OSC-genome/Apptainer/repeatmasker.app

###################################################################################################
#report settings and initiate log-files

printf "Analysis start DATE+TIME = ${FULL_DATE}\n" >> "${OPENdir}log.txt"

cd ${SCRIPTdirRAW}

if [[ $DEBUG != Y ]] 
then 

  #ask for commit-message
  while true; do
    read -r -p "Plese specify a commit-message: " msg
    case $msg in
        [Nn] ) break;;
        * ) commitMESSAGE=$msg; break;;
    esac
  done
  
  #commit all changes
  git add .
  if [[ -z $commitMESSAGE ]]
  then
    git commit -m "automatic commit on submission"
  else
    git commit -m "$commitMESSAGE"
  fi
  #git push --all
fi
commitID=$(git log -1 --pretty=format:"%h")

printf "\n\n############################################################################\n\n" >> "${OPENdir}log.txt"
printf "CommitID= ${commitID}\n\n" >> "${OPENdir}log.txt"

###################################################################################################
#askif contigs should get splitted
while true; do
  read -r -p "Do you want to split contigs?: " msg
  case $msg in
      [Yy] ) BREAK=Y; break;;
      [Nn] ) BREAK=N; break;;
      * ) echo please type Y or N! ;;
  esac
done
  
if [[ $BREAK == Y ]]; then

  source ${SCRIPTdir}tools
  if [[ ! -s ${TMPdir}asm_vs_dm6.paf ]]; then
    sbatch --wait --qos=rapid --cpus-per-task=5 --wrap="source ${SCRIPTdir}tools; minimap2 -t 10  --secondary=no -x asm5 /groups/brennecke/pipelines/utilities/AnnotationPipeline/dmel/dm6/genome_no-Mito_excl-Y.fa $assemblyFASTA > ${TMPdir}asm_vs_dm6.paf "
  fi

  awk -v OFS="\t" '{ X[$1][$5]+=$4-$3} END{for(i in X) print i,X[i]["+"]+0,X[i]["-"]+0}' ${TMPdir}asm_vs_dm6.paf > ${TMPdir}ctg-orientation.txt

  if [[ ! -s ${OPENdir}ctgs_to_split.txt ]]; then
    seqkit fx2tab --name --only-id --length $assemblyFASTA |  
      awk -v OFS="\t" -v CTGfile=${TMPdir}ctg-orientation.txt '
      BEGIN{
        while((getline LINE < CTGfile) > 0) {
          split(LINE,splitLINE,/ |\t/)
          CTG[splitLINE[1]]="sense="splitLINE[2]" antisense="splitLINE[3]
    }

      }
      {
        print $1,0,$NF,$1,0,"+",CTG[$1]
      }' | tr ' ' '\t' > ${OPENdir}ctgs_to_split.txt

    printf "\n\n\n   please edit  ${OPENdir}ctgs_to_split.txt     to split contigs  \n\n\n "
    exit
  fi
 
  cat ${OPENdir}ctgs_to_split.txt | tr -s ' ' | tr ' ' '\t' | tr -s '\t' | cut -f 1-6 > ${OPENdir}ctgs_to_split.bed 
  bedtools getfasta -fi $assemblyFASTA -tab -name -bed ${OPENdir}ctgs_to_split.bed |  sed 's/-/_/g' | seqkit tab2fx --line-width 0 > ${OPENdir}${VERSION}.ctgSPLIT.fa

  #run assembly eavluation pipeline
  assemblyFASTA=${OPENdir}${VERSION}.ctgSPLIT.fa

else
  seqkit fx2tab  --only-id  $assemblyFASTA | sed 's/-/_/g' | seqkit tab2fx --line-width 0 > ${TMPdir}corrected.fa
  assemblyFASTA=${TMPdir}corrected.fa
fi



###################################################################################################
mkdir -p ${OPENdir}settings/
cat ${SCRIPTdirRAW}*.sh | 
  awk -v RS="#@!@#" '{if (NR==1) print }' > ${OPENdir}settings/SETTINGS_${commitID}.log

TIME="$(date "+%s")"

###################################################################################################

#submit main-run script
LOG=${OPENdir}/LOGs/
rm -rf ${LOG}
mkdir -p ${LOG}
cd $LOG


COMMAND="${SCRIPTdir}Purge-${purgingNAME}"
VARI="DEBUG=${DEBUG},OPENdir=${OPENdir},TMPdir=${TMPdir},SINGULARITYdir=${SINGULARITYdir},COMPUTING=${COMPUTING},SCRIPTdir=${SCRIPTdir},UTILITYdir=${UTILITYdir},LOG=${LOG},purgingNAME=${purgingNAME},ASSEMBLYname=${ASSEMBLYname},FORCE=${FORCE},assemblyFASTA=${assemblyFASTA},rawFASTA=${rawFASTA},lowCUTOFF=${lowCUTOFF},midCUTOFF=${midCUTOFF},highCUTOFF=${highCUTOFF},HISTswitch=${HISTswitch}"  

#module load slurm/17.02.10
echo computing $COMPUTING
if [[ $COMPUTING == C ]]; then
  sbatch $COMMAND ${VARI}
else
  if [[ -z ${SLURM_JOBID+x} ]]; then
    srun --cpus-per-task=10 --mem=20g --qos=short $COMMAND ${VARI}
  else
    $COMMAND ${VARI}
  fi
fi


exit

