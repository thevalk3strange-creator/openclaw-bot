#!/bin/sh
# Gam Voc order lookup wrapper
# Usage: gamvoc don <ma> | gamvoc sdt <sdt> | gamvoc list | gamvoc sx
set -e
CMD="${1:-help}"; ARG="${2:-}"
case "$CMD" in
  don)   exec /usr/local/bin/lark-lookup search --field "Mã đơn hàng SAPO" --keyword "#${ARG}" ;;
  sdt)   exec /usr/local/bin/lark-lookup search --field "SĐT" --keyword "${ARG}" ;;
  khach) exec /usr/local/bin/lark-lookup search --field "Khách hàng" --keyword "${ARG}" ;;
  list)  exec /usr/local/bin/lark-lookup list --page-size 20 ;;
  sx)    exec /usr/local/bin/lark-lookup list --table sx --page-size 20 ;;
  *)     echo '{"error":"Usage: gamvoc don <ma> | gamvoc sdt <sdt> | gamvoc khach <ten> | gamvoc list | gamvoc sx"}' && exit 1 ;;
esac
