#!/bin/bash
set -e

# Download reloader stable chart
HELM_CHART_NAME="reloader"
HELM_CHART_REPO="stakater/reloader"
HELM_CHART_VERSION="1.0.40"
ISCP_NAME="d-reloader"
ISCP_VERSION="1.0.0"

function getChartVersion()
{
  echo "--- getChartVersion"
  if [ -d "${HELM_CHART_NAME}" ];
  then
    echo "There is a chart on target folder $(pwd)/${HELM_CHART_NAME}/"
    echo "Current chart is:"
    grep ^name\: ${HELM_CHART_NAME}/Chart.yaml
    grep ^version\: ${HELM_CHART_NAME}/Chart.yaml
  else
    echo "No ${HELM_CHART_NAME} chart found on local folder."
    echo "Downloading ..."
    helm fetch --untar --untardir . ${HELM_CHART_REPO} --version ${HELM_CHART_VERSION}
    echo "Chart on target folder ${pwd}/${HELM_CHART_NAME}/"
    grep ^name\: ${HELM_CHART_NAME}/Chart.yaml
    grep ^version\: ${HELM_CHART_NAME}/Chart.yaml
  fi
}

function getChartValues()
{
  echo "--- getChartValues"
  if [ -f "helm-values-${HELM_CHART_NAME}.yaml" ];
  then
    echo "helm-values-${HELM_CHART_NAME}.yaml is available"
  else
    echo "helm-values-${HELM_CHART_NAME}.yaml isn't available.";
    echo "Using ${HELM_CHART_NAME}/values.yaml as first candidate.";
    cp ${HELM_CHART_NAME}/values.yaml helm-values-${HELM_CHART_NAME}.yaml;
  fi
}

function generatek8stmpResources()
{
  echo "--- generatek8stmpResources"
  echo "Using ./helm-values.yaml to generate temporary files"
  #rm -rf tmp/helm-template-result-${HELM_CHART_NAME}
  mkdir -p tmp/helm-template-result-${HELM_CHART_NAME}
  helm template ${ISCP_NAME} ./${HELM_CHART_NAME} \
  	--output-dir tmp/helm-template-result-${HELM_CHART_NAME} \
  	--values ./helm-values-${HELM_CHART_NAME}.yaml \
  	--namespace k8sNamespace > /dev/null
  echo "Type tree tmp/helm-template-result to check all generated resources."
}

function flattenFilesPath()
{
  echo "--- flattenFilesPath"
  rm -rf tmp/k8s
  mkdir -p tmp/k8s
  for INFILE in $(find tmp/helm-template-result-${HELM_CHART_NAME} -name "*yaml")
  do
    OUTTMP=${INFILE/tmp\/helm-template-result-${HELM_CHART_NAME}\//}
    OUTTMP=${OUTTMP/templates\//}
    OUTFILE=${OUTTMP//\//-}
    cp $INFILE tmp/k8s/$OUTFILE
    # echo "Generated k8s resource: tmp/k8s/${OUTFILE}"
  done
  echo "Type ls tmp/k8s to check all generated resources."
}

function sanitizeTemplateVariables()
{
  echo "--- Adding templating to cluster related values"
  echo "--- this is always done on the tmp folder"

  sed s/'k8sNamespace'/'{{ k8sNamespace }}'/g -i tmp/k8s/*
  # sed s/'imageInstanceLocation'/'{{ imageInstanceLocation }}'/g -i tmp/k8s/*
  # sed s/'imageInstanceName'/'{{ imageInstanceName }}'/g -i tmp/k8s/*
  # sed s/'1.3.1-imageInstanceTag'/'{{ imageInstanceTag }}'/g -i tmp/k8s/*
  # sed s/'name: imagePullSecret'/'name: {{ imagePullSecret }}'/g -i tmp/k8s/*



}

function filesToVersionControl()
{
  echo "--- fileToVersionControl"


  mkdir -p ../../k8s/d-reloader

  cp -v tmp/k8s/*.yaml         ../../k8s/d-reloader/.
  tree
  rm -rf tmp
  rm -rf ${HELM_CHART_NAME}

}

# Force script execution context to this folder with out navigating or changing directory
#
# This way you may run the script from anypath.
#
# dirname -> get script folder
# pushd -> change script folder context execution
# popd -> back to original folder

BASEDIR=$(dirname "$0")
pushd $BASEDIR

getChartVersion

getChartValues

generatek8stmpResources

flattenFilesPath

sanitizeTemplateVariables

filesToVersionControl

popd