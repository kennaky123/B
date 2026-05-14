# Walkthrough - Chuyển hướng Mua ngay & Giải pháp Xác minh Thanh toán

Mình đã hoàn thành việc chuyển hướng luồng "Mua ngay" sang trang thanh toán QR và cung cấp thông tin về việc xác minh giao dịch.

## Các thay đổi chính

### 1. Đồng bộ luồng Thanh toán
- Cả **Giỏ hàng** (qua `CheckoutScreen`) và **Mua ngay** (qua `ProductDetailScreen`) hiện đều dẫn người dùng đến `PaymentScreen` (Trang QR).
- Đơn hàng chỉ được tạo trên Firestore sau khi người dùng nhấn **"XÁC NHẬN ĐÃ CHUYỂN KHOẢN"**.
- [payment_screen.dart](file:///C:/Users/chipt/AndroidStudioProjects/Shop/lib/screens/payment_screen.dart): Thêm logic `clearCartOnSuccess` để chỉ xóa giỏ hàng khi người dùng mua từ Giỏ hàng, không làm ảnh hưởng giỏ hàng khi dùng tính năng "Mua ngay".

### 2. Giải pháp xác minh giao dịch (Fake Payment)
Để giải quyết vấn đề người dùng giả mạo việc chuyển khoản, bạn có thể thực hiện các bước sau:

#### Quy trình thủ công (Admin)
- Khi người dùng nhấn xác nhận, đơn hàng được tạo.
- Admin vào ứng dụng Ngân hàng kiểm tra biến động số dư.
- Nếu khớp số tiền và nội dung, Admin mới chuyển trạng thái đơn hàng sang `Processing` hoặc `Confirmed`.

#### Quy trình tự động (Kỹ thuật)
- **Tích hợp API Ngân hàng**: Sử dụng dịch vụ như [PayOS](https://payos.vn/) hoặc [Casso](https://casso.vn/). Các dịch vụ này cung cấp Webhook sẽ gọi về máy chủ của bạn ngay khi có tiền vào.
- **Mã QR động**: Trong `PaymentScreen`, mã QR đã được tạo tự động với số tiền chính xác. Bạn có thể thêm mã đơn hàng vào nội dung chuyển khoản để việc đối soát tự động dễ dàng hơn.

## Hướng dẫn kiểm tra (Verification)

1.  **Mua ngay**:
    - Vào trang chi tiết sản phẩm.
    - Nhấn "MUA NGAY" -> Nhập thông tin -> Nhấn "TIẾP TỤC THANH TOÁN".
    - Kiểm tra xem có hiện trang QR với đúng số tiền không.
    - Nhấn xác nhận và kiểm tra Firestore (collection `orders`).
2.  **Giỏ hàng**:
    - Thêm sản phẩm vào giỏ -> Vào giỏ hàng -> Thanh toán.
    - Nhấn "TIẾP TỤC THANH TOÁN" -> Hoàn tất tại trang QR.
    - Kiểm tra xem giỏ hàng đã được xóa sạch chưa.
