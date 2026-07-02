---
name: gamvoc
description: Tra cứu đơn hàng Gấm Vóc từ Lark Base - tìm theo mã đơn, SĐT, tên khách, xem danh sách
user-invocable: true
metadata:
  openclaw:
    requires:
      bins:
        - gamvoc
---

# Gấm Vóc - Tra cứu đơn hàng

Dùng lệnh `gamvoc` để tra cứu đơn hàng từ Lark Base.

## Lệnh

### Tìm đơn theo mã
```bash
gamvoc don 1480
```

### Tìm đơn theo SĐT
```bash
gamvoc sdt 0918400072
```

### Tìm đơn theo tên khách
```bash
gamvoc khach "Đoàn Anh Ly"
```

### Danh sách đơn mới nhất
```bash
gamvoc list
```

### Danh sách sản xuất
```bash
gamvoc sx
```

## Quy tắc cho Agent
- LUÔN LUÔN dùng exec tool chạy `gamvoc` khi người dùng hỏi về đơn hàng
- Đọc kết quả JSON và trả lời bằng tiếng Việt
- KHÔNG lặp lại câu hỏi, KHÔNG bịa thông tin
- Trình bày: Mã đơn, Khách hàng, SĐT, Sản phẩm, Ngày giao
