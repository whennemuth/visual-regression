
runNode() {
  winpty docker run -ti -p 3000:3000 --rm node:12 bash
}

runBackstop() {
  export MSYS_NO_PATHCONV=1 && \
  winpty docker run --rm -ti -v /$(pwd -W)/backstop/:/tmp busybox /bin/bash
  return 0

  # docker run --rm -v /$(pwd)/backstop:/src backstopjs/backstopjs $1
  export MSYS_NO_PATHCONV=1 
  winpty docker run --rm -v '/C:/whennemuth/workspaces/bu_workspace/bu-visual-regression/backstop/':/src backstopjs/backstopjs init
}

build() {
  docker build -t visual-regression .
}

run() {
  docker run -d --rm --name visreg -p 3000:3000 visual-regression:latest
}

task="$1"
shift
case "$task" in
  build) build $@ ;;
  run) run $@ ;; 
  node) runNode $@ ;;
  backstop) runBackstop $@ ;;
esac