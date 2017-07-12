# urlmon
Simple shell script to monitor web service availability and send alerts to email.

# User guide
Add the script to crontab and run it for example once in a 5 minutes.

*/5 * * * * root  /root/urlmon.sh -c /root/urlmon.conf > /dev/null 2>&1
