#!/usr/bin/env bash
# TAGS
#   grab_lib.sh
#   v6.2
# AUTHOR
#   ngadimin@warnet-ersa.net
# TL;DR
#   see README and LICENSE

shopt -s expand_aliases
alias _sort="LC_ALL=C sort --buffer-size=80% --parallel=3"
alias _sed="LC_ALL=C sed"
alias _grep="LC_ALL=C grep"
alias _ssh="ssh -q -T -c aes128-ctr -o Compression=no -x"
alias _rsync="rsync -rtxX -e 'ssh -q -T -c aes128-ctr -o Compression=no -x'"
_foo=$(basename "$0"); _fuu=$(basename "${BASH_SOURCE[0]}")
HOST=rpz.warnet-ersa.net      # CHANGE to fqdn or ip-address of your BIND9-server

f_tmp() {   # remove temporary files/directories, array & function defined during the execution of the script
   find . -regextype posix-extended -regex "^.*(dmn|tmr|tm[pq]|txt.adulta).*|.*gz$" -print0 | xargs -0 -r rm
   find . -type d ! -name "." -print0 | xargs -0 -r rm -rf
   find /tmp -maxdepth 1 -type f -name "txt.adult" -print0 | xargs -r0 mv -t .
   }
f_uset() { unset -v ar_{cat,db,DB,dom,dmn,miss,raw,RAW,reg,rpz,RPZ,sho,split,tmp,txt,url,zon} isDOWN; }
f_trap() { printf "\n"; f_tmp; f_uset; }

f_xcd() {   # exit code {7..20}
   for EC in $1; do
      local _xcd="[ERROR] $_foo: at line ${BASH_LINENO[0]}. Exit code: $EC"
      local _xce="[ERROR] $_fuu: at line ${BASH_LINENO[0]}. Exit code: $EC"
      case $EC in
          7) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "require passwordless ssh to remote host: '$2'"; exit 1;;
          8) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "require '$2' but it's not installed"; exit 1;;
          9) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "'$2' require '$3' but it's not installed"; exit 1;;
         10) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "you must execute as non-root privileges"; exit 1;;
         11) _msj="urls. it's should consist of 22 urls";
             printf -v _lmm "%s" "$(basename "$2"): $(wc -l < "$2")";
             printf "\n\x1b[91m%s\x1b[0m\n%s %s\n" "$_xcd" "$_lmm" "$_msj";
             exit 1;;
         12) _msg="lines. it's should consist of 3 lines";
             printf -v _lnn "%s" "$(basename "$2"): $(wc -l < "$2")";
             printf "\n\x1b[91m%s\x1b[0m\n%s %s\n" "$_xcd" "$_lnn" "$_msg";
             exit 1;;
         13) _ref="https://en.wikipedia.org/wiki/List_of_HTTP_status_codes";
             _unk="Check out [grab_urls]. if those url[s] are correct, please reffer to";
             printf "\x1b[91m[ERROR]\x1b[0m %s:\n\t%s\n" "$_unk" "$_ref"; exit 1;;
         14) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "download failed from '$2'"; exit 1;;
         15) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "category: must equal 6"; exit 1;;
         16) _lin=$(grep -n "^HOST" "$_fuu" | cut -d":" -f1);
             _ext="[ERROR] $_fuu: at line $_lin. Exit code: $EC";
             printf "\n\x1b[91m%s\x1b[0m\n%s: if these address is correct, maybe isDOWN\n" "$_ext" "$2"
             exit 1;;
         17) printf "\n\x1b[91m%s\x1b[0m\nmissing file: %s\n" "$_xcd" "$(basename "$2")"; exit 1;;
         18) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xce" """$2"" doesn't exist in ""$3"""; exit 1;;
         19) printf "\n\x1b[91m%s\x1b[0m\n%s\n" "$_xcd" "unexpected, please remove: ""$2"""; exit 1;;
         20) printf "\n\x1b[91m%s\x1b[0m\nmissing file: %s\n" "$_xce" "$(basename "$2")"; exit 1;;
          *) _ukn="Unknown exit code [f_xcd $1], please check:";
             printf -v _knw "%s" "$_foo at line $(grep -n "f_xcd $1" "$_foo" | cut -d":" -f1)";
             printf "\n\x1b[91m[ERROR]\x1b[0m %s\n%s\n" "$_ukn" "$_knw"
             exit 1;;
      esac
   done
   }

f_sm0() {   # getting options display messages
   printf "\n\x1b[93mCHOOSE one of the following options :\x1b[0m\n"
   printf "%4s. eliminating duplicate entries between domain lists\n" "1"
   printf "%4s. option [1] and rewriting all domain lists to RPZ format [db.* files]\n" "2"
   printf "%4s. options [1,2] and incrementing serial at zone files [rpz.*]\n" "3"
   printf "%4s. options [1,2,3] and [rsync]ronizing latest [rpz.* and db.*] files to %s\n" "4" "$1"
   printf "%4s. other than above to QUIT\n" "*"
   printf "ENTER: \x1b[92m[1|2|3|4|*]\x1b[0m\t\t"
   }

f_sm1() {   # display messages when 1'st option chosen
   printf "\n\x1b[91m[%s'st] TASK options chosen\x1b[0m\n" "$RETVAL"
   printf "\x1b[93mCONTINUED to :\x1b[0m ~eliminating duplicate entries between domain lists\n"
   printf "\x1b[93mPerforming task based on %s'st options ...\x1b[0m\n" "$RETVAL"
   }

f_sm2() {   # display messages when 2'nd option chosen
   f_sm5; printf "\x1b[93mPerforming task based on %s'th options ...\x1b[0m\n" "$RETVAL"
   }

f_sm3() {   # display messages when 3'th option chosen
   f_sm5; printf "%28s serial at zone files [rpz.*]\n" "~incrementing"
   printf "\x1b[93mPerforming task based on %s'th options ...\x1b[0m\n" "$RETVAL"
   }

f_sm4() {   # display messages when 4'th option chosen
   f_sm5; printf "%28s serial zone files [rpz.*]\n" "~incrementing"
   printf "%31s latest [rpz.* and db.*] files to %s\n" "~[rsync]ronizing" "$HOST"
   if grep -qE "^\s{2,}#s(*.*)d\"" grab_lib.sh; then
       printf "\x1b[32m%13s:\x1b[0m host %s will REBOOT due to low memory\n" "WARNING" "$HOST"
       printf "%18s \x1b[92m'shutdown -c'\x1b[0m at HOST: %s to abort\n" "use" "$HOST"
   fi
   printf "\x1b[93mPerforming task based on %s'th options ...\x1b[0m\n" "$RETVAL"
   }

f_sm5() {   # sub-function. must include in f_sm2 ... f_sm4
   printf "\n\x1b[91m[%s'th] TASK options chosen\x1b[0m\n" "$RETVAL"
   printf "\x1b[93mCONTINUED to :\x1b[0m ~eliminating duplicate entries between domain lists\n"
   printf "%25s all domain lists to RPZ format [db.* files]\n" "~rewriting"
   }

f_sm6() {   # display FINISH messages
   printf "\n[INFO] Completed \x1b[93mIN %s:%s\x1b[0m\n" "$1" "$2"
   printf "\x1b[32mWARNING:\x1b[0m there are still remaining duplicate entries between domain lists.\n"
   printf "%17s continue to next TASKs.\n" "consider"
   }

# display processing messages
f_sm7() { printf "%12s: %-64s\t" "grab_$1" "${2##htt*\/\/}"; }
f_sm8() { printf "\nProcessing \x1b[93m%s CATEGORY\x1b[0m with (%d) additional remote file(s)\n" "${1^^}" "$2"; }
f_sm9() { printf "%12s: %-64s\t" "fixing" "bads, duplicates and false entries at ${1^^}"; }
f_sm10() { printf "\n\x1b[91mTASKs\x1b[0m based on %s'%s options: \x1b[32mDONE\x1b[0m\n" "$RETVAL" "$1"; }
f_ok() { printf "\x1b[32m%s\x1b[0m\n" "isOK"; }         # display isOK
f_do() { printf "\x1b[32m%s\x1b[0m\n" "DONE"; }         # display DONE
f_add() { curl -C - -fs "$1" || f_xcd 14 "$1"; }        # grabbing remote files

# fixing false positive and bad entry. Applied to all except ipv4 CATEGORY
f_falsf() { f_sm9 "$1"; _sort -u "$2" | _sed -e "$4" -e "$5" > "$3"; f_do; }

f_ipp() { # capture and throw ip-address entry to ipv4 CATEGORY, save into CIDR block
   _grep -P "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$" \
      "$1" | _sed -e "/\/[0-9]\{2\}$/ ! s/$/\/32/" >> "$2" || true
   _sed -i -E "/^([0-9]{1,3}\.){3}[0-9]{1,3}$/d" "$1"
}

f_falsg() {
   printf "%12s: %-64s\t" "moving" "IP-address entries into $3 CATEGORY"
   f_ipp "$@"; f_do; printf "%12s: %'d entries.\n" "acquired" "$(wc -l < "$1")"
   }

f_syn() {   # passwordless ssh for "backUP oldDB and rsync newDB"
   if ping -w 1 "$HOST" >> /dev/null 2>&1; then
      # check existance of db-files and rpz-files
      ar_DB=(db.adultaa db.adultab db.adultac db.adultad db.adultae db.adultaf db.adultag \
         db.ipv4 db.malware db.publicite db.redirector db.trust+)
      ar_RPZ=(rpz.adultaa rpz.adultab rpz.adultac rpz.adultad rpz.adultae rpz.adultaf rpz.adultag \
         rpz.ipv4 rpz.malware rpz.publicite rpz.redirector rpz.trust+)
      mapfile -t ar_db < <(find . -maxdepth 1 -type f -name "db.*" | sed -e "s/\.\///" | sort)
      mapfile -t ar_rpz < <(find . -maxdepth 1 -type f -name "rpz.*" | sed -e "s/\.\///" | sort)
      printf -v miss_DB "%s" "$(echo "${ar_DB[@]}" "${ar_db[@]}" | sed "s/ /\n/g" | sort | uniq -u | tr "\n" " ")"
      printf -v miss_RPZ "%s" "$(echo "${ar_RPZ[@]}" "${ar_rpz[@]}" | sed "s/ /\n/g" | sort | uniq -u | tr "\n" " ")"

      for DB in ${ar_DB[*]}; do [ -f "$DB" ] || f_xcd 20 "$miss_DB"; done
      for RPZ in ${ar_RPZ[*]}; do [ -f "$RPZ" ] || f_xcd 20 "$miss_RPZ"; done
      [ "${#ar_db[@]}" -eq "${#ar_DB[@]}" ] || f_xcd 19 "$miss_DB"
      [ "${#ar_rpz[@]}" -eq "${#ar_RPZ[@]}" ] || f_xcd 19 "$miss_RPZ"

      # run TASK
      local _remdir="/etc/bind/zones-rpz/"
      _ssh -o BatchMode=yes "$HOST" /bin/true  >> /dev/null 2>&1 || f_xcd 7 "$HOST"
      _ssh root@"$HOST" [ -d "$_remdir" ] || f_xcd 18 "$_remdir" "$HOST"

      # use [unpigz -v rpz-2022-04-09.tar.gz] then [tar xvf rpz-2022-04-09.tar] for decompression
      local _ts; local _ID; _ts=$(date "+%Y-%m-%d"); _ID="/home/rpz-$_ts.tar.gz"
      printf "\n[INFO] archiving oldDB, save in root@%s:%s\n" "$HOST" "$_ID"
      _ssh root@"$HOST" "cd /etc/bind; tar -I pigz -cf $_ID zones-rpz"
      printf "[INFO] find and remove old RPZ dBase archive in %s:/home\n" "$HOST"
      _ssh root@"$HOST" "find /home -regextype posix-extended -regex '^.*(tar.gz)$' -mmin +1430 -print0 | xargs -0 -r rm"
      printf "[INFO] syncronizing the latest RPZ dBase to %s:%s\n" "$HOST" "$_remdir"
      _rsync {rpz,db}.* root@"$HOST":"$_remdir"

      # $HOST" will reboot [after +@ minute] due to low memory
      printf "[INFO] host: \x1b[92m%s\x1b[0m scheduled for reboot at %s\n" "$HOST" "$(faketime -f "+5m" date +%H:%M:%S)"
      _ssh root@"$HOST" "shutdown -r 5 --no-wall >> /dev/null 2>&1"
      printf "[INFO] use \x1b[92m'shutdown -c'\x1b[0m at host: %s to abort\n" "$HOST"

      # OR comment 3 lines above AND uncomment 2 lines below, if you have sufficient RAM and
      #    DON'T add space after "#" if you comment. it's use by this script at line 93
      #printf "Reload BIND9-server:%s\n" "$HOST"
      #ssh root@"$HOST" "rndc reload"
   else
      f_xcd 16 "$HOST"
   fi
   }

f_crawl() {   # verify "URLS" isUP
   isDOWN=(); local i=-1
   while IFS= read -r line || [[ -n "$line" ]]; do
      # slicing urls && add element to ${ar_sho[@]}
      local lll; local ll; local l; local p_url
      lll="${line##htt*\/\/}"; ll="$(basename "$line")"; l="${lll/\/*/}"; p_url="$l/..?../$ll"
      ar_sho+=("${p_url}"); ((i++))
      printf "%12s: %-64s\t" "urls_${i}" "${ar_sho[i]}"
      local statusCode; statusCode=$(curl -C - -ks -o /dev/null -I -w "%{http_code}" "$line")
      # https://trustpositif.kominfo.go.id/assets/db/domains give me "$statusCode" 405 = Method Not Allowed
      if [[ "$statusCode" != 2* && "$statusCode" != 405 ]]; then
         printf "\x1b[91m%s\x1b[0m\n" "Code: $statusCode"
         isDOWN+=("[Respon Code:${statusCode}] ${line}")    # add element to ${isDOWN[@]}
      else
         printf "\x1b[32m%s\x1b[0m\n" "isUP"
      fi
   done < "$1"

   local isDOWNCount=${#isDOWN[@]}
   if [ "$isDOWNCount" -eq 0 ]; then
      printf "%30s\n" " " | tr " " -
      printf "%s\n" "All URLS of remote files isUP."
   else
      printf "%84s\n" " " | tr " " -
      printf "\x1b[91m%s\x1b[0m\n" "${isDOWN[@]}"
      f_xcd 13
   fi
   }

f_dupl() { printf "eliminating duplicate entries based on \x1b[93m%s\x1b[0m\n" "${1^^}"; }
f_ddup() {  # used by grab_dedup.sh
   printf "%11s = deduplicating %s entries \t\t" "STEP $6.$1" "$2"
   _sort "$3" "$4" | uniq -d | _sort -u > "$5"
   }

f_g4b() {   # used by grab_build.sh
   local _tag; _tag=$(grep -P "^#\s{2,}v.*" "$_foo" | cut -d" " -f4)
   sed -i -e "1i ; generate at \[$(date -u "+%d-%b-%y %T") UTC\] by $_foo $_tag\n;" "$1"
   printf -v acq_al "%'d" "$(wc -l < "$1")"
   printf "%10s entries\n" "$acq_al"
   }

f_g4c() {   # used by grab_cereal.sh
   local _tag; _tag=$(grep -P "^#\s{2,}v.*" "$_foo" | cut -d" " -f4)
   if [ "$(grep -n "^; generate at" "$1" | cut -d':' -f1)" -eq 1 ]; then
      sed -i "1s/^.*$/; generate at \[$(date -u "+%d-%b-%y %T") UTC\] by $_foo $_tag/" "$1"
   else
      sed -i -e "1i ; generate at \[$(date -u "+%d-%b-%y %T") UTC\] by $_foo $_tag" "$1"
   fi
   }

f_rpz() {   # used by grab_build.sh. change 'CNAME .' if you have other policy
   printf "%13s %-27s : " "rewriting" "${3^^} to $1"
   awk '{print $0" IN CNAME .""\n""*."$0" IN CNAME ."}' "$2" >> "$1"
   f_g4b "$@"
   }

f_ip4() {   # used by grab_build.sh. change 'CNAME .' if you have other policy
   printf "%13s %-27s : " "rewriting" "${3^^} to $1"
   awk -F. '{print $5"."$4"."$3"."$2"."$1".rpz-nsip"" CNAME ."}' "$2" >> "$1"
   f_g4b "$@"
   }

f_cer() {   # used by grab_cereal.sh to copy zone-files using passwordless ssh-scp
   if ping -w 1 "$HOST" >> /dev/null 2>&1; then
      local _remdir="/etc/bind/zones-rpz"
      _ssh -o BatchMode=yes "$HOST" /bin/true  >> /dev/null 2>&1 || f_xcd 7 "$HOST"
      _ssh root@"$HOST" [ -d "$_remdir" ] || f_xcd 18 "$_remdir" "$HOST"

      for a in $1; do
         if scp -qr root@"$HOST":"$_remdir"/"$a" "$_DIR" >> /dev/null 2>&1; then
            wait
         else
            local origin="https://raw.githubusercontent.com/ngadmini/Grabbing-Blacklist-for-Bind9-RPZ/master/zones-rpz/"
            printf "\n[INFO] %s not found in %s. %s\n" "$a" "$HOST" "try to get from origin:"
            printf "%s%s\n" "$origin" "$a"
            curl -C - -fs "$origin""$a" >> "$a" ||  f_xcd 14 "$origin"
            printf "[INFO] successfully get %s from origin:\n" "$a"
            printf "%s%s\n" "$origin" "$a"
         fi
      done
      printf "\n[INFO] retrying TASK again"
      exec "$0"
   else
      f_xcd 16 "$HOST"
   fi
   }

