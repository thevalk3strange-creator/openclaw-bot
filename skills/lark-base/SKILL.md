---
name: gamvoc
description: Tra cứu đơn hàng Gấm Vóc - tìm theo mã, SĐT, tên khách, xem danh sách
user-invocable: true
command-dispatch: tool
command-tool: exec
command-arg-mode: raw
metadata:
  openclaw:
    requires:
      bins:
        - gamvoc
---

# Gấm Vóc - Tra cứu đơn hàng từ Lark Base

Dùng lệnh `gamvoc` để tra cứu. Khi người dùng muốn tra cứu, LUÔN LUÔN chạy exec tool với lệnh tương ứng.

## Các lệnh

### Tìm đơn theo mã
```bash
gamvoc don <mã đơn>
```
VD: `gamvoc don 1480`

### Tìm đơn theo SĐT
```bash
gamvoc sdt <SĐT>
```

### Tìm đơn theo tên khách
```bash
gamvoc khach <tên khách>
```

### Danh sách đơn mới nhất
```bash
gamvoc list
```

### Danh sách sản xuất
```bash
gamvoc sx
```

## QUAN TRỌNG
Mỗi khi người dùng hỏi về đơn hàng, BẠN PHẢI dùng exec tool để chạy lệnh gamvoc tương ứng.
KHÔNG BAO GIỜ lặp lại câu hỏi. KHÔNG BAO GIỜ bỏ qua.
SAU KHI có kết quả JSON, trình bày bằng tiếng Việt: Mã đơn, Khách hàng, SĐT, Sản phẩm, Ngày giao.
