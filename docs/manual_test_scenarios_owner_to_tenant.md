# Kịch bản test tay tổng quan từ chủ trọ đến khách thuê

Tài liệu này dùng để test thủ công toàn hệ thống theo một chuỗi dữ liệu xuyên suốt: chủ trọ tạo nhà/phòng, tạo khách thuê, lập cọc/hợp đồng, chốt điện nước, lập hóa đơn, thu chi, kết thúc hợp đồng, khách thuê đăng nhập đối chiếu dữ liệu. Mục tiêu không chỉ là xem màn hình có chạy không, mà là bắt bug quan hệ dữ liệu giữa các chức năng.

## Cách ghi bug

Mỗi bug nên ghi theo mẫu:

```text
Màn hình:
Tài khoản đang dùng:
Dữ liệu test:
Thao tác:
Kết quả mong đợi:
Kết quả thực tế:
Ảnh/video:
Mức độ: blocker / high / medium / low
```

Quy ước dữ liệu test: đặt tiền tố `TEST_` cho tên nhà, phòng, khách thuê, phiếu thu/chi, bài đăng. Sau khi test xong, tìm theo `TEST_` để dọn.

## Dữ liệu mẫu

Tài khoản:

- Chủ trọ: `owner_test`, SĐT `0900000001`.
- Manager: `manager_test`, SĐT `0900000002`.
- Khách thuê A: `tenant_a_test`, SĐT `0910000001`.
- Khách thuê B: `tenant_b_test`, SĐT `0910000002`.
- Người ngoài chưa thuê: `guest_test`, SĐT `0910000099`.

Nhà/phòng:

- Nhà 1: `TEST_Nha_A`.
- Nhà 2: `TEST_Nha_B`.
- Phòng A101: giá `2,500,000`, cọc `1,000,000`, tối đa `2` người.
- Phòng A102: giá `3,000,000`, cọc `1,500,000`, tối đa `3` người.
- Phòng B201: dùng để kiểm tra manager không có quyền.

Dịch vụ:

- Internet: `100,000`/tháng.
- Rác: `30,000`/tháng.
- Gửi xe: `80,000`/xe/tháng.
- Điện: `3,500`/kWh.
- Nước: `15,000`/m3.

Chỉ số:

- Điện đầu kỳ hợp đồng A: `100`.
- Nước đầu kỳ hợp đồng A: `20`.
- Chốt tháng đầu: điện `150`, nước `28`.
- Chốt tháng sau: điện `210`, nước `35`.

## Pha 1: Đăng ký, đăng nhập, phân quyền

### TC-01: Đăng ký chủ trọ mới

Thao tác:

1. Mở app, chọn đăng ký.
2. Nhập tên, username, số điện thoại, mật khẩu.
3. Chọn vai trò chủ trọ nếu app yêu cầu.
4. Đăng xuất, đăng nhập lại bằng username.
5. Đăng xuất, đăng nhập lại bằng số điện thoại.

Kỳ vọng:

- Đăng ký thành công, vào đúng màn chủ trọ.
- Đăng nhập được bằng username và số điện thoại.
- Không có thông báo thiếu dấu tiếng Việt.
- Không tự liên kết tài khoản chủ trọ vào tenant trùng số điện thoại.

Ca lỗi cần thử:

- Bỏ trống từng trường bắt buộc.
- Username dưới độ dài tối thiểu.
- Số điện thoại sai định dạng.
- Đăng ký trùng username.
- Đăng ký trùng số điện thoại.

### TC-02: Tạo manager và giới hạn quyền

Thao tác:

1. Chủ trọ tạo `TEST_Nha_A` và `TEST_Nha_B`.
2. Tạo manager `manager_test`.
3. Gán manager chỉ quản lý `TEST_Nha_A`.
4. Đăng nhập manager.
5. Kiểm tra danh sách nhà, phòng, khách thuê, hợp đồng, hóa đơn, sự cố, thống kê.

Kỳ vọng:

- Manager chỉ thấy dữ liệu thuộc `TEST_Nha_A`.
- Manager không tạo/sửa/xóa dữ liệu của `TEST_Nha_B`.
- Nếu manager không có quyền tạo nhà, nút tạo nhà phải ẩn hoặc thao tác bị chặn rõ ràng.

Ca lỗi cần thử:

- Manager truy cập chi tiết dữ liệu ngoài quyền bằng nút quay lại, deep link, dữ liệu đã cache.
- Manager sửa/xóa phòng ngoài quyền sau khi đổi filter.
- Chủ trọ thu hồi quyền manager, manager reload app phải mất quyền ngay.

## Pha 2: Nhà trọ và phòng

### TC-03: Tạo, sửa, xem chi tiết nhà

Thao tác:

1. Chủ trọ tạo `TEST_Nha_A` với địa chỉ đầy đủ.
2. Thêm ảnh nhà nếu có.
3. Vào chi tiết nhà, đối chiếu địa chỉ, ảnh, tiện ích, số phòng.
4. Sửa tên thành `TEST_Nha_A_Edit`.
5. Sửa địa chỉ, ảnh, tiện ích.

Kỳ vọng:

- Danh sách nhà cập nhật sau khi tạo/sửa.
- Chi tiết nhà không mất ảnh cũ khi chỉ sửa text.
- Địa chỉ hiển thị thống nhất ở danh sách, chi tiết, bài đăng nếu có dùng lại.

Ca lỗi cần thử:

- Tạo nhà thiếu tỉnh/quận/phường/địa chỉ chi tiết.
- Upload ảnh lớn hoặc chọn nhiều ảnh.
- Bấm lưu nhiều lần liên tục.
- Mất mạng khi đang lưu.

### TC-04: Xóa nhà

Thao tác:

1. Tạo `TEST_Nha_Delete_Empty` chưa có phòng.
2. Xóa nhà này.
3. Tạo phòng trong `TEST_Nha_A`.
4. Thử xóa `TEST_Nha_A`.

Kỳ vọng:

- Nhà trống xóa được và biến mất khỏi danh sách.
- Nhà có phòng/hợp đồng/hóa đơn phải bị chặn hoặc yêu cầu xử lý dữ liệu phụ thuộc.
- Không còn phòng mồ côi sau khi xóa nhà.

### TC-05: Tạo, sửa, lọc phòng

Thao tác:

1. Tạo A101, A102 trong `TEST_Nha_A`.
2. Tạo B201 trong `TEST_Nha_B`.
3. Sửa giá A101 từ `2,500,000` thành `2,700,000`.
4. Sửa tối đa người từ `2` thành `3`.
5. Lọc theo nhà, trạng thái, giá.
6. Tìm kiếm theo tên phòng.

Kỳ vọng:

- Giá mới chỉ áp dụng cho phòng/hợp đồng mới theo quy tắc hiện tại.
- Filter không lẫn phòng giữa các nhà.
- Manager chỉ thấy A101/A102 nếu chỉ được gán `TEST_Nha_A`.

Ca lỗi cần thử:

- Giá âm, giá bằng 0.
- Cọc âm hoặc lớn bất thường.
- Tên phòng trùng trong cùng nhà.
- Xóa phòng trống.
- Thử xóa phòng đã có hợp đồng active.

## Pha 3: Dịch vụ và giá riêng

### TC-06: Tạo và sửa dịch vụ

Thao tác:

1. Tạo dịch vụ Internet, Rác, Gửi xe.
2. Tạo/sửa đơn giá điện, nước nếu nằm trong màn dịch vụ.
3. Sửa Internet từ `100,000` thành `120,000`.
4. Kiểm tra danh sách dịch vụ ở màn lập hợp đồng.

Kỳ vọng:

- Dịch vụ mới xuất hiện trong màn lập hợp đồng.
- Sửa giá dịch vụ không làm đổi hóa đơn đã phát hành.
- Dịch vụ có trạng thái ngừng dùng nếu không cho xóa.

Ca lỗi cần thử:

- Tạo trùng tên dịch vụ.
- Đơn giá âm.
- Xóa dịch vụ chưa dùng.
- Thử xóa dịch vụ đã gắn vào hợp đồng/hóa đơn.

### TC-07: Dịch vụ trong hợp đồng và hóa đơn

Thao tác:

1. Lập hợp đồng A101 có Internet + Rác.
2. Lập hóa đơn tháng 1.
3. Sau đó sửa giá Internet.
4. Mở lại hóa đơn tháng 1.
5. Lập hóa đơn tháng 2.

Kỳ vọng:

- Hóa đơn tháng 1 giữ nguyên giá tại thời điểm lập.
- Hóa đơn tháng 2 dùng giá mới nếu quy tắc là lấy giá hiện tại.
- Nếu hợp đồng lưu giá riêng, hóa đơn phải dùng giá riêng trong hợp đồng, không tự lấy giá global.

Điểm dễ bug:

- Giá dịch vụ bị nhân đôi.
- Hóa đơn cũ tự đổi tổng tiền.
- Dịch vụ đã bỏ khỏi hợp đồng vẫn lên hóa đơn.

## Pha 4: Đặt cọc

### TC-08: Cọc chờ lập hợp đồng

Thao tác:

1. Tạo cọc cho tenant A, phòng A101, trạng thái chờ.
2. Sửa thông tin cọc khi còn chờ.
3. Hủy cọc khi còn chờ.
4. Tạo lại cọc mới cho tenant A.
5. Từ cọc này lập hợp đồng.

Kỳ vọng:

- Cọc chờ được sửa/hủy.
- Cọc đã dùng để lập hợp đồng không được hủy như cọc chờ.
- Phòng không bị chuyển trạng thái sai nếu hủy cọc.

Ca lỗi cần thử:

- Tạo cọc cho phòng đã có hợp đồng active.
- Tạo cọc trùng cho cùng phòng/khách.
- Hủy cọc rồi vẫn lập được hợp đồng từ cọc đã hủy.

### TC-09: Cọc thanh toán tự động/test PayOS

Thao tác:

1. Tạo cọc chờ thanh toán.
2. Mở màn thanh toán.
3. Dùng return URL/test flow để chuyển paid.
4. Kiểm tra trạng thái cọc và phiếu thu nếu có sinh ra.

Kỳ vọng:

- Chỉ cập nhật đúng cọc đang thanh toán.
- Không tạo trùng phiếu thu khi return URL gọi nhiều lần.
- Cọc expired không chuyển thành paid tùy tiện.

## Pha 5: Khách thuê

### TC-10: Thêm và sửa khách thuê

Thao tác:

1. Thêm khách thuê A vào phòng A101.
2. Nhập họ tên, SĐT `0910000001`, CCCD, ảnh CCCD mặt trước/sau.
3. Mở chi tiết khách thuê.
4. Sửa tên, ngày sinh, địa chỉ, ảnh CCCD.
5. Đổi SĐT sang số mới chưa tồn tại.
6. Thử đổi SĐT sang số của tenant B hoặc user khác.

Kỳ vọng:

- Ảnh CCCD hiển thị giống style ở màn thêm khách thuê và tạo hợp đồng.
- Không trùng SĐT gây liên kết sai tài khoản.
- Sửa khách thuê không làm hỏng hợp đồng/hóa đơn cũ.

Ca lỗi cần thử:

- Bỏ trống tên hoặc SĐT.
- SĐT sai định dạng.
- Upload ảnh rồi quay lại không lưu.
- Sửa tenant có user_id đã liên kết.

### TC-11: Thành viên trong phòng

Thao tác:

1. Thêm tenant B là thành viên phụ cùng phòng A101.
2. Kiểm tra số lượng người hiện tại của phòng.
3. Xóa tenant B.
4. Thử thêm vượt quá `max_tenants`.

Kỳ vọng:

- Số người hiện tại tăng/giảm đúng.
- Không cho vượt quá số người tối đa.
- Xóa thành viên phụ không ảnh hưởng hợp đồng đại diện.

## Pha 6: Hợp đồng

### TC-12: Lập hợp đồng mới từ phòng trống

Thao tác:

1. Chọn A101.
2. Chọn tenant A làm đại diện.
3. Kiểm tra tự điền giá phòng, tiền cọc, dịch vụ, điện/nước đầu kỳ.
4. Nhập ngày bắt đầu, ngày kết thúc, ngày thu tiền là ngày 5.
5. Lưu hợp đồng.
6. Mở chi tiết hợp đồng.

Kỳ vọng:

- A101 chuyển sang đang thuê.
- Hợp đồng active gắn đúng tenant A và room A101.
- Điện đầu kỳ `100`, nước đầu kỳ `20`.
- Không bị thiếu dấu tiếng Việt trong thông báo.

Ca lỗi cần thử:

- Ngày kết thúc nhỏ hơn ngày bắt đầu.
- Thiếu tenant đại diện.
- Thiếu phòng.
- Lập hợp đồng thứ hai cho A101 khi hợp đồng cũ active.

### TC-13: Sửa hợp đồng trước/sau hóa đơn

Thao tác:

1. Khi chưa có hóa đơn, sửa giá thuê, ngày thu tiền, dịch vụ.
2. Lập hóa đơn tháng đầu.
3. Sau khi có hóa đơn, thử sửa lại giá thuê/dịch vụ.
4. Mở lại hóa đơn đã lập.

Kỳ vọng:

- Nếu cho sửa hợp đồng sau hóa đơn, hóa đơn cũ không bị đổi.
- Nếu không cho sửa sau hóa đơn, thông báo phải rõ lý do.
- Thông tin khách thuê không sửa trong hợp đồng nếu quy tắc là sửa ở màn khách thuê.

Điểm dễ bug:

- Sửa hợp đồng làm lệch công nợ.
- Dịch vụ trong hợp đồng và hóa đơn không đồng bộ.
- Hóa đơn thu trước đầu tháng bị chặn quá sớm khi cần sửa giá trước ngày thu tiền.

## Pha 7: Chốt điện nước

### TC-14: Chốt thủ công theo nhà/phòng

Thao tác:

1. Vào màn chốt điện nước thủ công.
2. Chọn `TEST_Nha_A`, chọn A101.
3. Chốt tháng đầu: điện `150`, nước `28`.
4. Mở lịch sử chốt.

Kỳ vọng:

- Tìm đúng hợp đồng active của A101.
- Kỳ trước lấy từ hợp đồng: điện `100`, nước `20`.
- Tiêu thụ điện `50`, nước `8`.
- Thông báo tiếng Việt đủ dấu.

Ca lỗi cần thử:

- Chọn phòng chưa có hợp đồng.
- Chọn nhà rồi đổi nhà khác, danh sách phòng phải reset đúng.
- Nhập chỉ số nhỏ hơn đầu kỳ.
- Nhập chữ/ký tự đặc biệt.
- Chốt trùng tháng.

### TC-15: Sửa/xóa chốt trước và sau hóa đơn

Thao tác:

1. Sửa chỉ số tháng đầu trước khi lập hóa đơn.
2. Xóa chốt trước khi lập hóa đơn nếu chức năng có.
3. Tạo lại chốt.
4. Lập hóa đơn.
5. Thử sửa/xóa chốt đã lên hóa đơn.

Kỳ vọng:

- Chốt chưa lên hóa đơn có thể sửa/xóa theo quyền.
- Chốt đã lên hóa đơn phải bị khóa hoặc yêu cầu xóa hóa đơn trước.
- Hóa đơn không giữ chỉ số cũ nếu chốt được sửa trước khi lập.

## Pha 8: Hóa đơn

### TC-16: Hóa đơn thu trước đầu tháng

Thao tác:

1. Lập hóa đơn tháng mới khi chưa chốt điện nước.
2. Chỉ tính tiền phòng + dịch vụ cố định nếu đó là quy tắc.
3. Đổi ngày thu tiền trong hợp đồng trước ngày 5.
4. Kiểm tra có thể sửa giá/dịch vụ trước khi thu không.

Kỳ vọng:

- Hóa đơn thu trước không bắt buộc phải có chốt điện nước nếu hệ thống thiết kế vậy.
- Nếu hóa đơn đã lập, sửa hợp đồng phải không làm đổi hóa đơn cũ.
- Nếu cần thay đổi hóa đơn, phải có luồng sửa/xóa/lập lại rõ ràng.

### TC-17: Hóa đơn sau chốt điện nước

Thao tác:

1. Chốt điện nước tháng 1.
2. Lập hóa đơn tháng 1.
3. Đối chiếu từng dòng: tiền phòng, điện, nước, Internet, Rác, phát sinh, giảm trừ.
4. Thử lập lại hóa đơn tháng 1.

Kỳ vọng:

- Tổng tiền đúng công thức.
- Không lập trùng hóa đơn cùng hợp đồng/tháng.
- Chi tiết hóa đơn có đủ tên phòng, khách thuê, tháng, trạng thái.

Ca lỗi cần thử:

- Dịch vụ bị thiếu hoặc nhân đôi.
- Sai tên cột phiếu thu/chi.
- Chọn tháng/năm khác làm hóa đơn gắn sai kỳ.
- Hóa đơn phòng A101 xuất hiện ở tenant B.

### TC-18: Thanh toán và xóa hóa đơn

Thao tác:

1. Đánh dấu hóa đơn pending thành paid.
2. Kiểm tra phiếu thu tự sinh.
3. Bấm paid lại lần nữa hoặc refresh rồi paid lại.
4. Xóa hóa đơn pending.
5. Thử xóa hóa đơn paid.

Kỳ vọng:

- Paid chỉ tạo một phiếu thu.
- Xóa pending cập nhật danh sách và công nợ.
- Xóa paid phải bị chặn hoặc xử lý phiếu thu liên quan rõ ràng.
- Tenant thấy trạng thái hóa đơn đổi đúng.

## Pha 9: Phiếu thu và phiếu chi

### TC-19: Phiếu thu thủ công

Thao tác:

1. Tạo phiếu thu thủ công cho A101.
2. Chọn khách thuê A, nhập số tiền, ngày thu, ghi chú `TEST_Thu_Manual`.
3. Mở danh sách và chi tiết phiếu thu.
4. Sửa phiếu thu nếu có.
5. Xóa phiếu thu thủ công.

Kỳ vọng:

- Tên cột đúng: người nộp, phòng, số tiền, ngày thu, nội dung.
- Số tiền không âm, không rỗng.
- Xóa phiếu thu thủ công không ảnh hưởng hóa đơn.

### TC-20: Phiếu chi

Thao tác:

1. Tạo phiếu chi `TEST_Chi_SuaDien`.
2. Nhập loại chi, số tiền, ngày chi, nhà/phòng liên quan nếu có.
3. Kiểm tra thống kê chi phí.
4. Sửa/xóa phiếu chi.

Kỳ vọng:

- Phiếu chi không xuất hiện nhầm ở danh sách phiếu thu.
- Thống kê cập nhật đúng khi tạo/sửa/xóa.
- Manager chỉ thấy phiếu chi trong phạm vi được phân quyền nếu có áp dụng.

## Pha 10: Kết thúc hợp đồng và hợp đồng mới

### TC-21: Kết thúc hợp đồng chưa có chốt cuối

Thao tác:

1. Kết thúc hợp đồng A101 ở ngày hiện tại.
2. Không nhập chốt điện nước cuối.
3. Kiểm tra trạng thái hợp đồng, phòng, tenant.
4. Thử lập hợp đồng mới cho A101.

Kỳ vọng:

- Hợp đồng cũ hết active.
- Phòng về trống/khả dụng.
- Tenant A không còn trạng thái đang thuê nếu không còn hợp đồng active.
- Hợp đồng mới không lấy sai điện/nước đầu kỳ.

### TC-22: Kết thúc hợp đồng đã chốt điện nước

Thao tác:

1. Chốt điện nước cuối kỳ: điện `210`, nước `35`.
2. Kết thúc hợp đồng.
3. Lập hợp đồng mới cho tenant B tại A101.
4. Kiểm tra điện/nước đầu kỳ hợp đồng mới.

Kỳ vọng:

- Điện đầu kỳ hợp đồng mới = `210`.
- Nước đầu kỳ hợp đồng mới = `35`.
- Tenant A không thấy hợp đồng/hóa đơn mới của tenant B.
- A101 không còn liên kết active với tenant A.

Ca lỗi cần thử:

- Kết thúc hợp đồng đã có hóa đơn pending.
- Kết thúc hợp đồng đã có hóa đơn paid.
- Kết thúc hợp đồng rồi bấm lại lần nữa.
- Lập hợp đồng mới ngay sau khi kết thúc không reload app.

## Pha 11: Tài khoản khách thuê và liên kết user-tenant

### TC-23: Đăng ký tài khoản khớp tenant có sẵn

Thao tác:

1. Tenant A đã tồn tại với SĐT `0910000001`.
2. Đăng ký tài khoản khách thuê bằng SĐT này.
3. Đăng nhập tenant A.
4. Mở trang nhà/phòng, hợp đồng, hóa đơn, cọc, sự cố.

Kỳ vọng:

- User mới liên kết đúng tenant A.
- Tenant A chỉ thấy dữ liệu của mình.
- Không thấy dữ liệu tenant B hoặc phòng B201.
- Nếu tenant A có hợp đồng ended, app hiển thị đúng lịch sử hoặc trạng thái không đang thuê theo thiết kế.

### TC-24: Đăng ký tài khoản không có tenant

Thao tác:

1. Đăng ký `guest_test` với SĐT không tồn tại trong tenants.
2. Đăng nhập.
3. Kiểm tra màn hình khách thuê.

Kỳ vọng:

- Không tự tạo tenant rác nếu hệ thống không thiết kế vậy.
- Hiển thị trạng thái chưa thuê/chưa liên kết rõ ràng.
- Không xem được dữ liệu chủ trọ.

### TC-25: Bảo vệ liên kết sai

Thao tác:

1. Tạo owner/manager có SĐT trùng một tenant inactive hoặc ended.
2. Đăng nhập owner/manager.
3. Kiểm tra bảng tenants nếu có thể, hoặc kiểm tra UI tenant.
4. Đổi SĐT tenant A sau khi user đã liên kết.

Kỳ vọng:

- Owner/manager không bị gán vào tenant.
- Tenant inactive/deleted không được liên kết như đang thuê.
- Đổi SĐT tenant phải có quy tắc rõ: giữ liên kết user cũ hoặc yêu cầu xác nhận.

## Pha 12: Sự cố, thông báo, chat, bài đăng

### TC-26: Khách thuê gửi sự cố

Thao tác:

1. Tenant A đăng nhập.
2. Gửi sự cố `TEST_SuCo_Dien`.
3. Đính kèm ảnh nếu có.
4. Chủ trọ đăng nhập xem danh sách sự cố.
5. Manager đăng nhập xem sự cố thuộc nhà được gán.
6. Cập nhật trạng thái xử lý.

Kỳ vọng:

- Sự cố gắn đúng tenant, phòng, hợp đồng active.
- Chủ trọ/manager nhận thông báo đúng.
- Tenant thấy trạng thái cập nhật.
- Manager không thấy sự cố của B201 nếu không có quyền.

### TC-27: Bài đăng và yêu cầu thuê

Thao tác:

1. Chủ trọ tạo bài đăng cho A102.
2. Guest xem bài đăng.
3. Guest gửi yêu cầu thuê/chat.
4. Chủ trọ trả lời hoặc chuyển trạng thái yêu cầu.
5. Đóng/xóa bài đăng.

Kỳ vọng:

- Bài đăng hiển thị đúng ảnh, giá, địa chỉ, tiện ích.
- Phòng đang thuê không nên đăng như còn trống.
- Bài đăng đã đóng không nhận yêu cầu mới.
- Chat/yêu cầu không lẫn giữa các bài đăng.

## Pha 13: Thống kê và đối chiếu dữ liệu

### TC-28: Thống kê chủ trọ

Thao tác:

1. Có một hóa đơn paid, một hóa đơn pending, một phiếu chi.
2. Mở dashboard/thống kê.
3. Ghi lại doanh thu, công nợ, chi phí, phòng trống, phòng đang thuê.
4. Xóa/sửa một phiếu thu/chi test.
5. Reload thống kê.

Kỳ vọng:

- Doanh thu không đếm pending nếu quy tắc chỉ tính paid.
- Công nợ gồm pending.
- Chi phí cập nhật sau khi sửa/xóa phiếu chi.
- Không đếm trùng phiếu thu sinh từ hóa đơn.

### TC-29: Thống kê manager

Thao tác:

1. Manager mở dashboard.
2. So sánh với chủ trọ.
3. Tạo dữ liệu ở `TEST_Nha_B`.
4. Reload dashboard manager.

Kỳ vọng:

- Manager chỉ thấy số liệu trong `TEST_Nha_A`.
- Dữ liệu `TEST_Nha_B` không làm thay đổi thống kê manager.

## Pha 14: Checklist xóa và bảo toàn dữ liệu

### TC-30: Xóa theo thứ tự an toàn

Thao tác:

1. Xóa/đóng bài đăng test.
2. Xóa sự cố test nếu chức năng cho phép.
3. Xóa hóa đơn pending test.
4. Với hóa đơn paid, kiểm tra quy tắc trước khi xóa.
5. Xóa phiếu thu/chi thủ công.
6. Kết thúc hoặc xóa hợp đồng test theo đúng luồng.
7. Xóa tenant không còn hợp đồng active.
8. Xóa phòng trống.
9. Xóa nhà không còn phòng.
10. Xóa manager/guest test nếu chức năng có.

Kỳ vọng:

- Không còn dữ liệu `TEST_` trong danh sách.
- Không còn phòng trạng thái đang thuê nhưng không có hợp đồng active.
- Không còn hợp đồng active thiếu tenant hoặc room.
- Không còn hóa đơn thiếu contract/room/tenant.
- Không còn phiếu thu liên kết hóa đơn đã bị xóa.

### TC-31: Thử xóa sai thứ tự để kiểm tra bảo vệ

Thao tác:

1. Thử xóa nhà khi còn phòng.
2. Thử xóa phòng khi còn hợp đồng active.
3. Thử xóa tenant đại diện khi còn hợp đồng active.
4. Thử xóa hợp đồng khi còn hóa đơn.
5. Thử xóa dịch vụ đã phát sinh hóa đơn.

Kỳ vọng:

- Hệ thống chặn bằng thông báo rõ ràng.
- Không xóa nửa vời làm mất quan hệ dữ liệu.
- Sau khi bị chặn, danh sách vẫn reload bình thường.

## Pha 15: Test hồi quy nhanh sau mỗi lần sửa bug

Chạy nhanh các case này sau khi sửa bất kỳ bug nào liên quan hợp đồng/hóa đơn:

- TC-12: Lập hợp đồng mới.
- TC-14: Chốt điện nước thủ công.
- TC-17: Lập hóa đơn sau chốt.
- TC-18: Đánh dấu paid và kiểm tra phiếu thu.
- TC-22: Kết thúc hợp đồng và lập hợp đồng mới.
- TC-23: Tenant đăng nhập chỉ thấy dữ liệu của mình.
- TC-30: Dọn dữ liệu test.

Nếu sửa phần phân quyền, chạy thêm:

- TC-02: Quyền manager.
- TC-29: Thống kê manager.

Nếu sửa phần dịch vụ, chạy thêm:

- TC-06: Tạo/sửa dịch vụ.
- TC-07: Dịch vụ trong hợp đồng và hóa đơn.

## Bảng đối chiếu nhanh các quan hệ dễ lỗi

| Quan hệ | Cần đúng |
|---|---|
| `house -> room` | Phòng thuộc đúng nhà, manager chỉ thấy nhà được gán |
| `room -> active contract` | Một phòng chỉ có tối đa một hợp đồng active |
| `contract -> tenant` | Hợp đồng gắn đúng tenant đại diện |
| `tenant -> user` | Chỉ khách thuê đúng SĐT/trạng thái được liên kết |
| `contract -> meter` | Chốt điện nước gắn đúng hợp đồng active tại thời điểm chốt |
| `meter -> invoice` | Chốt đã lên hóa đơn không bị sửa/xóa tùy tiện |
| `contract -> invoice` | Không lập trùng hóa đơn cùng hợp đồng/tháng |
| `invoice -> receipt` | Paid tạo đúng một phiếu thu |
| `service -> invoice detail` | Hóa đơn cũ không đổi khi sửa giá dịch vụ |
| `ended contract -> new contract` | Hợp đồng mới lấy đúng điện/nước đầu kỳ và không lộ cho tenant cũ |
