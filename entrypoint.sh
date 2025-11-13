#!/usr/bin/env bash

# validate subscription status
API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/subscription"

# Set a timeout for the curl command (3 seconds)
RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" "$API_URL" -o /dev/null) || true
CURL_EXIT_CODE=$?

# Decide based on curl exit code and HTTP status
if [ $CURL_EXIT_CODE -ne 0 ]; then
  echo "Timeout or API not reachable. Continuing to next step."
elif [ "$RESPONSE" = "200" ]; then
  :
elif [ "$RESPONSE" = "403" ]; then
  echo "Subscription is not valid. Reach out to support@stepsecurity.io"
  exit 1
else
  echo "Timeout or API not reachable. Continuing to next step."
fi

failed=0

check_html="${INPUT_CHECK_HTML:-true}"
if [[ "$check_html" =~ ^t.*|^T.*|^y.*|^Y.*|^1.* ]]; then
  check_css="${INPUT_CHECK_CSS:-true}"
  check_css_arg=""
  if [[ "$check_css" =~ ^t.*|^T.*|^y.*|^Y.*|^1.* ]]; then
      check_css_arg="--also-check-css"
  fi
  if ! java -jar /bin/vnu.jar --errors-only --filterpattern "${INPUT_VALIDATOR_IGNORE}" --skip-non-html ${check_css_arg} "${INPUT_DIRECTORY}"; then
    failed=1
  fi
fi

tries="${INPUT_RETRIES:-3}"

while [ "$tries" -ge 1 ]; do
  tries=$((tries-1))
  if RUBYOPT="-W0" ruby /proof-html.rb; then
    break
  fi
  if [ "$tries" -ge 1 ]; then
    sleep 5
  fi
  if [ "$tries" -eq 0 ]; then
    failed=1
  fi
done

exit $failed
