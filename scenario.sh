#!/bin/bash

# sh docker.sh rerun scenario

debugging && set -x

addScenario() {
  local defaultJson="$(cat $defaultJsonFile)"

  local js=$(cat <<EOF
    var scenario = {};
    for(var i=1; i<process.argv.length; i++) {
      var arg = process.argv[i];
      var name = arg.split('=')[0].trim();
      var val = arg.split('=')[1].trim();
      scenario[name] = val;
    }
    var backstop = $defaultJson;
    Object.assign(backstop.scenarios[0], scenario);
    console.log(JSON.stringify(backstop));
EOF
  )

  local label='THIS IS A TEST'
  local url='https://www.w3schools.com/js/js_json_stringify.asp'
  local referenceUrl='https://www.w3schools.com/js/js_json_parse.asp'

  # 1) Create some overriding json to merge into a scenario
  local scenarioOverrides="$(node -pe "$js" \
    "label=$label" \
    "url=$url" \
    "referenceUrl=$referenceUrl" | sed 's/undefined//g'
  )"

  echo "$scenarioOverrides" | jq '.' > $srcdir/backstop.custom.json
  # local backstop="$(echo "$scenarioOverrides" | jq '.')"
  # echo "$backstop"
} 

addScenario