#!/usr/bin/env bash
set -u

# Print stuff
GREEN="\033[32;1m"
RED="\033[31;1m"
BOLD="\033[;1m"
NORMAL="\033[0m"

_BATCH_MODE='no'
_AUTO_GENERATE_THUMBNAIL='no'
_AUTO_UPLOAD_TO_ARCHIVE_ORG='no'
_AUTO_RENDER_VIDEO='no'
_AUTO_PUBLISH_TO_YOUTUBE='no'
_AUTO_UPDATE_WEBSITE='no'
_AUTO_PUBLISH_WEBSITE='no'
_AUTO_SHARE_ON_TWITTER='no'

#    ______                _   _
#   |  ____|              | | (_)
#   | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
#   |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
#   | |  | |_| | | | | (__| |_| | (_) | | | \__ \
#   |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#
#

function .usage() {
  echo "Usage: $0 [OPTIONS] EPISODE.ENV"
  echo ""
  echo "OPTIONS:"
  echo "  -b  Batch mode - no questions"
  echo "  -t  Auto generate thumbnail"
  echo "  -a  Auto upload to archive.org"
  echo "  -v  Auto render video"
  echo "  -y  Auto publish on youtube"
  echo "  -m  Auto write website markdown files"
  echo "  -p  Auto publish website (git push). Only works with -m"
  echo "  -w  Auto publish to twitter"
  echo ""
  echo "note: options ordered by script sequece "
}

function .parse_input_flags() {
  while getopts ":btavympw" opt; do
    case ${opt} in
    b)
      _BATCH_MODE='yes'
      shift $((OPTIND - 1))
      ;;
    t)
      _AUTO_GENERATE_THUMBNAIL='yes'
      shift $((OPTIND - 1))
      ;;
    a)
      _AUTO_UPLOAD_TO_ARCHIVE_ORG='yes'
      shift $((OPTIND - 1))
      ;;
    v)
      _AUTO_RENDER_VIDEO='yes'
      shift $((OPTIND - 1))
      ;;
    y)
      _AUTO_PUBLISH_TO_YOUTUBE='yes'
      shift $((OPTIND - 1))
      ;;
    m)
      _AUTO_UPDATE_WEBSITE='yes'
      shift $((OPTIND - 1))
      ;;
    p)
      _AUTO_PUBLISH_WEBSITE='yes'
      shift $((OPTIND - 1))
      ;;
    w)
      _AUTO_SHARE_ON_TWITTER='yes'
      shift $((OPTIND - 1))
      ;;
    \?)
      echo "invalid option ${opt}"
      .usage
      exit 1
      ;;
    esac
  done

  if [[ $# -ne 1 ]]; then
    echo "Invalid number of arguments $#"
    .usage
    exit 1
  fi
  EPISODE_ENV_FILE=$1
}

function .print_variables() {
  echo "_BATCH_MODE = $_BATCH_MODE"
  echo "_AUTO_GENERATE_THUMBNAIL = $_AUTO_GENERATE_THUMBNAIL"
  echo "_AUTO_UPLOAD_TO_ARCHIVE_ORG = $_AUTO_UPLOAD_TO_ARCHIVE_ORG"
  echo "_AUTO_RENDER_VIDEO = $_AUTO_RENDER_VIDEO"
  echo "_AUTO_PUBLISH_TO_YOUTUBE = $_AUTO_PUBLISH_TO_YOUTUBE"
  echo "_AUTO_UPDATE_WEBSITE = $_AUTO_UPDATE_WEBSITE"
  echo "_AUTO_PUBLISH_WEBSITE = $_AUTO_PUBLISH_WEBSITE"
  echo "_AUTO_SHARE_ON_TWITTER = $_AUTO_SHARE_ON_TWITTER"
}

function .load_variables() {
  # Load all variables
  EPISODE_ENV_FILE="$1"
  if [[ ! -f "${EPISODE_ENV_FILE}" ]]; then
    echo "'${EPISODE_ENV_FILE}' file does not exist. Copy from episode-s01e01.example.env"
    echo "Exiting..."
    exit 3
  fi
  source "${EPISODE_ENV_FILE}"
}

function .print_and_check_info() {
  echo -e "\n${BOLD}*************** Information *******************${NORMAL}"
  echo -e "Episode: Season ${GREEN}${SEASON_NUMBER}${NORMAL} Episode ${GREEN}${EPISODE_NUMBER}${NORMAL} (${GREEN}${_sxxexx}${NORMAL})"
  echo -e "Audio File: ${GREEN}${AUDIO_PATH}${NORMAL}"
  echo -e "Title: ${GREEN}${TITLE}${NORMAL}"
  echo -e "Short Description: ${GREEN}${DESCRIPTION}${NORMAL}"
  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    read -p "Continue? [y/N] " choice
    if [[ "$choice" =~ [yY] ]]; then
      echo ""
    else
      echo "Exiting"
      exit 0
    fi
  fi
}

function .check_pre_requisites() {
  # check commands
  if ! command -v "${IA_BIN}" >/dev/null 2>&1; then
    echo "ia (internet archive command line) is not present or executable."
    echo "Read README.md"
    exit 2
  fi

  if ! command -v "youtube-upload" >/dev/null 2>&1; then
    echo "youtube-upload is not present."
    echo "Read README.md"
    exit 2
  fi

  if ! command -v "jq" >/dev/null 2>&1; then
    echo "jq is not present."
    echo "Read README.md"
    exit 2
  fi

  if ! command -v "python" >/dev/null 2>&1; then
    echo "python is not present."
    exit 2
  fi

  if ! command -v "display" >/dev/null 2>&1; then
    echo "display is not present."
    echo "find out how to install it <shrug>"
    exit 2
  fi

  # check paths and directories
  if [[ ! -f "${AUDIO_PATH}" ]]; then
    echo "AUDIO_PATH ${AUDIO_PATH} does not exist"
    exit 3
  fi
  if [[ ! -f "${BASE_IMAGE_PATH}" ]]; then
    echo "BASE_IMAGE_PATH ${BASE_IMAGE_PATH} does not exist"
    exit 3
  fi
  if [[ ! -f "${THUMBNAIL_PYTHON_SCRIPT}" ]]; then
    echo "THUMBNAIL_PYTHON_SCRIPT ${THUMBNAIL_PYTHON_SCRIPT} does not exist"
    exit 3
  fi
  if [[ ! -f "${GOOGLE_CREDENTIALS_PATH}" ]]; then
    echo "GOOGLE_CREDENTIALS_PATH ${GOOGLE_CREDENTIALS_PATH} does not exist"
    exit 3
  fi
  if [[ ! -d "$(dirname ${VIDEO_PATH})" ]]; then
    echo "VIDEO_PATH $(dirname ${VIDEO_PATH}) directory does not exist"
    exit 3
  fi
  if [[ ! -d "$(dirname "${WEBSITE_GIT_PATH}")" ]]; then
    echo "WEBSITE_GIT_PATH $(dirname "${WEBSITE_GIT_PATH}") directory does not exist"
    exit 3
  fi
  if [[ ! -d "$(dirname "${WEBSITE_GIT_PATH}${POST_RELATIVE_PATH}")" ]]; then
    echo "POST_RELATIVE_PATH $(dirname "${WEBSITE_GIT_PATH}${POST_RELATIVE_PATH}") directory does not exist"
    exit 3
  fi
  if [[ ! -d "$(dirname "${WEBSITE_GIT_PATH}${POST_IMAGE_RELATIVE_PATH}")" ]]; then
    echo "POST_IMAGE_RELATIVE_PATH $(dirname "${WEBSITE_GIT_PATH}${POST_IMAGE_RELATIVE_PATH}") directory does not exist"
    exit 3
  fi
  if [[ ! -d "$(dirname ${THUMBNAIL_PATH})" ]]; then
    echo "THUMBNAIL_PATH $(dirname ${THUMBNAIL_PATH}) directory does not exist"
    exit 3
  fi

}

function .generate_thumbnail() {
  echo -e "\n${BOLD}********** Generating Thumbnail (preview 5s) *************${NORMAL}"
  echo -e "Text: ${GREEN}${TITLE}${NORMAL}"
  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' && (-f "${THUMBNAIL_PATH}" || -f "${SMALL_THUMBNAIL_PATH}") ]]; then
    read -p "${THUMBNAIL_PATH} [OR] ${SMALL_THUMBNAIL_PATH} already exists. Override? [y/N] " choice
    if [[ "$choice" =~ [yY] ]]; then
      echo "Overriding file ${THUMBNAIL_PATH}/${SMALL_THUMBNAIL_PATH}"
    else
      return
    fi
  fi

  if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_GENERATE_THUMBNAIL} == 'yes' ]]; then
    python "${THUMBNAIL_PYTHON_SCRIPT}" "${BASE_IMAGE_PATH}" "${THUMBNAIL_PATH}" "${SMALL_THUMBNAIL_PATH}" "#${EPISODE_NUMBER} ${TITLE}"
  fi

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    display "${SMALL_THUMBNAIL_PATH}" &

    local _PID=$!
    sleep 5 && kill $_PID

    read -p "Thumbnails generated. Continue? [Y/n] " choice
    if [[ "$choice" =~ [nN] ]]; then
      echo "Stopping..."
      exit 0
    fi
  fi

}

function .upload_audio_to_archive_org() {
  echo -e "\n${BOLD}********** Publish to the Internet Archive (archive.org) *************${NORMAL}"
  echo -e "Identifier: ${GREEN}${ARCHIVE_ORG_IDENTIFIER}${NORMAL}"
  echo -e "Audio file: ${GREEN}${AUDIO_PATH}${NORMAL}"
  echo -e "Thumbnail file: ${GREEN}${THUMBNAIL_PATH}${NORMAL}"
  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    read -p "Publish to archive.org? [Y/n] " choice
    if [[ "$choice" =~ [nN] ]]; then
      echo "Skip archive.org upload..."
      return
    fi
  fi

  if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_UPLOAD_TO_ARCHIVE_ORG} == 'yes' ]]; then
    echo "Uploading files to archive.org..."

    "${IA_BIN}" upload "${ARCHIVE_ORG_IDENTIFIER}" \
      "${AUDIO_PATH}" \
      "${THUMBNAIL_PATH}" \
      "${SMALL_THUMBNAIL_PATH}" \
      --metadata="mediatype:audio" \
      --metadata="language:por" \
      --retries 5

    if [[ $? -eq 0 ]]; then
      echo -e "OK - Episode published to ${GREEN}${ARCHIVE_ORG_DETAILS_URL}${NORMAL}"
    else
      echo "Upload failed? check login: ${IA_BIN} configure"
    fi
  fi
}

function .render_video() {
  echo -e "\n${BOLD}********** Render video (ffmpeg) *************${NORMAL}"

  echo -e "Destination file: ${GREEN}${VIDEO_PATH}${NORMAL}"
  echo -e "Audio file: ${GREEN}${AUDIO_PATH}${NORMAL}"
  echo -e "Thumbnail file: ${GREEN}${THUMBNAIL_PATH}${NORMAL}"

  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    if [[ -f "$VIDEO_PATH" ]]; then
      read -p "${VIDEO_PATH} already exists. Override? [y/N] " choice
      if [[ "$choice" =~ [yY] ]]; then
        echo "Overriding file ${VIDEO_PATH}"
      else
        return
      fi
    else
      read -p "Render video now? [Y/n] " choice
      if [[ "$choice" =~ [nN] ]]; then
        echo "Skip render video..."
        return
      fi
    fi
  fi

  if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_RENDER_VIDEO} == 'yes' ]]; then
    ffmpeg -loop 1 -i "${SMALL_THUMBNAIL_PATH}" -i "${AUDIO_PATH}" -shortest -acodec copy "${VIDEO_PATH}" -y
  fi
}

function .upload_to_youtube() {
  echo -e "\n${BOLD}*************** Publish video to youtube *******************${NORMAL}"
  echo -e "Publish date: ${GREEN}${PUBLISHED_AT}${NORMAL}"
  echo -e "Video file: ${GREEN}${VIDEO_PATH}${NORMAL}"
  echo -e "Title file: ${GREEN}${YOUTUBE_TITLE}${NORMAL}"
  echo -e "Description: ${GREEN}\n${BODY_MD_TEXT}${FOOTER_MD_TEXT}${NORMAL}"
  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    read -p "Publish to Youtube? [Y/n] " choice
    if [[ "$choice" =~ [nN] ]]; then
      echo "Skip youtube upload..."
      return
    fi
  fi

  if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_PUBLISH_TO_YOUTUBE} == 'yes' ]]; then
    RESULT=$(youtube-upload \
      --title="${YOUTUBE_TITLE}" \
      --description="${BODY_MD_TEXT}$(echo -e "\n\n")${FOOTER_MD_TEXT}" \
      --tags="${TAGS}" \
      --client-secrets="${GOOGLE_CREDENTIALS_PATH}" \
      --credentials-file="yt_credentials.json" \
      --privacy="${YOUTUBE_PRIVACY_STATUS}" \
      --publish-at="${PUBLISHED_AT}T22:45:00.0Z" \
      ${VIDEO_PATH})

    if [[ $? -eq 0 ]]; then
      echo -e "OK - Episode published to https://youtube.com/watch?v=$(echo ${RESULT} | jq -r .id)"
    else
      echo -e "${RED}Upload failed${NORMAL}"
    fi
  fi
}

function .create_markdown_file() {
  local _markdown_post_file="${WEBSITE_GIT_PATH}${POST_RELATIVE_PATH}"
  local _image_file="${WEBSITE_GIT_PATH}${POST_IMAGE_RELATIVE_PATH}"

  echo -e "\n${BOLD}********** Create publishing Post (website/rss) *************${NORMAL}"
  echo -e "Destination Markdown File: ${GREEN}${_markdown_post_file}${NORMAL}"
  echo -e "Image File: ${GREEN}${_image_file}${NORMAL}"
  echo -e "Content: ${GREEN}\n${BODY_MD_TEXT}${NORMAL}"
  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    if [[ -f "${_markdown_post_file}" ]]; then
      read -p "${_markdown_post_file} already exists. Override? [y/N] " choice
      if [[ "$choice" =~ [yY] ]]; then
        echo "Overriding file ${_markdown_post_file}"
      else
        echo "Skip post creation..."
        return
      fi
    else
      read -p "Create post (locally)? [Y/n] " choice
      if [[ "$choice" =~ [nN] ]]; then
        echo "Skip post creation..."
        return
      fi
    fi
  fi

  if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_UPDATE_WEBSITE} == 'yes' ]]; then
    echo "${MARKDOWN_TEMPLATE}" >"${_markdown_post_file}"
    cp "${THUMBNAIL_PATH}" "${_image_file}"
  fi
}

function .commit_and_push_website() {
  (
    echo -e "\n${BOLD}********** Publishing Post with git (website/rss) *************${NORMAL}"

    cd "${WEBSITE_GIT_PATH}"
    if [[ "${_BATCH_MODE}" == 'no' ]]; then
      while ! git diff --cached --exit-code &>/dev/null; do
        echo -e "${RED}There are staged changes not yet committed."
        echo -e "You need to fix this manually.${NORMAL}"
        echo -e "(you may open another shell and commit changes)"

        read -p "Try again? [Y/n] " choice
        if [[ "$choice" =~ [nN] ]]; then
          echo "Skip publishing website..."
          return
        fi
      done
    fi

    if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_PUBLISH_WEBSITE} == 'yes' ]]; then
      LOCAL_BRANCH=$(git name-rev --name-only HEAD)
      TRACKING_REMOTE=$(git config "branch.${LOCAL_BRANCH}.remote")
      REMOTE_URL=$(git config "remote.${TRACKING_REMOTE}.url")

      echo -e "Executing git pull..."
      git pull

      echo -e ""
      echo -e "File to commit: ${GREEN}$(basename ${POST_RELATIVE_PATH}) + $(basename ${POST_IMAGE_RELATIVE_PATH})${NORMAL}"
      echo -e "push to ${GREEN}${REMOTE_URL}${NORMAL}"
      echo -e "remote/branch: ${GREEN}${TRACKING_REMOTE}/${LOCAL_BRANCH}${NORMAL}"

      if [[ ${_AUTO_PUBLISH_WEBSITE} == 'no' ]]; then
        read -p "Commit and push? [Y/n] " choice
        if [[ "$choice" =~ [nN] ]]; then
          echo "Skip publishing website..."
          return
        fi
      fi

      git add "${POST_RELATIVE_PATH}"
      git add "${POST_IMAGE_RELATIVE_PATH}"
      git commit -m "Publishing $(basename "${POST_RELATIVE_PATH}") + $(basename "${POST_IMAGE_RELATIVE_PATH}")"
      git push

      [[ $? -ne 0 ]] && echo -e "${RED}Error pushing repository. Changes not pushed${NORMAL}"
    fi
  )

}

function .share_on_twitter() {
  echo -e "\n${BOLD}********** Share on Twitter *************${NORMAL}"
  echo -e "Content: ${GREEN}${SOCIAL_SHARE_MESSAGE}${NORMAL}"
  echo -e ""

  if [[ "${_BATCH_MODE}" == 'no' ]]; then
    read -p "Tweet? [Y/n] " choice
    if [[ "$choice" =~ [nN] ]]; then
      echo "Skip twitter share..."
      return
    fi
  fi

  if [[ "${_BATCH_MODE}" == 'no' || ${_AUTO_SHARE_ON_TWITTER} == 'yes' ]]; then
    echo "${SOCIAL_SHARE_MESSAGE}" | perl oysttyer/oysttyer.pl -keyf="$(pwd)/.oysttyerkey" -rc="$(pwd)/.oysttyerrc"
  fi
}

#    __  __       _
#   |  \/  |     (_)
#   | \  / | __ _ _ _ __
#   | |\/| |/ _` | | '_ \
#   | |  | | (_| | | | | |
#   |_|  |_|\__,_|_|_| |_|
#
#
function .main() {
  .parse_input_flags "$@"
  .load_variables "${EPISODE_ENV_FILE}"
  [[ "$_BATCH_MODE" == 'yes' ]] && .print_variables
  .check_pre_requisites
  .print_and_check_info

  .generate_thumbnail
  .upload_audio_to_archive_org

  .render_video
  .upload_to_youtube

  .create_markdown_file
  .commit_and_push_website

  .share_on_twitter
}

.main "$@"
