#!/bin/bash
#   Copyright 2023 bin jin
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

[ -e "$1" ] || { printf "target file '$1' not exist\n" >&2; exit 1; }
which qrencode >/dev/null 2>/dev/null || { printf "'qrencode' command not found or not in '\$PATH'\n" >&2; exit 1; }

get_current_rows() {
    set -- $(stty size)
    set -- $(($1 - 1)) $(($2 / 2 + 1))
    [ $1 -lt $2 ] && printf $1 || printf $2
}

all_ascii_qr_rows=(`seq 29 4 185`) # ascii_qr_cols_by_version[$version - 1]=$((${all_ascii_qr_rows[$version - 1]} * 2))

# for i in {2..40}; do cat "$1" | gzip | base64 | while read l; do [ $((++c % $i)) == 1 ] && { printf "$n" | qrencode -o - -t ascii | awk 'END{print NR, length($0)}' || break; unset n; }; n="$n$l\n"; done | awk -v i=$i 'BEGIN{m=0};{t=strtonum($1);if(t > m) m = t}END{print i "," m}'; done
# base64 rows:  01 02 03 04 05 06 07 08 09  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38
   max_qr_rows=(41 57 65 69 77 85 89 93 97 101 105 113 117 117 121 125 129 133 137 141 141 145 149 153 153 157 161 161 165 169 169 173 173 177 181 181 185 185) # 76/64 same for base64 & openssl base & certutil.exe -decode

current_rows=`get_current_rows`;
[ $current_rows -lt $((${max_qr_rows[0]} + 4)) ] && {
    printf "window is too small\n" >&2
    exit 1
}

unset default_step
[ $current_rows -ge ${max_qr_rows[${#max_qr_rows[@]} - 4]} ] && default_step=$((${#max_qr_rows[@]} - 2)) || for i in ${!max_qr_rows[@]}; do
    [ $current_rows -ge ${max_qr_rows[$i]} -a $current_rows -le ${max_qr_rows[$i + 1]} ] && {
        default_step=$(($i + 1));
        break
    }
done

input_path="$1" base64_tmp_file=".${input_path##*/}-$$.log";
shift;

unset sleep_sec step_rows index_list || exit 1
while getopts ":s:w:l:" opt; do
    case "${opt}" in
        s) step_rows="$OPTARG";;
        w) sleep_sec="$OPTARG";;
        l) index_list="$OPTARG";;
        *) printf "Usage: $0 [target_file] -w [sleep_sec] -s [step_rows] -l [index_list/range]\n\n" >&2; exit 1;;
    esac
done

if [ "$step_rows" ]; then
    [ $step_rows -gt $default_step ] && {
        printf "window is too small to can not use step_rows: '$step_rows'\n" >&2;
        exit 1
    }
else
    step_rows=$default_step
fi


if [ -f "$input_path" ]; then
    cat "$input_path" | { [ "${input_path##*.}" == "gz" ] && cat || gzip; }
elif [ -d "$input_path" ]; then
    tar -czf - "$input_path"
else
    printf "unknown input type '$input_path'.\n" >&2;
    exit 1

fi | base64 > "$base64_tmp_file";

input_type=f; [ -d "$input_path" ] && { input_path="${input_path%/}"; input_type=d; }
sleep_sec=${sleep_sec:-'0.9'};
base64_sha1=$(sha1sum "$base64_tmp_file") max_nr=$(grep -c '^[0-9A-Za-z+/=]\+$' "$base64_tmp_file")
qr_count=$((max_nr / step_rows + 1)); [ $((max_nr % step_rows)) == 0 ] && qr_count=$((qr_count - 1))

begin_timestamp=$(date +%s)
# header
printf "# begin ${base64_sha1%% *} $input_path\nbegin_timestamp=$begin_timestamp,\nsleep_sec=$sleep_sec,\nstep_rows=$step_rows,\nqr_count=$qr_count,\nmax_nr=$max_nr\ninput_type=$input_type\n";
printf "# begin ${base64_sha1%% *} $input_path\n$begin_timestamp,$sleep_sec,$step_rows,$qr_count,$max_nr,$input_type" | qrencode -o - -t ansi256
sleep $sleep_sec; sleep 0.8;

rows_cols=$(stty size);
printf -v blank_lines "%$((${rows_cols% *} - ${max_qr_rows[$step_rows - 1]}))s" " ";
printf -v blank_lines %s" ${blank_lines// /\\n}";
printf -v blank_lines_max "%$((${rows_cols% *} - ${all_ascii_qr_rows[0]}))s" " ";
printf -v blank_lines_max %s" ${blank_lines_max// /\\n}";

trap '_kill_awk $?' SIGINT
_kill_awk() { kill $awk_pid && rm -f "$base64_tmp_file"; exit 0; }

awk \
    -v step=$step_rows \
    -v qr_count=$qr_count \
    -v blank_lines="$blank_lines" \
    -v blank_lines_max="$blank_lines_max" \
    -v sleep_sec=$sleep_sec \
    -v index_list="$index_list" \
    'BEGIN{
        begin = 0;
        if (index_list) {
            if (match(index_list, /^[[:space:]]*[0-9]+[[:space:]]*[+-]/)) {
                begin = strtonum(gensub(/^[[:space:]]+/, "", 1, gensub(/[[:space:]]*[+-].*/, "", 1, index_list)));
                index_list = ""
            } else {
                split(index_list, tmp_arr, /[[:space:]]+/);
                for(i in tmp_arr) idx_map[tmp_arr[i]]=1
            }
        }
    };
    {
        out=out "" $0 "\n";
        if(NR % step == 0) {
            idx++;
            if (!index_list || idx_map[idx]) if (idx >= begin)
                system("printf \"" blank_lines "\n# " idx " / " qr_count "\n\"; printf \"# " idx "\n" out "\" | qrencode -o - -t ansi256; sleep " sleep_sec);
            out=""
        }
    };
    END{
        idx++;
        if (out != "") if (!index_list || idx_map[idx]) if (idx >= begin)
            system("printf \"" blank_lines_max "\n# " idx " / " qr_count "\n\"; printf \"# " idx "\n" out "\" | qrencode -o - -t ansi256; sleep " sleep_sec)
    }' "$base64_tmp_file" &
awk_pid=$!

wait $awk_pid;

end_timestamp=$(date +%s)
use_sec=$((end_timestamp - $begin_timestamp))

printf "$blank_lines_max\n# end / ${use_sec}s\n";
printf "# end / $end_timestamp" | qrencode -o - -t ansi256;
sleep $sleep_sec; sleep 0.8;

printf -v blank_lines_all "%${rows_cols% *}s" " ";
printf -v blank_lines_all %s" ${blank_lines_all// /\\n}";
printf "$blank_lines_all\n# complete! sending the file '$input_path', using $qr_count + 2 QR codes, took $use_sec seconds.\n"

rm -f "$base64_tmp_file";
