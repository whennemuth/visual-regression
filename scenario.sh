#!/bin/bash

# sh docker.sh rerun scenario

debugging && set -x

parseargs() {

}

# Create a backstop json file based on an existing template backstop.json file.
# It will create a copy of the template and modify the default scenario in it to include field
# values specified in the parameter list.
#
# Example:
#   sh scenario.sh \
#     templateJsonFile=/src/backstop.json \
#     outputJsonFile=/src/backstop.custom.json \
#     inputParmsFile=/src/jobs/pending/test1.props
#
addScenario() {
  local defaultJson="$(cat $templateJsonFile)"

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

  # RESUME NEXT: These should come out of a job file. Need to rewrite job file parsing logic such that each line item is of the format:
  # backstop.json.file|field=value
  local label='THIS IS A TEST'
  local url='https://www.w3schools.com/js/js_json_stringify.asp'
  local referenceUrl='https://www.w3schools.com/js/js_json_parse.asp'

  # 1) Create some overriding json to merge into a scenario
  local scenarioOverrides="$(node -pe "$js" \
    "label=$label" \
    "url=$url" \
    "referenceUrl=$referenceUrl" | sed 's/undefined//g'
  )"

  echo "$scenarioOverrides" | jq '.' > $outputJsonFile
  # local backstop="$(echo "$scenarioOverrides" | jq '.')"
  # echo "$backstop"
} 


addScenario