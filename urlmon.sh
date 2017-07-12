#!/usr/bin/env bash
# Simple URL monitoring script. Needs urlmon.conf file with monitoring details.
# Add to cron and configure email (script uses "mail" to send alerts).
# Logic: curl -m 10 -s "${URL1}" | grep -q "${STRING1}"

usage() {
  echo "Usage: urlmon.sh -c config_file.conf"
  exit 0
}

readconfig() {
  source ${1}
  if [[ -z ${NUMBER_OF_URLS+x} || -z ${EMAIL+x} ]]; then
    echo "ERROR: error in config file: NUMBER_OF_URLS or EMAIL not set!"
    exit 1
  fi
  for (( i = 1; i <= NUMBER_OF_URLS; i++ )); do
    HOSTX="HOST$i"
    URLX="URL$i"
    STRINGX="STRING$i"
    if [[ -z ${!HOSTX+x} || -z ${!URLX+x} || -z ${!STRINGX+x} ]]; then
      echo "ERROR: error in config file: needed variables not set!"
      exit 1
    fi
  done
}

monitor() {
  HOSTX="HOST$1"
  URLX="URL$1"
  STRINGX="STRING$1"
  FAILED=0
  r=$(curl -m 10 -s "${!URLX}")
  if [[ $? -ne 0 ]]; then
    FAILED=1
  fi
  grep -q "${!STRINGX}" <<< "${r}"
  if [[ $? -ne 0 ]]; then
    FAILED=1
  fi

  if [[ $FAILED -ne 0 ]]; then
    if [[ ! -f "/tmp/host${1}_alert" ]]; then
      alert
      touch "/tmp/host${1}_alert"
    fi
  else
    if [[ -f "/tmp/host${1}_alert" ]]; then
      hostok
      rm "/tmp/host${1}_alert"
    fi
  fi
}

alert() {
  echo "Send alert ${!HOSTX}"
  echo -e "Host alert\nHost: ${!HOSTX}\nURL: ${!URLX}\nString: ${!STRINGX}" | mail -s "Alert: Host ${!HOSTX}" ${EMAIL}
}

hostok() {
  echo "Send ok ${!HOSTX}"
  echo -e "Host ok\nHost: ${!HOSTX}\nURL: ${!URLX}\nString: ${!STRINGX}" | mail -s "Ok: Host ${!HOSTX}" ${EMAIL}
}

if [[ "$1" == "-c" ]]; then
  if [[ -n "$2" && -f "$2" ]]; then
      readconfig $2
      for (( i = 1; i <= NUMBER_OF_URLS; i++ )); do
        monitor $i
      done
  else
    echo "ERROR: config file not found"
    exit 1
  fi
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
else
  echo "ERROR: Unknown command, try option -h"
  exit 1
fi
