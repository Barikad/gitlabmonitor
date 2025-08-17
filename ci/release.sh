#!/bin/bash

# ==============================================================================
# GitLab CI/CD Release Script
# ==============================================================================
# This script is called by .gitlab-ci.yml to handle packaging and release.

set -e # Exit immediately if a command exits with a non-zero status.

# GitLab CI variables are available as environment variables
VERSION=${CI_COMMIT_TAG:?"CI_COMMIT_TAG variable is not set. This script should only be run from a tagged pipeline."}
PACKAGE_NAME="gitlab-monitor-${VERSION}.tar.gz"
PACKAGE_PATH="${CI_PROJECT_DIR}/${PACKAGE_NAME}"
GENERIC_PACKAGE_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/gitlab-monitor"
RELEASE_NOTES_FILE="${CI_PROJECT_DIR}/release_notes_${VERSION}.md"

# --- Function to build the package ---
task_build() {
    echo "--- Building package for version ${VERSION} ---"
    
    echo "Current directory: $(pwd)"
    ls -la
    echo "CI_PROJECT_DIR is: ${CI_PROJECT_DIR}"
    ls -la "${CI_PROJECT_DIR}"

    tar -C "${CI_PROJECT_DIR}" -czvf "${PACKAGE_PATH}" \
        gitlab-public-repo-monitor.sh \
        config.conf.example \
        README.md \
        LICENSE \
        template.fr.md \
        template.en.md
        
    echo "Package ${PACKAGE_NAME} created successfully at ${PACKAGE_PATH}."
}

# --- Function to publish the release ---
task_release() {
    echo "--- Releasing version ${VERSION} ---"

    # 1. Upload packages
    echo "Uploading packages to Generic Package Registry..."
    curl --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file "${PACKAGE_PATH}" "${GENERIC_PACKAGE_URL}/${VERSION}/${PACKAGE_NAME}"
    curl --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file "${PACKAGE_PATH}" "${GENERIC_PACKAGE_URL}/latest/${PACKAGE_NAME}"

    # 2. Prepare Release Notes
    echo "Preparing release notes..."
    if [ ! -f "${RELEASE_NOTES_FILE}" ]; then
        echo "Warning: ${RELEASE_NOTES_FILE} not found. Using a generic description."
        DESCRIPTION_CONTENT="Release for version ${VERSION}."
    else
        DESCRIPTION_CONTENT=$(sed -e 's/\/\\/g' -e 's/"/\"/g' -e 's///g' -e 's/	/\t/g' -e 's/
/\n/g' < "${RELEASE_NOTES_FILE}")
    fi

    # 3. Create JSON payload
    echo "Preparing JSON payload..."
    cat << EOF > payload.json
    {
      "name": "Release ${VERSION}",
      "tag_name": "${VERSION}",
      "description": "${DESCRIPTION_CONTENT}",
      "assets": {
        "links": [{
          "name": "Package (${PACKAGE_NAME})",
          "url": "${CI_PROJECT_URL}/-/packages/generic/gitlab-monitor/${VERSION}/${PACKAGE_NAME}"
        }]
      }
    }
EOF

    # 4. Create GitLab Release
    echo "Creating GitLab Release..."
    curl --fail --request POST \
         --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
         --header "Content-Type: application/json" \
         --data "@payload.json" \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/releases"

    echo "Release created successfully."
}

# --- Main entrypoint ---
case "$1" in
    build)
        task_build
        ;;;;
    release)
        task_release
        ;;;;
    *)
        echo "Error: Invalid task '$1'. Use 'build' or 'release'."
        exit 1
        ;;
esac
