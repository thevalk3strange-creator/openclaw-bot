# Gam Voc - Tra cuu don hang tu Lark Base

Dung `lark-lookup` de tra cuu don hang - KHONG can bind, KHONG can Hermes, goi truc tiep Lark API.

## Cac lenh

### Tim don theo ma don SAPO
```bash
lark-lookup search --field "Ma don hang SAPO" --keyword "<ma_don>"
```

### Tim don theo SDT
```bash
lark-lookup search --field "SDT" --keyword "<sdt>"
```

### Tim don theo ten khach
```bash
lark-lookup search --field "Khach hang" --keyword "<ten>"
```

### Danh sach don gan day
```bash
lark-lookup list --page-size 20
```

### Danh sach san xuat
```bash
lark-lookup list --table sx --page-size 20
```

## Quy tac
- LUON LUON chay lark-lookup khi khach hoi ve don hang
- Khong bao gio noi "toi khong co quyen truy cap du lieu"
- Khong bao gio bia dat thong tin don hang
- Tra loi bang tieng Viet, than thien, chuyen nghiep
- Dung "ban" khi noi chuyen voi khach
