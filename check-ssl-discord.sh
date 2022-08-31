#!/bin/bash

level_notification=30 # Notification remaining days start from here
level_warning=14      # send warning start from notification day, until reach danger level
level_danger=7        # send danger from this days
level_critical=3      # send critical from this days
discord_webhook_url="CHANGE_ME"

generate_json() {
  domain="${1}"
  days_left="${2}"
  color=0
  [ ${days_left} -gt ${level_danger} ] && color=15258703
  [[ ${days_left} -le ${level_danger} && ${days_left} -gt ${level_critical} ]] && color=15895301
  [ ${days_left} -le ${level_critical} ] && color=15861768
  output=$(jq -n \
    --arg dn "$domain" \
    --arg dl "$days_left days left" \
    --arg cl "$color" \
    '{ "username": "DevOps Bot", "embeds": [ { "title": "SSL Certificate Alert", "color": $cl, "fields": [ { "name": "Domain", "value": $dn }, { "name": "Remaining expiry days", "value": $dl } ] } ] }')
  echo "${output}"
}

send_notification() {
  json_data="${1}"
  curl \
    -H "Content-Type: application/json" \
    -d "${json_data}" \
    "${discord_webhook_url}"
}

check_ssl_expiry_days() {
  website="${1}"
  source_website="${website}"
  certificate_file=$(mktemp)
  echo -n | openssl s_client -servername "${website}" -connect "${website}":443 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${certificate_file}
  date=$(openssl x509 -in ${certificate_file} -enddate -noout | sed "s/.*=\(.*\)/\1/")
  date_s=$(date -d "${date}" +%s)
  now_s=$(date -d now +%s)
  date_diff=$(( (date_s - now_s) / 86400 ))
  [ ${2} -eq 2 ] && website="*.$(echo ${website} | sed 's/.*\.\(.*\..*\)/\1/')"
  [ ${2} -eq 3 ] && website="*.$(echo ${website} | sed 's/.*\.\(.*\..*\..*\)/\1/')"
  if [ ${date_diff} -gt ${level_notification} ]; then
    echo "Info: ${website} still has ${date_diff} days remaining"
  fi
  if [[ ${date_diff} -le ${level_notification} && ${date_diff} -gt ${level_warning} || ${date_diff} -le ${level_warning} && ${date_diff} -gt ${level_danger} ]]; then
    echo "Warning: ${website} will expire in ${date_diff} days"
    echo "Sending notification to Discord ..."
    json_data="$(generate_json ${website} ${date_diff})"
    send_notification "${json_data}"
  fi
  if [[ ${date_diff} -le ${level_danger} && ${date_diff} -gt ${level_critical} ]]; then
    echo "Danger: ${website} will expire in ${date_diff} days"
    echo "Sending notification to Discord ..."
    json_data="$(generate_json ${website} ${date_diff})"
    send_notification "${json_data}"
  fi
  if [[ ${date_diff} -le ${level_critical} ]]; then
    echo "Critical: ${website} will expire in ${date_diff} days"
    echo "Sending notification to Discord ..."
    json_data="$(generate_json ${website} ${date_diff})"
    send_notification "${json_data}"
  fi
  rm -f "${certificate_file}"
}

for website in \
  sub.mysite.tld; \
do
  check_ssl_expiry_days ${website} 2
done

for website in \
  sub.mysite.co.tld; \
do \
  check_ssl_expiry_days ${website} 3
done
