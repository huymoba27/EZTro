# Kich ban test luong dang ky va lien ket tai khoan khach thue

Muc tieu: kiem tra toan bo luong khach thue tu luc dang ky tai khoan den khi duoc lien ket voi ban ghi `tenants`, dang nhap, xem du lieu lien quan va tranh bi lien ket nham.

Pham vi chinh:
- Dang ky tai khoan moi cua khach thue.
- Tu dong lien ket tai khoan voi khach thue da duoc chu tro tao truoc.
- Dang nhap va tu sua lien ket neu truoc do chua co `user_id`.
- Kiem tra quyen xem hop dong, hoa don, coc, su co theo khach thue.
- Kiem tra cac case am: so dien thoai trung, tenant inactive, tenant da co user, trung so voi landlord/manager.

Du lieu nen chuan bi
--------------------

1. Chu tro A:
   - `landlord_user_id = L1`
   - Co nha `H1`, phong `R1`, hop dong active `C1`.

2. Khach thue da tao thu cong:
   - `tenant_name = Nguyen Van Test`
   - `phone = 0900000001`
   - `status = active`
   - `deleted_at = NULL`
   - `user_id = NULL`
   - Dang o phong `R1`.

3. Khach thue inactive cu:
   - `phone = 0900000002`
   - `status = inactive`
   - Hoac `deleted_at IS NOT NULL`.

4. Khach thue da lien ket user:
   - `phone = 0900000003`
   - `status = active`
   - `user_id = U_EXISTING`.

5. Tai khoan landlord/manager co so dien thoai rieng:
   - Landlord/manager phone: `0900000004`.

6. Hoa don va coc lien quan:
   - Hoa don pending cho hop dong `C1`.
   - Mot su co do khach thue phong `R1` tao.

TC01 - Dang ky tai khoan khach thue moi, chua co ban ghi tenant
----------------------------------------------------------------

Dieu kien truoc:
- Khong co ban ghi `tenants.phone = 0911111111`.
- Khong co `users.phone = 0911111111`.

Buoc test:
1. Mo man dang ky.
2. Nhap username moi, mat khau, ho ten, so dien thoai `0911111111`.
3. Bam dang ky.

Ket qua mong doi:
- Tao thanh cong user moi.
- `users.role = unassigned`.
- Response co `is_renting = false`.
- Response co `room_id = null`.
- Khach thue khong thay menu/du lieu phong thue.

TC02 - Dang ky bang so dien thoai cua tenant active chua co user_id
-------------------------------------------------------------------

Dieu kien truoc:
- Ton tai tenant active phone `0900000001`.
- Tenant nay `user_id IS NULL`.

Buoc test:
1. Dang ky tai khoan moi bang phone `0900000001`.
2. Dang ky thanh cong.
3. Kiem tra database bang `tenants`.
4. Dang nhap bang tai khoan vua tao.

Ket qua mong doi:
- User duoc tao voi `role = tenant`.
- Chi tenant active dung so dien thoai duoc cap nhat `user_id = user moi`.
- Response dang ky co `is_renting = true`.
- Response co `room_id = R1`.
- `full_name` tra ve uu tien ten trong bang `tenants` neu co.
- Sau dang nhap, user thay du lieu phong dang thue.

TC03 - Dang ky bang so dien thoai cua tenant inactive/deleted
-------------------------------------------------------------

Dieu kien truoc:
- Co tenant phone `0900000002` nhung `status = inactive` hoac `deleted_at IS NOT NULL`.
- Chua co user phone `0900000002`.

Buoc test:
1. Dang ky tai khoan bang phone `0900000002`.
2. Kiem tra response va database.

Ket qua mong doi:
- Dang ky thanh cong.
- User moi co `role = unassigned`, khong phai `tenant`.
- Khong cap nhat `tenants.user_id` cho ban ghi inactive/deleted.
- `is_renting = false`.
- `room_id = null`.

TC04 - Dang ky bang so dien thoai tenant da co user_id
------------------------------------------------------

Dieu kien truoc:
- Co tenant active phone `0900000003`.
- Tenant nay da co `user_id = U_EXISTING`.
- Chua co user moi cung phone vi he thong dang chan trung phone.

Buoc test:
1. Thu dang ky tai khoan moi bang phone `0900000003`.

Ket qua mong doi:
- Dang ky bi tu choi vi so dien thoai da ton tai trong `users`.
- Khong thay doi `tenants.user_id`.
- User cu van dang nhap va xem du lieu binh thuong.

TC05 - Dang nhap tai khoan unassigned, phone trung tenant active chua link
--------------------------------------------------------------------------

Dieu kien truoc:
- Co user `U_NEW` role `unassigned`, phone `0900000001`.
- Co tenant active phone `0900000001`, `user_id IS NULL`.

Buoc test:
1. Dang nhap bang user `U_NEW`.
2. Kiem tra database `tenants`.
3. Kiem tra response dang nhap.

Ket qua mong doi:
- He thong tu repair lien ket: tenant `user_id = U_NEW`.
- Neu user role dang `unassigned`, cap nhat thanh `tenant`.
- Response co `role = tenant`.
- Response co `is_renting = true`, `room_id = R1`.

TC06 - Dang nhap landlord/manager co phone trung tenant chua link
-----------------------------------------------------------------

Dieu kien truoc:
- Co user role `landlord` hoac `manager`, phone `0900000004`.
- Co tenant active phone `0900000004`, `user_id IS NULL`.

Buoc test:
1. Dang nhap bang tai khoan landlord/manager.
2. Kiem tra tenant phone `0900000004`.

Ket qua mong doi:
- Dang nhap thanh cong theo role goc.
- Khong auto link tenant voi landlord/manager.
- Khong doi role landlord/manager thanh tenant.
- `tenants.user_id` van `NULL`.

TC07 - Tao hop dong cho khach co phone trung user tenant/unassigned
-------------------------------------------------------------------

Dieu kien truoc:
- Co user phone `0900000005`, role `unassigned`.
- Phong `R2` con trong.

Buoc test:
1. Chu tro tao hop dong moi cho khach phone `0900000005`.
2. Kiem tra tenant va user.

Ket qua mong doi:
- Tenant moi duoc tao va gan `user_id` cua user `0900000005`.
- User duoc cap role `tenant` neu dang `unassigned`.
- Hop dong dung `tenant_id` cua ban ghi tenant, khong dung `users.id`.

TC08 - Tao hop dong cho khach co phone trung landlord/manager
-------------------------------------------------------------

Dieu kien truoc:
- Co user phone `0900000004`, role `landlord` hoac `manager`.
- Phong `R3` con trong.

Buoc test:
1. Tao hop dong cho khach phone `0900000004`.
2. Kiem tra tenant moi.

Ket qua mong doi:
- Khong gan `user_id` cua landlord/manager vao tenant.
- Khong doi role landlord/manager.
- Tenant moi co `user_id = 0` hoac `NULL` tuy schema hien tai.
- Khach thue can dang ky bang so khac hoac xu ly du lieu trung phone thu cong.

TC09 - Sua thong tin khach thue doi so dien thoai khong co user tuong ung
-------------------------------------------------------------------------

Dieu kien truoc:
- Tenant active da co `user_id = U1`.
- Sua phone sang `0900000099`, chua co user nao phone nay.

Buoc test:
1. Chu tro/su dung form sua khach thue doi so dien thoai.
2. Luu.
3. Kiem tra tenant.

Ket qua mong doi:
- Cap nhat phone thanh cong.
- `user_id` cu van duoc giu, khong bi set ve `NULL`.
- User cu van xem duoc du lieu theo `user_id`.

TC10 - Sua thong tin khach thue doi sang phone cua user tenant/unassigned
-------------------------------------------------------------------------

Dieu kien truoc:
- Tenant active `T1`.
- Co user `U2` role `unassigned` hoac `tenant`, phone `0900000088`.

Buoc test:
1. Sua phone tenant `T1` thanh `0900000088`.
2. Luu.

Ket qua mong doi:
- Tenant `T1.user_id = U2`.
- Neu `U2.role = unassigned`, cap nhat thanh `tenant`.
- Khong link voi user co role landlord/manager.

TC11 - Khach thue xem danh sach hop dong sau khi link
-----------------------------------------------------

Dieu kien truoc:
- User tenant da link voi tenant active cua phong `R1`.
- Phong `R1` co hop dong active `C1`.

Buoc test:
1. Dang nhap khach thue.
2. Vao man hop dong.
3. Goi API danh sach/chi tiet hop dong voi `user_id` cua tenant.

Ket qua mong doi:
- Chi thay hop dong lien quan den tenant/room cua minh.
- Khong thay hop dong cua phong/nha khac.
- Neu sua request `managed_house_id` hoac `role`, backend van khong tra du lieu ngoai quyen.

TC12 - Khach thue xem hoa don sau khi link
------------------------------------------

Dieu kien truoc:
- User tenant da link.
- Hop dong `C1` co hoa don thang hien tai.

Buoc test:
1. Dang nhap khach thue.
2. Vao man hoa don.
3. Mo chi tiet hoa don.

Ket qua mong doi:
- Chi thay hoa don cua hop dong/phong dang thue.
- Trang thai hoa don dung: `pending`, `paid`, `bad_debt`...
- Khong thay hoa don phong khac du neu sua tham so `room_id`.

TC13 - Khach thue tao thanh toan PayOS cho hoa don cua minh
-----------------------------------------------------------

Dieu kien truoc:
- Hoa don `I1` cua tenant dang `pending`.
- User tenant da link voi hop dong cua hoa don.

Buoc test:
1. Khach thue bam thanh toan PayOS.
2. Tao payment link.

Ket qua mong doi:
- Tao link thanh cong cho hoa don cua minh.
- Neu gui `invoice_id` cua phong khac, API tra loi khong co quyen hoac khong tim thay hoa don.

TC14 - Khach thue xem coc theo user_id va phone
-----------------------------------------------

Dieu kien truoc:
- Co phieu coc online/manual lien quan phone cua user tenant.
- Co phieu coc cua user khac cung phone cu hoac da gan `user_id` khac.

Buoc test:
1. Dang nhap tenant.
2. Vao man coc.
3. Kiem tra danh sach.

Ket qua mong doi:
- Thay coc co `user_id = current_user`.
- Co the thay coc manual chua gan `user_id` neu `customer_phone` trung phone current user.
- Khong thay coc da gan `user_id` cua user khac.

TC15 - Khach thue bao su co sau khi link
----------------------------------------

Dieu kien truoc:
- User tenant da link voi tenant active phong `R1`.

Buoc test:
1. Khach thue tao su co cho phong dang thue.
2. Kiem tra bang `incidents`.
3. Kiem tra thong bao gui cho chu tro.

Ket qua mong doi:
- Incident duoc tao voi `tenant_id` dung cua khach thue.
- `landlord_id` tra ve dung chu tro cua nha.
- Thong bao gui ve chu tro cua nha do, khong hard-code user id.

TC16 - Khach thue khong duoc xem/sua du lieu phong khac
-------------------------------------------------------

Dieu kien truoc:
- User tenant o phong `R1`.
- Co phong `R_OTHER`, hoa don/hop dong/su co khac.

Buoc test:
1. Goi API hop dong/hoa don/su co voi id phong khac bang user tenant.
2. Thu sua request `role=admin` hoac `role=manager`.

Ket qua mong doi:
- Backend van lay role that tu DB.
- Khong tra ve du lieu ngoai pham vi tenant.
- Cac response phu hop: `data=[]`, `not found`, hoac `khong co quyen`.

TC17 - So dien thoai trung nhieu tenant active
----------------------------------------------

Dieu kien truoc:
- Co 2 tenant active cung phone `0900000077`, ca hai `user_id IS NULL`.

Buoc test:
1. Dang ky user moi bang phone `0900000077`.
2. Kiem tra tenant nao duoc link.

Ket qua mong doi hien tai:
- He thong link ban ghi active moi nhat theo `ORDER BY id DESC LIMIT 1`.
- Chi mot tenant duoc set `user_id`.

Ghi chu danh gia:
- Day la case can canh bao nghiep vu. Tot nhat nen co rule khong cho tao 2 tenant active cung phone neu chua co ly do ro rang.

TC18 - Doi phone user sau khi da link tenant
--------------------------------------------

Dieu kien truoc:
- User tenant `U1` da link voi `tenant.user_id = U1`.

Buoc test:
1. Doi phone cua user trong bang `users` hoac qua chuc nang profile neu co.
2. Dang nhap lai.
3. Vao hop dong/hoa don.

Ket qua mong doi:
- Du lieu van xem duoc theo `tenant.user_id`.
- Khong phu thuoc vao phone fallback.
- Khong link nham sang tenant khac co phone moi.

TC19 - Thanh ly hop dong va dang nhap lai tenant cu
---------------------------------------------------

Dieu kien truoc:
- User tenant dang o phong `R1`.
- Hop dong `C1` duoc thanh ly.
- Tenant status chuyen inactive.

Buoc test:
1. Dang nhap lai bang user tenant cu.
2. Kiem tra response dang nhap va du lieu.

Ket qua mong doi:
- User van dang nhap duoc.
- `is_renting = false` neu khong con tenant active nao lien ket.
- Khong xem duoc hoa don/hop dong active moi cua phong neu da co khach moi.
- Lich su cu neu co hien thi thi phai theo rule san pham, khong lay nham hop dong moi.

TC20 - Lap hop dong moi cung phong cho khach moi sau khi tenant cu inactive
---------------------------------------------------------------------------

Dieu kien truoc:
- Hop dong cu da thanh ly.
- Tenant cu inactive, user cu van ton tai.
- Chu tro tao hop dong moi cho khach khac.

Buoc test:
1. Tao hop dong moi cho phone khac.
2. Dang nhap user cu.
3. Dang nhap user moi.

Ket qua mong doi:
- User cu khong thay du lieu hop dong moi.
- User moi duoc link dung tenant moi neu dang ky bang phone moi.
- Dien nuoc dau ky/hop dong/hoa don khong bi lay nham theo tenant cu.

Checklist can doi chieu trong database
--------------------------------------

- `users.role` sau dang ky/dang nhap.
- `users.phone` co trung khong.
- `tenants.user_id` co dung user khong.
- `tenants.status`, `tenants.deleted_at`.
- `contracts.tenant_id` phai la `tenants.id`, khong phai `users.id`.
- Hoa don tenant xem duoc phai join ve dung contract/room.
- Cac API tenant scope khong chi dua vao phone neu tenant da co `user_id` khac.

Uu tien auto test truoc
-----------------------

1. TC02: dang ky va link tenant active chua co user.
2. TC05: dang nhap repair link.
3. TC06: khong link nham landlord/manager.
4. TC11 + TC12: tenant chi xem hop dong/hoa don cua minh.
5. TC13: khong thanh toan PayOS hoa don cua phong khac.
6. TC19 + TC20: tenant cu sau thanh ly khong thay du lieu hop dong moi.
