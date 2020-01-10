#!/bin/bash

set -a

# Parse aruments, check/create directory structure, make sure a default backstop json template file exists.
init() {

  appdir="/app"
  srcdir="/src"
  templateJsonFile="$srcdir/backstop.json"
  outputJsonFile="$srcdir/backstop.custom.json"
  jobdir="$srcdir/jobs"
  jobdirIn="$jobdir/pending"
  jobdirOut="$jobdir/completed"
  jobdirErr="$jobdir/error"

  parseargs $@

  if printInit ; then
    echo "task=$task"
    echo "jobfile=$jobfile"
    echo "debug=$([ -z "$debug" ] && echo 'false' || echo 'true')"
    echo "templateJsonFile=$templateJsonFile"
    echo "outputJsonFile=$outputJsonFile"
    echo "jobdirIn=$jobdirIn"
    echo "jobdirOut=$jobdirOut"
    echo "jobdirErr=$jobdirErr"
  fi

  [ ! -d $jobdirIn ] && mkdir -p $jobdirIn
  [ ! -d $jobdirOut ] && mkdir -p $jobdirOut
  [ ! -d $jobdirErr ] && mkdir -p $jobdirErr
  if [ ! -f $templateJsonFile ] ; then
    echo "CREATING TEMPLATE BACKSTOP JSON..."
    backstop init
  fi
}

# Parse the arguments.
#   sh init.sh --f /tmp/jobfile --debug batch
#   sh init.sh --jobfile /tmp/jobfile batch -d
#   sh init.sh --task batch --debug --jobfile /tmp/jobfile
# All 3 of the above are equivalent
parseargs() {
  while (( $# )) ; do
    case "$1" in
      -d|--debug) 
        debug="true"
        ;;
      -t|--task)
        shift
        task="$1"
        ;;
      -f|--jobfile)
        shift
        jobfile="$1"
        ;;
      *)
        local temp="$1"
        ;;
    esac
    shift
  done

  [ -n "$temp" ] && task="$temp"
  if [ -z "$task" ] ; then
    echo "No task provided!"
    exit 1
  fi
  # If a specific job file was indicated, move it to the standard pending directory
  if [ -n "$jobfile" ] ; then
    if [ -f "$jobfile" ] ; then
      echo "Moving $jobfile to $jobdirIn"
      mv $jobfile $jobdirIn
    else
      echo "No such file: $jobfile"
      exit 1
    fi
  fi
}

getNextJobFile() {
  for propfile in $(ls -1 $jobdirIn) ; do
    [ -n "$propfile" ] && echo $jobdirIn/$propfile
    return 0
  done
}

dobatches() {
  while true; do
    if ! dobatch ; then break; fi
  done
}

dobatch() {
  local initfile=${1:-"$(getNextJobFile)"}
  if [ -f "$initfile" ] ; then
    while read -r line || [ -n "$line" ] ; do
      local jsonfile=$(echo -n "$line" | cut -d '=' -f1 | xargs)
      local propname=$(echo -n "$line" | cut -d '=' -f2- | xargs)
      # The cut function will return the first element if there is no second element (non null or empty string.)
      if [ "$jsonfile" == "$propname" ] ; then
        jsonfile="$templateJsonFile"
      fi
      if [ -f $jsonfile ] ; then
        debugging && set +x
        local stderr="$(dosingle $jsonfile $propname 2>&1 1>/dev/null)"
        debugging && set -x
        if [ -n "$stderr" ] ; then
          echo "$stderr"
          printf "\n\n$line\n$stderr" >> temp.err
        else
          echo "$line" >> temp.ok
        fi
      else
        local err="No such file: $jsonfile"
        echo $err
        printf "\n\n$line\n$err" >> temp.err
      fi 
    done < $initfile

    archive $initfile "$(pwd)"
    
    true
  else
    false
  fi
}

dosingle() {
  if [ "$#" -eq 2 ] ; then
    local jsonfile="$1"
    local propname="$2"
    if [ ! -f $jsonfile ] ; then
      echo "No such file: $jsonfile"
      return 1
    fi
  elif [ "$#" -eq 1 ] ; then
    local propname="$1"
    local jsonfile="$templateJsonFile"
  else
    echo "dosingle: invalid number of arguments!"
    return 1
  fi

  # If debugging is turned on, turn if off temporarily because the entire content of the backstop.json
  # file would get printed out to the console, which is far too verbose.
  local json="$(cat $jsonfile)"
  local parsecmd="JSON.parse(process.argv[1]).$propname"
  local prop=$(node -pe "$parsecmd" "$json")
  
  echo $prop
}

archive() {
  local jobfile="$1"
  local tempdir="$2"
  local okfile="$tempdir/temp.ok"
  local errfile="$tempdir/temp.err"
  local outdir="$jobdirOut"
  local shortname=$(echo "$jobfile" | rev | cut -d '/' -f1 | rev)
  local archive="$(date +"%m-%d-%Y-%T.N")-$shortname"

  if [ -f $okfile ] ; then
    mv $okfile "$jobdirOut/$archive"
  fi

  if [ -f $errfile ] ; then
    mv $errfile "$jobdirErr/$archive"
  fi

  rm -f $jobfile
}

debugging() { [ -n "$debug" ] ; }

printInit() { [ "$task" == "init" ] ; }

testScenario() {
  /bin/bash $appdir/scenario.sh $@
}

init $@

case "$task" in
  init) exit ;;
  all) dobatches ;;
  batch) dobatch ;;
  single) dosingle ;;
  scenario) testScenario ;;
  '*') echo "Unrecognized task: \"$task\"" ;;
esac