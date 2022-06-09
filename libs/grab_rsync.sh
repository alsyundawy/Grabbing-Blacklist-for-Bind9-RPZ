#!/usr/bin/env bash
# TAGS
#   grab_rsync.sh
#   v6.9
# AUTHOR
#   ngadimin@warnet-ersa.net
# TL;DR
#   don't change unless you know what you're doing
#   see README and LICENSE
# shellcheck source=/dev/null disable=SC2059 disable=SC2154

T=$(date +%s%N)
PATH=/usr/local/bin:/usr/bin:/bin:$PATH
_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

readonly _LIB="${_DIR}"/grab_library
if [[ -e ${_LIB} ]]; then
   if [[ $(stat -L -c "%a" "${_LIB}") != 644 ]]; then chmod 644 "${_LIB}"; fi
   f_trap; f_cnf
else
   printf "[FAIL] %s notFOUND\n" "${_LIB##*/}"; exit 1
fi

printf "\n${_RED}\nstarting ${0##*/} (${_ver}) at ${_CYN}" "[4'th] TASKs:" "${_lct}"
cd "${_DIR}"
SOURCED=false && [[ $0 = "${BASH_SOURCE[0]}" ]] || SOURCED=true
if ! ${SOURCED}; then set -Eeuo pipefail; [[ ! ${UID} -eq 0 ]] || f_xcd 10; fi

if [[ $(stat -L -c "%a" {rpz,db}.*) != 640 ]]; then chmod 640 {rpz,db}.*; fi
ar_DBC=(db.adultaa db.adultab db.adultac db.adultad db.adultae db.adultaf db.adultag \
   db.ipv4 db.malware db.publicite db.redirector db.trust+)
ar_RPZ=(rpz.adultaa rpz.adultab rpz.adultac rpz.adultad rpz.adultae rpz.adultaf rpz.adultag \
   rpz.ipv4 rpz.malware rpz.publicite rpz.redirector rpz.trust+)

printf "\n${_inf} check availability: RPZ-dBase and zone-files in local-host: %-23s" "$(hostname -I)"
# check required: db-files
mapfile -t ar_dbc < <(f_fnd "db.*")
printf -v miss_DBC "%s" "$(echo "${ar_DBC[@]}" "${ar_dbc[@]}" | f_sed)"
if ! [[ ${ar_dbc[*]} == "${ar_DBC[*]}" ]]; then
   printf "\n${_inf} misMATCH file: ${_CYN}" "${miss_DBC}"; f_xcd 19 "${ar_DBC[*]}"
fi

# check required: zone-files
mapfile -t ar_rpz < <(f_fnd "rpz.*")
printf -v miss_RPZ "%s" "$(echo "${ar_RPZ[@]}" "${ar_rpz[@]}" | f_sed)"
if ! [[ ${ar_rpz[*]} == "${ar_RPZ[*]}" ]]; then
   printf "\n${_inf} misMATCH file: ${_CYN}" "${miss_RPZ}"; f_xcd 19 "${ar_RPZ[*]}"
fi
f_ok
f_ssh   # check compatibility: ${HOST} with passwordless ssh
        # check availability: ${ZONE_DIR} in ${HOST}
        # check required debian packages in ${HOST}
# end of check

printf -v _ID "/home/rpz-%s.tar.gz" "$(date +%Y%m%d-%H%M%S)"
printf "${_inf} archiving current RPZ-dBase, save in %s\t" "${HOST}:${_ID}"
_ssh root@"${HOST}" "cd /etc/bind; tar -I pigz -cf ${_ID} zones-rpz"; f_do
printf "${_hnt} use 'unpigz -v ${_ID}' following 'tar -xvf ${_ID/.gz/}' to extract\n"
printf "${_inf} find and remove old RPZ-dBase archive in %s:/home\t" "${HOST}"
_ssh root@"${HOST}" "find /home -regex '^.*\(tar.gz\)$' -mmin +1440 -print0 | xargs -0 -r rm"; f_do
printf "${_inf} syncronizing the latest RPZ-dBase to %s\t" "${HOST}:${ZONE_DIR}"
_snc {rpz,db}.* root@"${HOST}":"${ZONE_DIR}"; f_do

if [[ ${RNDC_RELOAD} =~ [yY][eE][sS] ]]; then
   # required sufficient RAM to execute "rndc reload"
   printf "execute ${_rnr} at BIND9-server:%s\n" "${HOST}"
   _ssh root@"${HOST}" "rndc reload"
else
   # remote-host will reboot [after +@ minute] due to low memory
   printf "${_wn1} host: %s scheduled for reboot at ${_GRN}\n" "${HOST}" "${_fkt}"
   _ssh root@"${HOST}" "shutdown -r 5 --no-wall >> /dev/null 2>&1"
   printf "${_hnt} use ${_shd} at host: %s to abort\n" "${HOST}"
fi

T="$(($(date +%s%N)-T))"; f_time
exit 0
