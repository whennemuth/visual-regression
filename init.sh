#!/bin/bash

set -a

init() {
  appdir="/app"
  srcdir="/src"
  defaultJsonFile="$srcdir/backstop.json"
  jobdir="$srcdir/jobs"
  jobdirIn="$jobdir/pending"
  jobdirOut="$jobdir/completed"
  jobdirErr="$jobdir/error"

  [ testing ] && return 0
  [ ! -d $jobdirIn ] && mkdir -p $jobdirIn
  [ ! -d $jobdirOut ] && mkdir -p $jobdirOut
  [ ! -d $jobdirErr ] && mkdir -p $jobdirErr
  if [ ! -f $defaultJsonFile ] ; then
    echo "CREATING DEFAULT BACKSTOP JSON..."
    backstop init
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
        jsonfile="$defaultJsonFile"
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
    local jsonfile="$defaultJsonFile"
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

# Get the optional debug argument if it was provided
debug="${1,,}"
if [ $debug == "debug" ] ; then
  shift
  set -x
else
  debug=
fi
debugging() {
  [ -n "$debug" ] && true || false
}

# Get the task argument
task="$1"
shift

testing() {
  [ "${task,,}" == "test" ] && true || false
}

testScenario() {
  /bin/bash $appdir/scenario.sh $@
}

init

case "$task" in
  all) dobatches $@ ;;
  batch) dobatch $@ ;;
  single) dosingle $@ ;;
  scenario) testScenario $@ ;;
esac