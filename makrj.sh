#!/bin/sh

######################################################################
#
# MAKRJ.SH
#   A JSON Generator Which Makes From "JSONPath-value" Formatted Text
#
# === What is "JSONPath-value" Formatted Text? ===
# 1. Format
#    <JSONPath_string#1> + <0x20> + <value_at_that_path#1>
#    <JSONPath_string#2> + <0x20> + <value_at_that_path#2>
#    <JSONPath_string#3> + <0x20> + <value_at_that_path#3>
#             :              :              :
# 2. How do I get that formatted text?
#   "JSONPath-indexed value" also can be generated by "parsrj.sh".
#   (Try to convert some JSON data with parsrj.sh, and learn its format)
#
# === This Command will Do Like the Following Conversion ===
# 1. Input Text (JSONPath-value Formatted Text)
#    $.hoge 111
#    $.foo[0] 2\n2
#    $.foo[1].bar 3 3
#    $.foo[1].fizz.bazz 444
#    $.foo[2] \u5555
# 2. Output Text This Command Generates (equivalent JSON)
#    {"hoge":111,
#     "foo" :["2\n2",
#             {"bar" :"3 3",
#              "fizz":{"bazz":444}
#             },
#             "\u5555"
#            ]
#    }
#
# === Usage ===
# Usage : makrj.sh [JSON-value_textfile]
#
#
# Written by Shell-Shoccar Japan (@shellshoccarjpn) on 2017-03-05
#
# This is a public-domain software (CC0). It means that all of the
# people can use this for any purposes with no restrictions at all.
# By the way, We are fed up with the side effects which are brought
# about by the major licenses.
#
######################################################################


######################################################################
# Initial configuration
######################################################################

# === Initialize shell environment ===================================
set -eu
export LC_ALL=C
export PATH="$(command -p getconf PATH)${PATH:+:}${PATH:-}"

# === Define the functions for printing usage and error message ======
print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [JSONPath-value_textfile]
	Version : 2017-03-05 04:49:02 JST
	          (POSIX Bourne Shell/POSIX commands)
	USAGE
  exit 1
}
error_exit() {
  ${2+:} false && echo "${0##*/}: $2" 1>&2
  exit $1
}


######################################################################
# Parse Arguments
######################################################################

# === Print the usage when "--help" is put ===========================
case "$# ${1:-}" in
  '1 -h'|'1 --help'|'1 --version') print_usage_and_exit;;
esac

# === Get the filepath ===============================================
case "$#" in
  0) file='-'                                                              ;;
  1) if [ -f "$1" ] || [ -c "$1" ] || [ -p "$1" ] || [ "_$1" = '_-' ]; then
       file=$1
     else
       error_exit 1 'Cannot open the file: '"$file"
     fi
     case "$file" in -|/*|./*|../*) :;; *) file="./$file";; esac           ;;
  *) print_usage_and_exit                                                  ;;
esac


######################################################################
# Prepare for the Main Routine
######################################################################

# === Define some chrs. to escape some special chrs. temporarily =====
HT=$( printf '\t'  ) # Means TAB
FS=$( printf '\034') # Use to divide JSONPath and value temporarily
ACK=$(printf '\006') # Use to escape <0x20> temporarily
NAK=$(printf '\025') # Use to escape TAB temporarily
ETX=$(printf '\003') # Use to mark empty value


######################################################################
# Main Routine (Convert and Generate)
######################################################################

# === Open the "JSONPath-value" data source ================================== #
cat "$file"                                                                    |
#                                                                              #
# === Escape all of " "s and TABs in the value field to temporarily ============
sed '/^[^ '"$HT"']\{1,\}$/s/$/ '$ETX'/' 2>/dev/null                            |
sed 's/ /'$FS'/'                                                               |
tr  " $HT$FS" "$ACK$NAK "                                                      |
#                                                                              #
# === Normalize the value field depending on type ==============================
awk '$2~/^".*"$/              {print $0             ;next;} #<-string          #
     $2~/^-?([1-9][0-9]*|0)(\.[0-9]+)?([Ee][+-][0-9]+)?$/ { #<-number          #
                               print $0             ;next;}                    #
     $2~/^(null|true|false)$/ {print $0             ;next;} #<-boolians        #
     $2=="'$ETX'"             {print $0             ;next;} #<-empty-field     #
     {                         s=$2; gsub(/"/,"\\\"",s);    #<-non-quoted-str  #
                               print $1,"\"" s "\"" ;next;}                  ' |
#                                                                              #
# === Add the prefix of type (Hash or List array), and split into KEYs =========
awk '{s=$1;                                                                    #
      gsub(/\./        ," H:"  ,s);                                            #
      gsub(/\[[0-9]+\]/," L:&" ,s);                                            #
      sub( /h:$/       ," H:{}",s);                                            #
      print s,$2                  ;}'                                          |
#                                                                              #
# === Cut the first KEY because every line also has it =========================
sed 's/^\$ //'                                                                 |
#                                                                              #
# === (For debuggin code) ======================================================
#cat; exit 0                                                                   #
#                                                                              #
# === Build the JSON data ======================================================
awk '# --- initialize ------------------------------------------------         #
     BEGIN{                                                                    #
       OFS="";ORS="";                                                          #
       last_depth =0 ; # depth of the last line                                #
       last_key[0]=""; # each string of last keys                              #
     }                                                                         #
     # --- main loop -------------------------------------------------         #
     { # 1) get the value field and unescape <0x20>s and TABs                  #
       val=$NF;                                                                #
       gsub(/'$ACK'/," " ,val);                                                #
       gsub(/'$NAK'/,"\t",val);                                                #
       #                                                                       #
       # 2) compare the path with the last one                                 #
       curr_depth=NF-1; # depth of the current line                            #
       same_depth=0   ; # number of keys which are same from top               #
       j=(curr_depth<last_depth)?curr_depth:last_depth;                        #
       for (i=1; i<=j; i++) {                                                  #
         if($i==last_key[i]){same_depth=i;}else{break;}                        #
       }                                                                       #
       if (same_depth>0                 &&                                     #
           substr($same_depth,1,1)=="H" &&                                     #
           same_depth==curr_depth         ) {                                  #
         same_depth--;                                                         #
         if (same_depth>0                 &&                                   #
             substr($same_depth,1,1)=="L" &&                                   #
             substr($(same_depth+1),1,1)==substr(last_key[same_depth+1],1,1)){ #
           same_depth--;                                                       #
         }                                                                     #
       }                                        # (debug)                      #
       #print "same_depth=",same_depth,"\n" > "/dev/stderr";                   #
       #                                                                       #
       # 3) move the key tree and generate the corresponding JSON string       #
       #    (up to the top of the tree)                                        #
       s="";                                                                   #
       for (i=last_depth  ; i> same_depth; i--) {                              #
         if   (substr(last_key[i],1,1)=="H") { s = s "}"; }                    #
         else                                { s = s "]"; }                    #
       }                                                                       #
       #                                                                       #
       # 4) move the key tree and generate the corresponding JSON string       #
       #    (down to the bottom of the tree)                                   #
       for (i=same_depth+1; i<=curr_depth; i++) {                              #
         if   (substr($i,1,1)=="H") { s = s "{\n\"" substr($i,3) "\":"; }      #
         else                       { s = s "["                       ; }      #
       }                                                                       #
       #                                                                       #
       # 5) if it moves in the same level as a result,                         #
       #    replace the JSONS chrs in the string with ","                      #
       sub( /(\}\{|\]\[)/,","  ,s);                                            #
       gsub(/\}/         ,"\n}",s);                                            #
       if (s=="" ) {s="," ;}                                                   #
       if (same_depth>0 && substr($same_depth,1,1)=="L") {                     #
         if      (sub(/^[{[]/,",&",s)) {}                                      #
         else if (sub(/[]}]$/,"&,",s)) {}                                      #
       }                                                                       #
       #                                                                       #
       # 6) print the JSON string with the value string                        #
       #    (however it must be printed only string for empty-field)           #
       if      (val        !="'$ETX'") {print s,val                  ;}        #
       else if ($curr_depth=="H:"    ) {print substr(s,1,length(s)-4);}        #
       else                            {print s                      ;}        #
       #                                                                       #
       # 7) copy every KEY string to the last KEY variables                    #
       if     (curr_depth > last_depth) {                                      #
         for (i=same_depth+1; i<=curr_depth; i++) {                            #
           last_key[i]=$i                                                      #
         }                                                                     #
       } else {                                                                #
         for (i=last_depth  ; i> curr_depth; i--) {                            #
           delete last_key[i];                                                 #
         }                                                                     #
         for (              ; i> same_depth; i--) {                            #
           last_key[i]=$i                                                      #
         }                                                                     #
       }                                                                       #
       last_depth=curr_depth;                                                  #
     }                                                                         #
     # --- the last loop ---------------------------------------------         #
     END{                                                                      #
       # 1) move the key tree and generate the corresponding JSON string       #
       #    (down to the bottom of the tree)                                   #
       same_depth=0;                                                           #
       s="";                                                                   #
       for (i=last_depth  ; i> same_depth; i--) {                              #
         if   (substr(last_key[i],1,1)=="H") { s = s "}"; }                    #
         else                                { s = s "]"; }                    #
       }                                                                       #
       #                                                                       #
       # 2) print the JSON string                                              #
       gsub(/\}/,"\n}",s);                                                     #
       print s;                                                                #
     }'                                                                        |
#                                                                              #
# === Insert the break chr. at the last of the data ============================
grep ^ || :                                                                    #