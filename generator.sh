#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
TITLE='\033[1;34m'
NORMAL='\033[0m'

chk_availability() {
    attempt_counter=0
    max_attempts=10
    SERVER="$1"
    until $(curl --output /dev/null --silent --head --fail "$SERVER"); do
        if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo -e "${RED}Max attempts reached${NORMAL}"
        return 1
        fi

        printf '.'
        attempt_counter=$(($attempt_counter+1))
        sleep 5
    done
    echo -e "${GREEN}Server reachable at: ${NORMAL}$SERVER"

    # Wait additional time to avoid empty responses
    return 0
}

generate() {
    API_URL="$1"
    GROUP_ID="$2"
    ARTIFACT_ID="$3"
    PACKAGE="${ARTIFACT_ID}"
    MODEL_PACKAGE="$4"
    API_PACKAGE="$5"
    LANG="$6"

    echo -e "  ${TITLE}- ${LANG}${NORMAL}"
    mvn clean compile -Dspec_source=$API_URL -Dversion=$VERSION -Dlanguage=$LANG -Dgroup_id=$GROUP_ID -Dartifact_id=$ARTIFACT_ID -Dpackage=$PACKAGE -Dmodel=$MODEL_PACKAGE -Dapi=$API_PACKAGE
    cd target/generated-sources/swagger/ > /dev/null
    zip -r -q ../../../"${ARTIFACT_ID}_${LANG}.zip" .
    cd - > /dev/null

    return 0
}

generate_java() {
    API_URL="$1"
    GROUP_ID="$2"
    ARTIFACT_ID="$3"
    PACKAGE="${GROUP_ID}.${ARTIFACT_ID}"
    LIBRARY="$4"

    echo -e "  ${TITLE}- Java-${LIBRARY}${NORMAL}"
    mvn clean compile install deploy -Dspec_source=$API_URL -Dversion=$VERSION -Dlanguage="java" -Dlibrary=$LIBRARY -Dgroup_id=$GROUP_ID -Dartifact_id=$ARTIFACT_ID -Dmodel="${PACKAGE}.model" -Dapi="${PACKAGE}.api" -Dmaven.javadoc.skip=true
    cd target/generated-sources/swagger/ > /dev/null
    zip -r -q ../../../"${ARTIFACT_ID}_java-${LIBRARY}.zip" .
    cd - > /dev/null

    return 0
}

echo -e "${TITLE}Comptence-Repository${NORMAL}"
API_URL="https://staging.sse.uni-hildesheim.de:9010/api-json"

if chk_availability $API_URL ; then
    VERSION=$(wget "$API_URL" -q -O - | grep -oP "(?<=info\":\{).*?(?=\}\})" | grep -oP "(?<=\"version\":\").*?(?=\",)")
    rm -f "${ARTIFACT_ID}*.zip"
    echo -e "${TITLE}Version:${NORMAL} ${VERSION}"

    # Python
    generate "$API_URL" "net.ssehub.e_learning" "competence_repository_api" "model" "api" "python"

    # TypeScript
    generate "$API_URL" "net.ssehub.e_learning" "competence_repository_api" "model" "api" "typescript-angular"
    generate "$API_URL" "net.ssehub.e_learning" "competence_repository_api" "model" "api" "javascript"
    generate "$API_URL" "net.ssehub.e_learning" "competence_repository_api" "model" "api" "typescript-axios"
    
    # PHP
    generate "$API_URL" "net.ssehub.e_learning" "competence_repository_api" "model" "api" "php"
	
	# Java
	generate_java "$API_URL" "net.ssehub.e_learning" "competence_repository" "resttemplate"
else
    exit 1
fi


echo -e "${TITLE}AI Service${NORMAL}"
API_URL="https://staging.sse.uni-hildesheim.de:9012/swagger.json"

if chk_availability $API_URL ; then
    VERSION=$(wget "$API_URL" -q -O - | grep -oP "(?<=info\": \{).*?(?=\}\})" | grep -oP "(?<=\"version\": \").*?(?=\",)")
    rm -f "${ARTIFACT_ID}*.zip"
    echo -e "${TITLE}Version:${NORMAL} ${VERSION}"

    # TypeScript
    generate "$API_URL" "net.ssehub.e_learning" "competence_ai_api" "model" "api" "typescript-angular"
    generate "$API_URL" "net.ssehub.e_learning" "competence_ai_api" "model" "api" "javascript"
	
	# Java
	generate_java "$API_URL" "net.ssehub.e_learning" "competence_ai" "resttemplate"
else
    exit 1
fi
