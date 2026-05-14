# Chuyển hướng "Mua ngay" sang Trang Thanh toán QR và Giải pháp Xác minh Giao dịch

Yêu cầu thay đổi luồng "Mua ngay" tại trang chi tiết sản phẩm để người dùng thực hiện thanh toán qua QR tương tự như trong giỏ hàng. Ngoài ra, cung cấp giải pháp để đối phó với tình trạng người dùng giả mạo ảnh chuyển khoản.

## Giải pháp xác minh giao dịch (Fake Payment)

Để ngăn chặn việc người dùng "fake" chuyển khoản (nhấn xác nhận khi chưa chuyển hoặc gửi ảnh giả), bạn có thể áp dụng các cách sau:

1.  **Sử dụng Webhook/API Ngân hàng (Khuyên dùng)**:
    - Sử dụng các dịch vụ như **Casso.vn**, **PayOS**, hoặc **VietQR API** để lắng nghe biến động số dư.
    - Khi có tiền vào tài khoản với nội dung khớp mã đơn hàng, hệ thống tự động cập nhật trạng thái đơn hàng thành "Đã thanh toán".
2.  **Đối chiếu thủ công (Cơ bản)**:
    - Khi người dùng nhấn "Xác nhận đã chuyển", đơn hàng được tạo với trạng thái `Pending Payment` (Chờ thanh toán).
    - Admin kiểm tra ứng dụng ngân hàng, nếu thấy tiền khớp với mã đơn thì mới chuyển trạng thái đơn hàng sang `Processing` (Đang xử lý).
3.  **Yêu cầu tải lên ảnh minh chứng**:
    - Thêm một nút để người dùng tải lên ảnh chụp màn hình giao dịch thành công. Mặc dù ảnh vẫn có thể bị fake, nhưng nó tạo thêm một bước đối chứng cho Admin.

Trong phạm vi code này, mình sẽ thực hiện luồng: **Thông tin -> Thanh toán QR -> Tạo đơn hàng với trạng thái mặc định**.

## Proposed Changes

### [Screens]

#### [product_detail_screen.dart](file:///C:/Users/chipt/AndroidStudioProjects/Shop/lib/screens/product_detail_screen.dart)

- Thay đổi logic nút "Xác nhận đặt hàng" trong BottomSheet của `_placeOrder`.
- Thay vì gọi `firebaseService.placeOrder` trực tiếp, nó sẽ điều hướng sang `PaymentScreen`.

#### [payment_screen.dart](file:///C:/Users/chipt/AndroidStudioProjects/Shop/lib/screens/payment_screen.dart)

- Đảm bảo màn hình này nhận đúng danh sách sản phẩm (trong trường hợp "Mua ngay" chỉ có 1 loại sản phẩm) để xử lý tạo đơn hàng sau khi nhấn xác nhận.

## Verification Plan

### Automated Tests
- Không có test tự động cụ thể cho luồng UI này.

### Manual Verification
- **Bước 1**: Vào trang chi tiết một sản phẩm.
- **Bước 2**: Nhấn "MUA NGAY".
- **Bước 3**: Nhập thông tin và áp mã giảm giá (nếu có).
- **Bước 4**: Nhấn "XÁC NHẬN" -> Kiểm tra xem có chuyển sang trang QR với đúng số tiền đã giảm không.
- **Bước 5**: Nhấn "XÁC NHẬN ĐÃ CHUYỂN KHOẢN" tại trang QR -> Kiểm tra đơn hàng có được tạo trên Firestore không.
