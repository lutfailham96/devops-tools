#!/bin/bash

PROJECT=""
ROUTE_TMPL=""
ROUTE_FILE="/tmp/${PROJECT}.txt"
FILTER=""
RESULT_DIR="/tmp/generated-yaml"
DRY_RUN=false

while getopts n:t:f:d flag; do
  case "${flag}" in
    n)
      PROJECT=${OPTARG}
      ;;
    t)
      ROUTE_TMPL=${OPTARG}
      ;;
    f)
      FILTER=${OPTARG}
      ;;
    d)
      DRY_RUN=true
      ;;
  esac
done

parse_args() {
  if [ -z ${PROJECT} ]; then
    echo "Project cannot be empty"
    exit 1
  fi
  if [ -z ${ROUTE_TMPL} ]; then
    echo "Route template file required"
    exit 1
  fi
}

generate_route() {
  oc project ${PROJECT}
  if [ -z ${FILTER} ]; then
    oc get routes -o json \
        | jq '.items[] | [.metadata.name, .spec.host, .spec.path, .spec.to.name, .spec.port.targetPort]' \
        | sed ':a;N;$!ba;s/\]\n\[//g' \
        | sed '/\]/d' \
        | sed '/\[/d' \
        | sed 's/  //g' \
        | sed ':a;N;$!ba;s/,\n/ /g' \
        | sed 's/"//g' \
        | sed 's/null/\//g' \
        | sed ':a;N;$!ba;s/\n\n/\n/g' > ${ROUTE_FILE}
  else
    oc get routes -o json \
        | jq '.items[] | [.metadata.name, .spec.host, .spec.path, .spec.to.name, .spec.port.targetPort]' \
        | sed ':a;N;$!ba;s/\]\n\[//g' \
        | sed '/\]/d' \
        | sed '/\[/d' \
        | sed 's/  //g' \
        | sed ':a;N;$!ba;s/,\n/ /g' \
        | sed 's/"//g' \
        | sed 's/null/\//g' \
        | sed ':a;N;$!ba;s/\n\n/\n/g' \
        | grep ${FILTER} > ${ROUTE_FILE}
  fi
}

generate_route_yml() {
  rm -rf ${RESULT_DIR}
  mkdir -p ${RESULT_DIR}
  while IFS= read -r route; do
    route_name=$(echo ${route} | awk '{print $1}')
    route_service=$(echo ${route} | awk '{print $4}')
    route_domain=$(echo ${route} | awk '{print $2}')
    route_path=$(echo ${route} | awk '{print $3}')
    route_path_esc=$(echo ${route_path} | sed 's/\//\\\//g')
    route_port=$(echo ${route} | awk '{print $5}')
    route_file="${RESULT_DIR}/${route_name}-env.yaml"
    echo "Generating yaml: ${route_name}"
    cp -afp ${ROUTE_TMPL} ${route_file}
    sed -i "s/ROUTE_NAME/${route_name}/g" ${route_file}
    sed -i "s/ROUTE_NS/${PROJECT}/g" ${route_file}
    sed -i "s/CUSTOM_HOST_SERVICE/${route_service}/g" ${route_file}
    sed -i "s/CUSTOM_HOST_DOMAIN/${route_domain}/g" ${route_file}
    sed -i "s/CUSTOM_HOST_PORT/${route_port}/g" ${route_file}
    sed -i "s/CUSTOM_HOST_PATH/${route_path_esc}/g" ${route_file}
  done < ${1}
}

remove_old_route() {
  while IFS= read -r route; do
    route_name=$(echo ${route} | awk '{print $1}')
    echo oc delete route ${route_name} -n ${PROJECT}
  done < ${1}
}

create_new_route() {
  while IFS= read -r route; do
    route_name=$(echo ${route} | awk '{print $1}')
    route_file="${RESULT_DIR}/${route_name}-env.yaml"
    echo oc apply -f ${route_file} -n ${PROJECT}
  done < ${1}
}

update_route() {
  while IFS= read -r route; do
    route_name=$(echo ${route} | awk '{print $1}')
    route_file="${RESULT_DIR}/${route_name}-env.yaml"
    echo "Updating route: ${route_name} ..."
    oc delete route ${route_name} -n ${PROJECT} \
      && oc apply -f ${route_file} -n ${PROJECT}
  done < ${1}
}

if ${DRY_RUN}; then
  echo "####################"
  echo "#      Dry Run     #"
  echo "####################"
  parse_args \
    && generate_route \
    && generate_route_yml ${ROUTE_FILE}
else
  echo "####################"
  echo "#      Execute     #"
  echo "####################"
  parse_args \
    && generate_route \
    && generate_route_yml ${ROUTE_FILE} \
    && update_route ${ROUTE_FILE}
fi
