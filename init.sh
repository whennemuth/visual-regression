#!/bin/bash

srcdir="/src"
defaultJsonFile="$srcdir/backstop.json"
jobdir="$srcdir/jobs"
jobdirIn="$jobdir/pending"
jobdirOut="$jobdir/completed"
jobdirErr="$jobdir/error"
[ ! -d $jobdirIn ] && mkdir -p $jobdirIn
[ ! -d $jobdirOut ] && mkdir -p $jobdirOut
[ ! -d $jobdirErr ] && mkdir -p $jobdirErr
if [ ! -f $defaultJsonFile ] ; then
  echo "CREATING DEFAULT BACKSTOP JSON..."
  backstop init
fi


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
      if [ "$jsonfile" == "$propname" ] ; then
        jsonfile="$defaultJsonFile"
      fi
      if [ -f $jsonfile ] ; then
        local stderr=$(dosingle "$jsonfile" "$propname" 2>&1 1>/dev/null)
        if [ -n "$stderr" ] ; then
          echo "$stderr"
          printf "\n\n$line\n$err" >> temp.err
        fi
      else
        local err="No such file: $jsonfile"
        echo $err
        printf "\n\n$line\n$err" >> temp.err
      fi 
    done < $initfile

    if [ -f temp.err ] ; then
      archive $initfile "$(pwd)/temp.err"
      rm -f temp.err
    else
      archive $initfile
    fi
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

  local json="$(cat $jsonfile)"
  local parsecmd="JSON.parse(process.argv[1]).$propname"
  local prop=$(node -pe "$parsecmd" "$json")
  echo $prop
}

archive() {
  local jobfile="$1"
  local errfile="$2"
  local shortname=$(echo "$jobfile" | rev | cut -d '/' -f1 | rev)
  local outdir="$jobdirOut"
  if [ -n "$errfile" ] ; then
    outdir="$jobdirErr"
    printf "\n----------- ERRORS -----------\n\n" >> $jobfile
    cat $errfile >> $jobfile
  fi
  local archivefile="$outdir/$(date +"%m-%d-%Y-%T")-$shortname"
  mv $jobfile $archivefile
}

# Get the optional debug argument if it was provided
debug="${1,,}"
echo "debug=$debug"
if [ $debug == "debug" ] ; then
  shift
  set -x
fi

# Get the task argument
task="$1"
echo "task=$task"
shift

case "$task" in
  all) dobatches $@ ;;
  batch) dobatch $@ ;;
  single) dosingle $@ ;;
esac