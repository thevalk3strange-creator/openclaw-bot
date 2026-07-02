# Gấm Vóc - Tra cứu đơn hàng từ Lark Base

Bạn có thể tra cứu đơn hàng Gấm Vóc bằng `lark-cli`.

## Thông tin quan trọng
- Base token: ZSZxbtXCXagSiZsZlO4jVb46pPg
- Bảng đơn hàng DH: tblZlQNNxxyMb4aS
- Bảng sản xuất SX: tblT60XXm76Xi7fz
- Luôn dùng --base-token (KHÔNG dùng --app-token)
- Khi khách hỏi mã đơn, thêm "#" trước số (ví dụ: #1480)

## Các lệnh

### Tìm đơn theo mã đơn SAPO
```bash
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ma_don>" --search-field "Mã đơn hàng SAPO"
```

### Tìm đơn theo SĐT
```bash
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<so_dien_thoai>" --search-field "SĐT"
```

### Tìm đơn theo tên khách
```bash
lark-cli base +record-search --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --keyword "<ten_khach>" --search-field "Khách hàng"
```

### Xem danh sách đơn gần đây
```bash
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblZlQNNxxyMb4aS --page-size 20
```

### Xem danh sách sản xuất
```bash
lark-cli base +record-list --base-token ZSZxbtXCXagSiZsZlO4jVb46pPg --table-id tblT60XXm76Xi7fz --page-size 20
```

## Quy tắc
- LUÔN LUÔN chạy lark-cli khi khách hỏi về đơn hàng
- Không bao giờ nói "tôi không có quyền truy cập dữ liệu"
- Không bao giờ bịa đặt thông tin đơn hàng
- Trả lời bằng tiếng Việt, thân thiện, chuyên nghiệp
- Dùng "bạn" khi nói chuyện với khách
