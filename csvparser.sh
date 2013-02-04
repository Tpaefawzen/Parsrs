#! /bin/sh
#
# csvparser.sh
#    CSV(Excel形式(RFC 4180):ダブルクォーテーションのエスケープは"")から
#    行番号列番号インデックス付き値(line field indexed value)テキストへの正規化
#    (例)
#     aaa,"b""bb","c
#     cc",d d
#     "f,f"
#     ↓
#     1 1 aaa
#     1 2 b"bb
#     1 3 c\ncc
#     1 4 d d
#     2 1 f,f
#     ◇よって grep '^1 3 ' | sed 's/^[^ ]* [^ ]* //' などと
#       後ろに grep&sed をパイプで繋げれば目的の行・列の値が得られる。
#       さらにこれを
#         sed 's/\\n/\<LF>/g' (←"<LF>"は実際には改行を表す)
#       にパイプすれば、元データに改行を含む場合でも完全な値として取り出せる。
#
# Usage: csvparser.sh [CSV_file]
#
# Written by Rich Mikan(richmikan[at]richlab.org) / Date : Feb 5, 2013


ACK=$(printf '\006')             # 1列1行化後に元々の改行を示すための印
NAK=$(printf '\025')             # (未使用)
SYN=$(printf '\026')             # ダブルクォーテーション*2のエスケープ印
LF=$(printf '\\\n_');LF=${LF%_}  # SED内で改行を変数として扱うためのもの

if [ \( $# -eq 1 \) -a \( \( -f "$1" \) -o \( -c "$1" \) \) ]; then
  file=$1
elif [ \( $# -eq 0 \) -o \( \( $# -eq 1 \) -a \( "_$1" = '_-' \) \) ]
then
  file='-'
else
  echo "Usage : ${0##*/} [CSV_file]" 1>&2
  exit 1
fi

# === データの流し込み ============================================= #
cat "$file"                                                          |
#                                                                    #
# === 値としてのダブルクォーテーションをエスケープ ================= #
#     (但しnull囲みの""も区別が付かず、エスケープされる)             #
sed "s/\"\"/$SYN/g"                                                  |
#                                                                    #
# === 値としての改行を\nに変換 ===================================== #
#     (ダブルクォーテーションが奇数個なら\n付けて次の行と結合する)   #
awk '                                                                \
  {                                                                  \
    s=$0;                                                            \
    gsub(/[^"]/,"",s);                                               \
    if (((length(s)+cy) % 2)==0) {                                   \
      cy=0;                                                          \
      printf("%s\n",$0);                                             \
    } else {                                                         \
      cy=1;                                                          \
      printf("%s\\n",$0);                                            \
    }                                                                \
  }                                                                  \
'                                                                    |
#                                                                    #
# === 各列を1行化するにあたり、元々の改行には予め印をつけておく ==== #
#     (元々の改行の後にACK行を挿入する)                              #
awk '                                                                \
  {                                                                  \
    printf("%s\n'$ACK'\n",$0);                                       \
  }                                                                  \
'                                                                    |
#                                                                    #
# === ダブルクォーテーション囲み列の1列1行化 ======================= #
#     (その前後にスペースもあれば余計なのでここで取り除いておく)     #
# (1/3)先頭からNF-1までのダブルクォーテーション囲み列の1列1行化      #
sed "s/[[:blank:]]*\(\"[^\"]*\"\)[[:blank:]]*,/\1$LF/g"              |
# (2/3)最後列(NF)のダブルクォーテーション囲み列の1列1行化            #
sed "s/,[[:blank:]]*\(\"[^\"]*\"\)[[:blank:]]*$/$LF\1/g"             |
# (3/3)ダブルクォーテーション囲み列が単独行だったらスペース除去だけ  #
sed "s/^[[:blank:]]*\(\"[^\"]*\"\)[[:blank:]]*$/\1/g"                |
#                                                                    #
# === ダブルクォーテーション囲みでない列の1列1行化 ================= #
#     (単純にカンマを改行にすればよい)                               #
#     (ただしダブルクォーテーション囲みの行は反応しないようにする)   #
sed "/[$ACK\"]/!s/,/$LF/g"                                           |
#                                                                    #
# === ダブルクォーテーション囲みを外す ============================= #
#     (単純にダブルクォーテーションを除去すればよい)                 #
#     (値としてのダブルクォーテーションはエスケープ中なので問題無し) #
tr -d '"'                                                            |
#                                                                    #
# === エスケープしてた値としてのダブルクォーテーションを戻す ======= #
#     (ただし、区別できなかったnull囲みの""も戻ってくるので適宜処理) #
# (1/3)まずは""に戻す                                                #
sed "s/$SYN/\"\"/g"                                                  |
# (2/3)null囲みの""だった場合はそれを空行に変換する                  #
sed 's/^[[:blank:]]*""[[:blank:]]*$//'                               |
# (3/3)""(二重)を一重に戻す                                          #
sed 's/""/"/g'                                                       |
#                                                                    #
# === 先頭に行番号と列番号をつける ================================= #
awk '                                                                \
  BEGIN{                                                             \
    l=1;                                                             \
    f=1;                                                             \
  }                                                                  \
  {                                                                  \
    if ($0=="'$ACK'") {                                              \
      l++;                                                           \
      f=1;                                                           \
    } else {                                                         \
      printf("%d %d %s\n",l,f,$0);                                   \
      f++;                                                           \
    }                                                                \
  }                                                                  \
'