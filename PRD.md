# Hệ Thống Quản Lý Thư Viện Mượn Trả Sách

---

## PHẦN 1: TỔNG QUAN DỰ ÁN

### 1.1 Tổng quan dự án
Xây dựng một hệ thống quản lý thư viện hiện đại giúp các nhân viên và độc giả dễ dàng mượn, trả sách, cập nhật tình trạng tập sách một cách nhanh chóng, minh bạch, tránh thất thoát tài sản và nợ quá hạn.
Phần mềm quản lý thư viện web-based cho phép:
- **Độc giả** có thể tìm kiếm, xem thông tin sách, mượn, trả sách trực tuyến
- **Nhân viên thư viện** quản lý kho sách, xác nhận mượn/trả, theo dõi các khoản phạt
- **Quản lý viên** xem báo cáo thống kê, quản lý tài khoản người dùng

### 1.2 Đối tượng sử dụng
- **Độc giả (Readers)**: Mượn sách, kiểm tra trạng thái mượn, gia hạn sách, thanh toán các khoản phạt
- **Nhân viên (Librarians)**: Quản lý kho sách, xác nhận giao/nhận sách, theo dõi tình trạng sách, theo dõi các khoản phạt
- **Quản lý viên (Admin)**: Quản lý tài khoản, báo cáo thống kê, cài đặt hệ thống

---

## PHẦN 2: YÊU CẦU CHỨC NĂNG

### 2.1 Quản lý Tài Khoản

#### 2.1.1 Đăng Ký
**Actor:** Mọi người  
**Yêu cầu:** Không có

**Flow:**
1. Click "Đăng ký"
2. Nhập: Email, Tên, Mật khẩu, Confirm mật khẩu
3. Hệ thống tạo tài khoản với trạng thái "Chờ xác nhận"

**Validation Rules:**
- Email: Định dạng email hợp lệ
- Tên: Không được để trống, tối đa 50 ký tự
- Mật khẩu: Không được để trống, tối thiểu 8 ký tự, tối đa 16 ký tự
- Confirm mật khẩu: Không được để trống, phải trùng với mật khẩu

#### 2.1.2 Đăng Nhập (Login)
**Actor:** Mọi người  
**Yêu cầu:** Không có

**Flow:**
1. Nhập Email & Mật khẩu
2. Hệ thống xác thực
3. Tạo session (JWT token, thời hạn 24h)
4. Chuyển hướng tới dashboard của độc giả hoặc nhân viên thư viện

**Validation Rules:**
- Email: Định dạng email hợp lệ
- Mật khẩu: Không được để trống, tối thiểu 8 ký tự, tối đa 16 ký tự

#### 2.1.3 Hồ Sơ Cá Nhân
**Actor:** Độc giả  
**Yêu cầu:** Login vào hệ thống với vai trò độc giả

**Thông tin hiển thị:**
- Tên, Email, Số điện thoại, Địa chỉ
- Ngày tham gia, Số lần mượn, Tổng số tiền phạt

**Chức năng:**
- Cập nhật thông tin cá nhân
- Thay đổi mật khẩu

**Validation Rules:**
- Tên: Không được để trống, tối đa 50 ký tự
- Số điện thoại: Định dạng số điện thoại hợp lệ
- Địa chỉ: Không được để trống, tối đa 255 ký tự

---

### 2.2 Quản lý Sách

#### 2.2.1 Quản lý thể loại sách
**Actor:** Nhân viên thư viện
**Yêu cầu:** Login vào hệ thống với vai trò nhân viên thư viện

**Flow:**
1. Nhân viên thư viện xem danh sách các thể loại sách ở dạng bảng, có thể sửa trực tiếp trên bảng.
2. Nhân viên thư viện thêm thể loại sách mới bằng cách click "Thêm thể loại sách" và nhập tên thể loại sách.
3. Nhân viên thư viện xóa thể loại sách bằng cách click "Xóa" trên bảng nếu không có sách nào thuộc thể loại đó. Xác nhận lại mới xóa.

**Validation Rules:**
- Tên thể loại: Không được để trống, tối đa 50 ký tự

#### 2.2.2 Thêm Sách Mới
**Actor:** Nhân viên thư viện  
**Yêu cầu:** Login vào hệ thống với vai trò nhân viên thư viện

**Flow:**
1. Nhân viên click "Thêm Sách Mới"
2. Nhập: Tên sách, Tác giả, Năm xuất bản, ISBN, Thể loại, Mô tả, Số lượng bản sách
3. Hệ thống lưu sách vào database với trạng thái "Có sẵn"
4. Hiện thông báo "Thêm sách thành công"

**Validation Rules:**
- Tên sách: Không được để trống, tối đa 100 ký tự
- ISBN: Định dạng chuẩn ISBN-10 hoặc ISBN-13 (nếu có)
- Số lượng: Phải > 0, kiểu số
- Năm xuất bản: Năm hợp lệ (1900 - năm hiện tại)
- Thể loại: Phải có thể loại sách
- Mô tả: Không được để trống, tối đa 255 ký tự
- Tác giả: Không được để trống, tối đa 100 ký tự



#### 2.2.3 Xem Danh Sách Sách
**Actor:** Tất cả người dùng (không cần login)
**Hiển thị thông tin:**
- Tên sách, Tác giả, Năm xuất bản, Thể loại, Số lượng có sẵn, Số lượng đang mượn

**Chức năng tìm kiếm & lọc:**
- Tìm kiếm theo tên sách hoặc tác giả
- Lọc theo thể loại
- Sắp xếp: Tên (A-Z), Năm xuất bản (Mới nhất), Lượt mượn (Phổ biến nhất)
- Phân trang: 10 sách trên 1 trang

#### 2.2.4 Xem Chi Tiết Sách
**Actor:** Tất cả người dùng (không cần login)
**Hiển thị:**
- Tên, Tác giả, ISBN, Năm xuất bản, Mô tả chi tiết
- Số lượng bản đang có, đang mượn
- Lịch sử mượn (Độc giả, Ngày mượn, Ngày hết hạn: Nếu là nhân viên thư viện thì hiển thị)

**Thao tác:** Độc giả có thể nhấn "Mượn sách" tại đây

#### 2.2.5 Sửa & Xóa Sách
**Actor:** Nhân viên thư viện
**Yêu cầu:** Login vào hệ thống với vai trò nhân viên thư viện

**Flow sửa:**
- Xem chi tiết sách
- Click "Sửa" → Chỉnh sửa thông tin → Lưu
**Flow xóa:**
- Xem chi tiết sách
- Click "Xóa" → Xác nhận → Xóa (nếu không có đơn mượn hoạt động)

---

### 2.3 Quản lý Mượn Sách

#### 2.3.1 Mượn Sách (Độc Giả)
**Actor:** Độc giả  
**Yêu cầu:** Login vào hệ thống với vai trò độc giả

**Điều kiện:**
- Sách còn sẵn (số lượng > 0)
- Độc giả không vượt quá số sách mượn tối đa (mặc định 5 cuốn)
- Không có khoản phạt chưa thanh toán

**Flow:**
1. Độc giả xem chi tiết sách
2. Click "Mượn Sách"
3. Chọn thời hạn mượn (mặc định 14 ngày, tối đa 30 ngày)
4. Hệ thống tạo đơn mượn ở trạng thái "Chờ xác nhận"

#### 2.3.2 Mượn Sách (Nhân Viên Thư Viện)
**Actor:** Nhân viên thư viện
**Yêu cầu:** Login vào hệ thống với vai trò nhân viên thư viện

**Flow:**
1. Nhân viên thư viện xem danh sách sách mượn chờ xác nhận
2. Nhân viên thư viện có 2 lựa chọn:
   - **Xác nhận:** Click "Xác nhận" → Hệ thống cập nhật trạng thái đơn mượn thành "Đã mượn" và giảm số lượng sách có sẵn
   - **Từ chối:** Click "Từ chối" → Nhập lý do từ chối (bắt buộc) → Hệ thống cập nhật trạng thái thành "Bị từ chối" và lưu lý do


#### 2.3.3 Xem Lịch Sử Mượn Sách (Độc Giả)
**Actor:** Độc giả  
**Yêu cầu:** Login vào hệ thống với vai trò độc giả

**Hiển thị:**
- Danh sách sách đang mượn (Tên, Tác giả, Ngày mượn, Hạn trả, Số ngày còn lại)
- Danh sách sách đã trả (Tên, Ngày mượn, Ngày trả)
- Danh sách sách bị từ chối (Tên, Tác giả, Lý do từ chối)
- Trạng thái: "Chờ xác nhận", "Đang mượn", "Quá hạn", "Đã trả", "Bị từ chối"

**Chức năng:**
- Lọc theo trạng thái
- Xem lý do từ chối (nếu có)
- Tạo yêu cầu trả sách (cho sách đang mượn)

**Chức năng gia hạn:**
- Nếu chưa hết hạn, có nút "Gia hạn" (+7 ngày, tối đa gia hạn 1 lần)

---

### 2.4 Trả Sách

#### 2.4.1 Yêu Cầu Trả Sách
**Actor:** Độc giả
**Yêu cầu:** Login vào hệ thống với vai trò độc giả

**Flow:**
1. Độc giả vào trang "Lịch sử mượn sách"
2. Xem danh sách sách đang mượn
3. Click "Xin trả sách" trên sách muốn trả
4. Xác nhận trong modal
5. Hệ thống tạo yêu cầu trả sách ở trạng thái "Chờ xác nhận"

**Lưu ý:** 
- Độc giả cần mang sách đến thư viện để nhân viên xác nhận
- Một đơn mượn chỉ có thể tạo một yêu cầu trả ở trạng thái "Chờ xác nhận"

#### 2.4.2 Xác Nhận Trả Sách
**Actor:** Nhân viên  
**Yêu cầu:** Login vào hệ thống với vai trò nhân viên thư viện

**Flow:**
1. Nhân viên vào trang "Quản lý mượn trả" → Tab "Chờ xác nhận trả"
2. Xem danh sách yêu cầu trả sách chờ xác nhận
3. Nhận sách vật lý từ độc giả
4. Click "Xác nhận trả" và kiểm tra tình trạng sách:
   - **Bình thường:** Chọn "Bình thường", xác nhận trả. Cập nhật đơn mượn thành "Đã trả", tăng sách có sẵn, giảm sách đang mượn.
   - **Hư hỏng:** Chọn "Hư hỏng", chọn mức phạt & nhập ghi chú. Nếu muộn thì thêm phiếu phạt "Trả muộn". Tạo phiếu phạt cho hư hỏng và trả muộn (nếu có). Đơn thành "Đã trả".
   - **Mất:** Chọn "Mất", chọn mức phạt & ghi chú. Đơn thành "Đã trả".

**Chọn mức phạt:**
- Khi sách hư hỏng hoặc mất, nhân viên phải chọn một mức phạt từ danh sách các mức phạt đã được quản lý viên cấu hình

**Validation Rules:**
- Tình trạng sách: Bắt buộc chọn (bình thường, hư hỏng, mất)
- Mức phạt: Bắt buộc khi tình trạng là "hư hỏng", trả muộn hoặc "mất"
- Ghi chú: Bắt buộc khi tình trạng là "hư hỏng", hoặc "mất", tối đa 500 ký tự

---

### 2.5 Quản lý Nợ & Phạt

#### 2.5.1 Quản lý mức phạt
**Actor:** Quản lý viên
**Yêu cầu:** Login vào hệ thống với vai trò quản lý viên

**Flow:**
1. Quản lý viên xem danh sách các mức phạt ở dạng bảng, có thể sửa trực tiếp trên bảng.
2. Quản lý viên thêm mức phạt mới bằng cách click "Thêm mức phạt" và nhập thông tin mức phạt.
3. Quản lý viên xóa mức phạt bằng cách click "Xóa" trên bảng.

**Validation Rules:**
- Tên mức phạt: Không được để trống, tối đa 25 ký tự
- Số tiền: Phải > 0, kiểu số
- Ngày phạt: Ngày hợp lệ (mặc định là ngày hiện tại)

#### 2.5.2 Xem & Thanh Toán Khoản Phạt (Độc Giả)
**Actor:** Độc giả  
**Yêu cầu:** Login vào hệ thống với vai trò độc giả

**Hiển thị:**
- Danh sách khoản phạt chưa thanh toán
- Nguyên nhân phạt, Số tiền, Ngày phạt, Trạng thái

**Thanh toán:**
- Độc giả chọn phiếu phạt ở trạng thái "Chưa thanh toán" rồi thanh toán bằng chuyển khoản qua ngân hàng và nhấn "Đã thanh toán" chờ nhân viên thư viện xác nhận. Phiếu phạt sẽ hiển thị trạng thái "Chờ xác nhận".

#### 2.5.3 Xem & Thanh Toán Khoản Phạt (Nhân Viên Thư Viện)
**Actor:** Nhân viên thư viện
**Yêu cầu:** Login vào hệ thống với vai trò nhân viên thư viện

**Flow:**
1. Nhân viên thư viện xem danh sách khoản phạt chưa thanh toán
2. Nhân viên thư viện xem chi tiết khoản phạt
3. Nhân viên thư viện xác nhận thanh toán bằng cách nhấn "Đã thanh toán" hoặc từ chối nếu số tiền không phù hợp. Phiếu phạt sẽ hiển thị trạng thái "Từ chối" kèm theo lý do từ chối.

---

### 2.6 Quản lý Người Dùng

#### 2.6.1 Danh Sách Người Dùng
**Actor:** Quản lý viên  
**Yêu cầu:** Login vào hệ thống với vai trò quản lý viên

**Hiển thị:**
- Email, Tên, Vai trò (Reader/Librarian/Admin), Ngày tham gia, Trạng thái (Kích hoạt/Vô hiệu hóa)

**Chức năng:**
- Tìm kiếm theo email/tên
- Lọc theo vai trò
- Vô hiệu hóa/Kích hoạt tài khoản

#### 2.6.2 Gán Vai Trò
**Actor:** Quản lý viên  
**Yêu cầu:** Login vào hệ thống với vai trò quản lý viên

**Vai trò trong hệ thống:**
- **Reader:** Chỉ có thể mượn sách, xem lịch sử cá nhân
- **Librarian:** Có thể quản lý sách, xác nhận mượn/trả, theo dõi phạt
- **Admin:** Toàn quyền, quản lý tài khoản, báo cáo, cài đặt

---

### 2.7 Báo Cáo & Thống Kê

#### 2.7.1 Báo Cáo Tổng Quan (Dashboard)
**Actor:** Quản lý viên, Nhân viên  
**Yêu cầu:** Login vào hệ thống với vai trò quản lý viên hoặc nhân viên thư viện

**Hiển thị:**
- Tổng số sách: Có sẵn / Đang mượn / Bị mất / Hư hỏng
- Tổng số độc giả: Hoạt động / Vô hiệu hóa
- Tổng đơn mượn hôm nay
- Top 5 sách phổ biến nhất
- Danh sách độc giả nợ quá hạn

#### 2.7.2 Báo Cáo Chi Tiết
**Actor:** Quản lý viên, Nhân viên thư viện
**Yêu cầu:** Login vào hệ thống với vai trò quản lý viên hoặc nhân viên thư viện

**Các báo cáo có sẵn:**
1. **Báo cáo Sách:** Tổng số sách, tình trạng, số lần mượn
2. **Báo cáo Mượn Trả:** Số lần mượn/trả theo ngày/tháng/quý
3. **Báo cáo Phạt:** Tổng doanh thu phạt, người nợ ngoài hạn
4. **Báo cáo Sách Mất/Hư:** Danh sách sách cần thay thế

**Tính năng:**
- Xuất báo cáo ra CSV
- Lọc theo khoảng thời gian (Ngày, Tuần, Tháng, Quý, Năm)

## PHẦN 3: BẢNG PHỤ THUỘC

Bảng dưới đây mô tả các phụ thuộc giữa các tính năng. Tính năng ở cột "Tính năng" phụ thuộc vào các tính năng được liệt kê trong cột "Phụ thuộc vào".

| STT | Tính năng | Mã số | Phụ thuộc vào | Ghi chú | Trạng thái |
|-----|-----------|-------|---------------|---------|------------|
| 1 | Đăng Ký | 2.1.1 | - | Tính năng cơ bản, không phụ thuộc | ⬜ Chưa làm |
| 2 | Đăng Nhập (Login) | 2.1.2 | 2.1.1 | Cần có tài khoản để đăng nhập | ⬜ Chưa làm |
| 3 | Hồ Sơ Cá Nhân | 2.1.3 | 2.1.2 | Cần đăng nhập để xem hồ sơ | ⬜ Chưa làm |
| 4 | Quản lý thể loại sách | 2.2.1 | 2.1.2 | Cần đăng nhập với vai trò nhân viên | ⬜ Chưa làm |
| 5 | Thêm Sách Mới | 2.2.2 | 2.1.2, 2.2.1 | Cần đăng nhập và có thể loại sách | ⬜ Chưa làm |
| 6 | Xem Danh Sách Sách | 2.2.3 | - | Không cần đăng nhập, có thể làm song song | ⬜ Chưa làm |
| 7 | Xem Chi Tiết Sách | 2.2.4 | 2.2.3 | Cần có danh sách sách trước | ⬜ Chưa làm |
| 8 | Sửa & Xóa Sách | 2.2.5 | 2.1.2, 2.2.4 | Cần đăng nhập và xem chi tiết sách | ⬜ Chưa làm |
| 9 | Mượn Sách (Độc Giả) | 2.3.1 | 2.1.2, 2.2.4 | Cần đăng nhập và xem chi tiết sách | ⬜ Chưa làm |
| 10 | Mượn Sách (Nhân Viên) | 2.3.2 | 2.1.2, 2.2.4 | Cần đăng nhập và xem chi tiết sách. Có chức năng xác nhận & từ chối với lý do | ⬜ Chưa làm |
| 11 | Xem Lịch Sử Mượn Sách | 2.3.3 | 2.1.2, 2.3.1 | Cần đăng nhập và có đơn mượn. Bao gồm xem lý do từ chối | ⬜ Chưa làm |
| 12 | Yêu Cầu Trả Sách | 2.4.1 | 2.1.2, 2.3.1 | Cần đăng nhập và có sách đang mượn | ⬜ Chưa làm |
| 13 | Xác Nhận Trả Sách | 2.4.2 | 2.1.2, 2.4.1 | Cần đăng nhập và có yêu cầu trả sách. Hỗ trợ 3 tình trạng: Bình thường/Hư hỏng/Mất | ⬜ Chưa làm |
| 14 | Quản lý mức phạt | 2.5.1 | 2.1.2 | Cần đăng nhập với vai trò quản lý viên | ⬜ Chưa làm |
| 15 | Xem & Thanh Toán Phạt (Độc Giả) | 2.5.2 | 2.1.2, 2.4.2, 2.5.1 | Cần đăng nhập, có phiếu phạt và mức phạt | ⬜ Chưa làm |
| 16 | Xem & Thanh Toán Phạt (Nhân Viên) | 2.5.3 | 2.1.2, 2.5.2 | Cần đăng nhập và có phiếu phạt chờ xác nhận | ⬜ Chưa làm |
| 17 | Danh Sách Người Dùng | 2.6.1 | 2.1.2 | Cần đăng nhập với vai trò quản lý viên | ⬜ Chưa làm |
| 18 | Gán Vai Trò | 2.6.2 | 2.1.2, 2.6.1 | Cần đăng nhập và có danh sách người dùng | ⬜ Chưa làm |
| 19 | Báo Cáo Tổng Quan (Dashboard) | 2.7.1 | 2.1.2, 2.2.2, 2.3.1, 2.4.2 | Cần có dữ liệu sách, mượn, trả | ⬜ Chưa làm |
| 20 | Báo Cáo Chi Tiết | 2.7.2 | 2.1.2, 2.7.1 | Cần có dashboard và dữ liệu đầy đủ | ⬜ Chưa làm |

### Lưu ý về thứ tự triển khai:

**Giai đoạn 1 - Nền tảng (Ưu tiên cao nhất):**
- 2.1.1 Đăng Ký
- 2.1.2 Đăng Nhập
- 2.1.3 Hồ Sơ Cá Nhân

**Giai đoạn 2 - Quản lý Sách:**
- 2.2.1 Quản lý thể loại sách
- 2.2.2 Thêm Sách Mới
- 2.2.3 Xem Danh Sách Sách
- 2.2.4 Xem Chi Tiết Sách
- 2.2.5 Sửa & Xóa Sách

**Giai đoạn 3 - Mượn Trả Sách:**
- 2.3.1 Mượn Sách (Độc Giả)
- 2.3.2 Mượn Sách (Nhân Viên)
- 2.3.3 Xem Lịch Sử Mượn Sách
- 2.4.1 Yêu Cầu Trả Sách
- 2.4.2 Xác Nhận Trả Sách

**Giai đoạn 4 - Quản lý Phạt:**
- 2.5.1 Quản lý mức phạt
- 2.5.2 Xem & Thanh Toán Phạt (Độc Giả)
- 2.5.3 Xem & Thanh Toán Phạt (Nhân Viên)

**Giai đoạn 5 - Quản lý Người Dùng:**
- 2.6.1 Danh Sách Người Dùng
- 2.6.2 Gán Vai Trò

**Giai đoạn 6 - Báo Cáo (Ưu tiên thấp nhất):**
- 2.7.1 Báo Cáo Tổng Quan
- 2.7.2 Báo Cáo Chi Tiết


## PHẦN 4: TECH STACK

#### Frontend
- **Framework:** ReactJS
- **Styling:** TailwindCSS
- **State Management:** Context API
- **HTTP Client:** Axios
- **Forms:** React Hook Form
- **Date Handling:** Day.js
- **Charts (for reports):** Recharts

#### Backend
- **Runtime:** Node.js (v18+)
- **Framework:** Express.js
- **Language:** JavaScript
- **ORM:** Prisma
- **Validation:** Joi
- **Authentication:** jsonwebtoken (JWT)


#### Database
- **Primary:** PostgreSQL

#### Deployment
- **Hosting:** Vercel
- **Database Hosting:** Supabase
- **File Storage:** Supabase

#### Other Tools
- **Version Control:** Git
- **API Testing:** Postman
- **CI/CD:** GitHub Actions
