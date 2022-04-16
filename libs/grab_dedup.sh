#!/usr/bin/env bash
# TAGS
#   grab_dedup.sh
#   v6.2
# AUTHOR
#   ngadimin@warnet-ersa.net
# see README and LICENSE

umask 027
set -Eeu
PATH=/bin:/usr/bin:/usr/local/bin:$PATH
_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export LC_NUMERIC=id_ID.UTF-8
startTime=$(date +%s)
start=$(date "+DATE: %Y-%m-%d TIME: %H:%M:%S")
trap f_trap EXIT INT TERM   # cleanUP on exit, interrupt & terminate
# shellcheck source=/dev/null
source "$_DIR"/grab_lib.sh

cd "$_DIR"; [ ! "$UID" -eq 0 ] || f_xcd 10
mapfile -t ar_txt < <(find . -maxdepth 1 -type f -name "txt.*" | sed -e "s/\.\///" | sort)
if [ "${#ar_txt[@]}" -eq 6 ]; then
   # declare tmp files as array
   ar_cat=(); ar_dmn=(); ar_tmp=()
   for B in {0..5}; do
      ar_cat+=("${ar_txt[B]/txt./}")
      ar_dmn+=(dmn."${ar_txt[B]/txt./}")
      ar_tmp+=(tmr."${ar_txt[B]/txt./}")
   done

   printf "\n\x1b[91m[1'st] TASKs:\x1b[0m\nStarting %s ... %s\n" "$(basename "$0")" "$start"
   printf "[INFO] Eliminating duplicate entries between domain lists\n"
   printf "[INFO] FOUND %s domain lists: \x1b[93m%s\x1b[0m\n" "${#ar_txt[@]}" "${ar_cat[*]}"
   # based on ${ar_dom[1,4]}
   printf "\neliminating duplicate entries based on \x1b[93m%s\x1b[0m\t\tdo nothing" "${ar_cat[1]^^}"
   printf "\neliminating duplicate entries based on \x1b[93m%s\x1b[0m\tdo nothing\n" "${ar_cat[4]^^}"

   f_dupl "${ar_cat[0]}"   # based on ${ar_cat[0]}
   for C in {2..5}; do
      f_ddup "$C" "${ar_cat[C]}" "${ar_txt[C]}" "${ar_txt[0]}" "${ar_tmp[C]}"
      awk 'FILENAME == ARGV[1] && FNR==NR{a[$1];next} !($1 in a)' "${ar_tmp[C]}" "${ar_txt[C]}" \
         | _sort > "${ar_dmn[C]}"
      cp "${ar_dmn[C]}" "${ar_txt[C]}"
      f_do
   done

   f_dupl "${ar_cat[3]}"   # based on ${ar_cat[3]}
   for D in 2 4 5; do
      f_ddup "$D" "${ar_cat[D]}" "${ar_txt[D]}" "${ar_txt[3]}" "${ar_tmp[D]}"
      awk 'FILENAME == ARGV[1] && FNR==NR{a[$1];next} !($1 in a)' "${ar_tmp[D]}" "${ar_txt[D]}" \
         | _sort > "${ar_dmn[D]}"
      cp "${ar_dmn[D]}" "${ar_txt[D]}"
      f_do
   done

   f_dupl "${ar_cat[5]}"   # based on ${ar_cat[5]}
   for E in 3 4; do
      f_ddup "$E" "${ar_cat[E]}" "${ar_txt[E]}" "${ar_txt[5]}" "${ar_tmp[E]}"
      awk 'FILENAME == ARGV[1] && FNR==NR{a[$1];next} !($1 in a)' "${ar_tmp[E]}" "${ar_txt[E]}" \
         | _sort > "${ar_dmn[E]}"
      cp "${ar_dmn[E]}" "${ar_txt[E]}"
      f_do
   done

   f_dupl "${ar_cat[2]}"   # based on ${ar_cat[2]}
   printf "%11s = deduplicating %s entries\t\t" "STEP 0.5" "${ar_cat[4]}"
   _sort "${ar_txt[4]}" "${ar_txt[2]}" | uniq -d | _sort -u > "${ar_tmp[4]}"
   awk 'FILENAME == ARGV[1] && FNR==NR{a[$1];next} !($1 in a)' "${ar_tmp[4]}" "${ar_txt[4]}" \
      | _sort > "${ar_dmn[4]}"
   cp "${ar_dmn[4]}" "${ar_txt[4]}"
   f_do

else
   printf "\n\x1b[91m[FAILED]\x1b[0m due to: just FOUND %s of 6 domain list:\n\t%s\n" \
      "${#ar_txt[@]}" "${ar_txt[*]}"
   exit 1
fi

# display result
endTime=$(date +%s); DIF=$((endTime - startTime)); unset -v ar_txt
mapfile -t ar_txt < <(find . -maxdepth 1 -type f -name "txt.*" | sed -e "s/\.\///" | sort)
printf "\ndeduplicating domain lists (\x1b[93m%s CATEGORIES\x1b[0m) in summary:\n" "${#ar_txt[@]}"
for P in {0..5}; do
   printf -v dpl "%'d" "$(wc -l < "${ar_txt[P]}")"
   printf "%12s: %9s entries\n" "${ar_cat[P]}" "$dpl"
done
printf -v dpl_ttl "%'d" "$(wc -l "${ar_txt[@]}" | grep "total" | cut -d" " -f3)"
printf "%12s: %9s entries\n" "TOTAL" "$dpl_ttl"
printf "[INFO] Completed \x1b[93mIN %s:%s\x1b[0m\n" "$((DIF/60))" "$((DIF%60))s"
exit 0
