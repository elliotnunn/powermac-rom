#!/bin/sh

cd "`dirname "$0"`" && find . -type f -not -path '*/.*' -not -ipath './BuildResults/*' \( -not -name '*.*' -o -iname '*.s' -o -iname '*.a' -o -iname '*.c' -o -iname '*.h' \) -exec SetFile -t 'TEXT' -c 'MPS ' {} \;
