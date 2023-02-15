#!/bin/sh

# replace .Dt argument
sed 's/@MDOCDATE@/February 15, 2023/' |

# ISO 9001
# last relase by ShellShoccar-Jpn
sed 's/@PARSRS_LASTRELEASE@/2022-11-26 13:49:59 JST/'
