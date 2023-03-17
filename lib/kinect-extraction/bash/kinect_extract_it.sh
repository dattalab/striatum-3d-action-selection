#!/bin/bash
#
# From bash, trigger a MATLAB extraction of raw data, can be run on tarballs and directories

#######################################
# Run extraction
# Globals:
#   HMS_CLUSTER
# Arguments:
#   -c|--has-cable (flag): does the data have a cable? (default: False)
#   -i|--input (string): input file/directory to process
#   -b|--batch-processor (string): which MATLAB batch processor to use (default: local)
#   -e|--environment (string): cluster environment (o2 or orchestra)
#   -q|--queue (string): cluster queue/partition to submit to (default: medium)
#   -t|--wall-time (string): job wall time (hh:mm:ss, default: 48:00:00)
#   -n|--workers (int): number of workers (default: 1)
#   -m|--mem-usage (int): RAM usage in MB (default: 40000)
#   -s|--submit (bool): Submit job to bsub/slurm (default: True)
#   -u|--user (string): o2 username (default: $(whoami))
#   --matlab-path (string): path to MATLAB binary (default: None)
#
# Returns:
#   None
#
# Example:
# $ kinect_extract_it.sh -i session_20181225.tar.gz -c
#
#######################################


HAS_CABLE=false
INPUT='somefile'
REMOTE_SERVER=""
BATCH_PROCESSOR='local'
SUBMIT=true
SUBMIT_QUEUE=medium
SUBMIT_WALL_TIME='48:00:00'
SUBMIT_WORKERS=1
SUBMIT_MEM_USAGE=40000
MATLAB_PATH=""
DRY_RUN=false
USER="$(whoami)@hms.harvard.edu"

if [ -z "$HMS_CLUSTER" ]; then
  ENVIRONMENT=local
else
  ENVIRONMENT=$HMS_CLUSTER
fi

# add wall time and relevant orchestra options


if [ $# -eq 0 ]; then
  echo "Usage: $0 -i [input] [options]";
  echo "";
  echo "[input] = Input file/directory to process (*.tar.gz or dir with depth.dat)";
  echo "Arguments:";
  echo "  -c|--has-cable (flag): does the data have a cable? (default: True)"
  echo "  -i|--input (string): input file/directory to process"
  echo "  -b|--batch-processor (string): which MATLAB batch processor to use (default: local)"
  echo "  -e|--environment (string): cluster environment (o2 or orchestra)"
  echo "  -q|--queue (string): cluster queue/partition to submit to (default: medium)"
  echo "  -t|--wall-time (string): job wall time (hh:mm:ss, default: 48:00:00)"
  echo "  -n|--workers (int): number of workers (default: 1)"
  echo "  -m|--mem-usage (int): RAM usage in MB (default: 40000)"
  echo "  -s|--submit (bool): Submit job to bsub/slurm (default: True)"
  echo "  -u|--user (string): o2 username (default: $(whoami))"
  echo "   --matlab-path (string): path to MATLAB binary (default: None)"
  echo "";
  exit 1;
fi


while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -c|--has-cable)
  HAS_CABLE=true
  ;;
  -i|--input)
  INPUT=( $2 )
  shift
  ;;
  -b|--batch-processor)
  BATCH_PROCESSOR=$2
  shift
  ;;
  -r|--remote-server)
  REMOTE_SERVER=$2
  shift
  ;;
  -d|--dry-run)
  DRY_RUN=true
  ;;
  -e|--environment)
  ENVIRONMENT=$2
  shift
  ;;
  -q|--queue)
  SUBMIT_QUEUE=$2
  shift
  ;;
  -t|--wall-time)
  SUBMIT_WALL_TIME=$2
  shift
  ;;
  -n|--workers)
  SUBMIT_WORKERS=$2
  shift
  ;;
  --matlab-path)
  MATLAB_PATH=$2
  shift
  ;;
  -m|--mem-usage)
  SUBMIT_MEM_USAGE=$2
  shift
  ;;
  -u|--user)
  USER=$2
  shift
  ;;
  *)
  # unknown option
  ;;
esac
shift
done

# we can 1) run locally 2) submit bsub locally 3) do either remote
# let MATLAB farm em out?

# make sure scripts is aware of the number of workers along w/ SUBMIT, otherwise wall time will run out fast
# (MATLAB will just hedonistically grab threads)

MATLAB_WORKERS=$((SUBMIT_WORKERS-1))

for file in "${INPUT[@]}"; do
  if [[ -e $file ]]; then

    if [[ $HAS_CABLE = true ]] && [[ $ENVIRONMENT = o2 ]]; then
      CMD="${MATLAB_PATH}matlab -nodisplay -r \\\"kinect_extract_it('$file',1,$MATLAB_WORKERS,'$BATCH_PROCESSOR');exit;\\\""
    elif [[ $HAS_CABLE = true ]]; then
      CMD="${MATLAB_PATH}matlab -nodisplay -r \"kinect_extract_it('$file',1,$MATLAB_WORKERS,'$BATCH_PROCESSOR');exit;\""
    elif [[ $HAS_CABLE = false ]] && [[ $ENVIRONMENT = o2 ]]; then
      CMD="${MATLAB_PATH}matlab -nodisplay -r \\\"kinect_extract_it('$file',0,$MATLAB_WORKERS,'$BATCH_PROCESSOR');exit;\\\""
    else
      CMD="${MATLAB_PATH}matlab -nodisplay -r \"kinect_extract_it('$file',0,$MATLAB_WORKERS,'$BATCH_PROCESSOR');exit;\""
    fi

    if [[ $ENVIRONMENT = orchestra ]]; then
      CMD="bsub -n $SUBMIT_WORKERS -R "rusage[mem=$SUBMIT_MEM_USAGE]" -q $SUBMIT_QUEUE -W $SUBMIT_WALL_TIME $CMD"
    elif [[ $ENVIRONMENT = o2 ]]; then
      CMD="sbatch -n $SUBMIT_WORKERS --mem=${SUBMIT_MEM_USAGE}M -p $SUBMIT_QUEUE -t $SUBMIT_WALL_TIME --wrap \"$CMD\" --mail-user $USER --mail-type=ALL"
    fi

    if [[ ! -z $REMOTE_SERVER ]]; then
      CMD="ssh $REMOTE_SERVER $CMD"
    fi

    echo $CMD

    if [[ $DRY_RUN = false ]]; then
      sleep 2
      eval $CMD
    fi

  fi

done

# do we run in background?
