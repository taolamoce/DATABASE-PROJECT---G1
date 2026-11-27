# University Research & Lab Asset Tracker — Phase 4 Demo (Node.js + MySQL)

Website demo của nhóm G1, học phần INT1313 – Databases. Ứng dụng sử dụng 12 bảng MySQL của Phase 3 và kết nối trực tiếp với cơ sở dữ liệu `lab_asset_tracker` thông qua Node.js, Express và mysql2.

## Các chức năng

- **Overview:** Tổng quan số lượng phòng thí nghiệm, thiết bị, hóa chất và tài trợ nghiên cứu.
- **Laboratories:** Xem danh sách phòng thí nghiệm và mức độ nguy hiểm.
- **Equipment:** Xem, thêm, sửa và xóa thiết bị trực tiếp trong MySQL.
- **Chemicals:** Xem hóa chất, số lượng, vị trí lưu trữ và mức độ nguy hiểm.
- **Personnel:** Xem nhân sự và cấp chứng chỉ an toàn hợp lệ tại ngày hiện tại.
- **Research grants:** Xem các khoản tài trợ nghiên cứu và người phụ trách.
- **Access control:** Thử quyền truy cập phòng thí nghiệm bằng SQL Trigger.
- **Access logs:** Xem nhật ký truy cập được phép (Allowed) và bị từ chối (Denied).

## Chạy trên macOS hoặc Windows

Yêu cầu: MySQL Server 8.0.16 trở lên, MySQL Workbench, Node.js 18 trở lên và npm.

### 1. Chuẩn bị database

Khởi động MySQL Server. Mở MySQL Workbench và chạy các file trong thư mục `database/` theo thứ tự:

| File | Chức năng |
| --- | --- |
| `01_schema_ddl.sql` | Tạo database và các bảng |
| `02_functions_triggers_views.sql` | Tạo functions, triggers và views |
| `03_seed_data_dml.sql` | Nạp dữ liệu mẫu |
| `04_advanced_queries.sql` | Thực hiện 12 truy vấn nâng cao (tùy chọn khi chạy web) |
| `05_verification_rbac.sql` | Kiểm thử và phân quyền RBAC (tùy chọn, cần quyền quản trị) |

**Lưu ý:** File 01 xóa database cũ trước khi tạo lại. Sao lưu trước khi chạy. Nếu đã nạp database từ `Phase_3/sql/`, không cần chạy lại bộ SQL trong demo. Không nạp seed nhiều lần.

### 2. Cấu hình kết nối MySQL

Mở Terminal tại thư mục `Phase_4/demo/`. Sao chép `.env.example` thành `.env`:

macOS:
```bash
cp .env.example .env
```

Windows (PowerShell):
```powershell
Copy-Item .env.example .env
```

Điền thông tin kết nối phù hợp với máy:

```dotenv
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password
MYSQL_DATABASE=lab_asset_tracker
PORT=3000
```

Thay `your_mysql_password` bằng mật khẩu MySQL của máy. Không đưa file `.env` chứa mật khẩu lên GitHub.

### 3. Khởi động website

```bash
npm ci
npm start
```

Mở trình duyệt tại [http://localhost:3000](http://localhost:3000).

Kiểm tra kết nối database tại [http://localhost:3000/api/health](http://localhost:3000/api/health). Khi thành công, API trả về `ok: true` và tên database `lab_asset_tracker`.

Giữ Terminal mở trong quá trình demo. Nhấn `Ctrl+C` để dừng server. Có thể sử dụng `npm run dev` để tự khởi động lại khi sửa mã nguồn trên phiên bản Node hỗ trợ `--watch`.

## Chuẩn bị dữ liệu để thử

Kiểm tra nhân sự, phòng thí nghiệm và chứng chỉ trong MySQL Workbench:

```sql
USE lab_asset_tracker;
SELECT person_id, full_name FROM personnel;
SELECT lab_id, lab_name, hazard_level FROM lab;
SELECT person_id, fn_person_clearance(person_id, '2026-10-15') AS clearance
FROM personnel
WHERE person_id IN ('PER-00001', 'PER-00016');
```

### Demo Access Control

Vào trang **Access control**, chọn phòng `LAB-004`, loại truy cập `Entry` và ngày `2026-10-15` (ngày tham chiếu của dữ liệu mẫu).

| Trường hợp | Nhân sự | Yêu cầu authorization TRUE | Kết quả mong đợi |
| --- | --- | --- | --- |
| Truy cập hợp lệ | `PER-00001` | Bật | Allowed, lưu `authorized_flag = 1` |
| Không đủ chứng chỉ | `PER-00016` | Bật | Trigger báo lỗi SQLSTATE 45000, không lưu bản ghi |
| Ghi nhật ký truy cập bị từ chối | `PER-00016` | Tắt | Denied, lưu `authorized_flag = 0` |

Thực hiện yêu cầu truy cập rồi chuyển sang **Access logs** để kiểm tra kết quả. Muốn lưu nhật ký Denied, cần tắt yêu cầu authorization TRUE; nếu bật, trigger sẽ từ chối INSERT khi không đủ chứng chỉ.

Cơ chế kiểm tra được thực hiện bởi `trg_access_log_before_insert`, sử dụng `fn_hazard_rank` và `fn_person_clearance` để so sánh mức nguy hiểm với cấp chứng chỉ hợp lệ tại ngày truy cập.

## Kiểm tra MySQL sau khi demo

```sql
USE lab_asset_tracker;

SELECT * FROM equipment ORDER BY equipment_id;

SELECT log_id, person_id, lab_id, access_timestamp,
       access_type, authorized_flag
FROM access_log
ORDER BY log_id DESC
LIMIT 10;

SELECT * FROM v_unauthorized_access;
```

Các thao tác thêm, sửa, xóa thiết bị và ghi nhật ký trên website tác động trực tiếp đến MySQL. Có thể chạy lại các câu SELECT trong Workbench để đối chiếu.

## Xử lý lỗi thường gặp

| Lỗi | Cách xử lý |
| --- | --- |
| Không kết nối được MySQL | Kiểm tra MySQL Server, host, port và `.env` |
| Access denied for user | Kiểm tra tài khoản, mật khẩu và quyền MySQL |
| Unknown database | Kiểm tra tên database và chạy các file SQL 01–03 nếu chưa khởi tạo |
| Website không có dữ liệu | Kiểm tra đã nạp seed và đang kết nối đúng database |
| Cannot find module | Chạy `npm ci` trong thư mục chứa `package.json` |
| Port 3000 đã được sử dụng | Dừng tiến trình đang dùng port hoặc đổi `PORT` trong `.env` |
| Không thấy nhật ký Denied | Tắt yêu cầu authorization TRUE khi thử truy cập không hợp lệ |

## Giới hạn quan trọng

- Website chỉ chạy cục bộ tại `127.0.0.1`; không triển khai công khai bản demo dùng tài khoản root hoặc chưa có xác thực người dùng.
- Website hiện không có màn hình đăng nhập hay phân quyền người dùng theo các vai trò RBAC của MySQL.
- Access Control mô phỏng kiểm tra quyền truy cập, không điều khiển cửa phòng thí nghiệm thật.
- Form Access Control hiện chỉ kiểm tra truy cập phòng, không chọn thiết bị hoặc hóa chất cụ thể. Các quy tắc liên quan đến thiết bị và hóa chất có thể kiểm thử bằng SQL trong Workbench.
- Access logs hiển thị tối đa 100 bản ghi mới nhất theo `log_id`.
- Các kết quả demo trên là kết quả mong đợi theo mã nguồn và dữ liệu mẫu; có thể thay đổi nếu dữ liệu hoặc chứng chỉ đã được chỉnh sửa.
