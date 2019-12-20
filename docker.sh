
runNode() {
  docker run -ti -p 3000:3000 --rm node:12 bash
}

runBackstop() {
  docker run -ti --rm -v $(pwd)/backstop:/src --entrypoint=bash backstopjs/backstopjs
}

build() {
  docker build -t visual-regression .
}

run() {
  docker run -t --name visreg -v $(pwd)/backstop:/src visual-regression:latest $@
}

rerun() {
  build
  docker rm -f visreg
  run $@
}

task="$1"
shift
case "$task" in
  build) build $@ ;;
  run) run $@ ;;
  rerun) rerun $@ ;; 
  node) runNode $@ ;;
  backstop) runBackstop $@ ;;
esac