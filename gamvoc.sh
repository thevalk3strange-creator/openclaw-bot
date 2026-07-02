#!/bin/sh
# Gam Voc order lookup — ultra-simple wrapper for lark-lookup
# Usage: gamvoc don <ma> | gamvoc sdt <sdt> | gamvoc list | gamvoc sx
set -e

CMD="${1:-help}"
ARG="${2:-}"

case "$CMD" in
  don)
    exec lark-lookup search --field "Mã đơn hàng SAPO" --keyword "#${ARG}"
    ;;
  sdt)
    exec lark-lookup search --field "SĐT" --keyword "${ARG}"
    ;;
  khach)
    exec lark-lookup search --field "Khách hàng" --keyword "${ARG}"
    ;;
  list)
    exec lark-lookup list --page-size 20
    ;;
  sx)
    exec lark-lookup list --table sx --page-size 20
    ;;
  *)
    echo '{"error":"Usage: gamvoc don <ma> | gamvoc sdt <sdt> | gamvoc khach <ten> | gamvoc list | gamvoc sx"}'
    exit 1
    ;;
esac
