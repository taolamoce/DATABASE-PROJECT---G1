# University Research & Lab Asset Tracker – G1

README dự án và hướng dẫn cài đặt, vận hành demo Phase 4.

University Research & Lab Asset Tracker là hệ thống quản lý phòng thí nghiệm nghiên cứu trong trường đại học, tích hợp quản lý nhân sự, thiết bị, hóa chất, chứng chỉ an toàn, tài trợ nghiên cứu và nhật ký truy cập. Website kết nối trực tiếp với MySQL thông qua Node.js và Express. Trọng tâm của dự án là kiểm soát truy cập dựa trên chứng chỉ an toàn bằng SQL Trigger tại tầng cơ sở dữ liệu.

### Thông tin repository và học phần

| Thông tin | Nội dung |
| --- | --- |
| Học phần | INT1313 – Databases (Cơ sở dữ liệu) |
| Lớp học phần | E24CQCE02-N |
| Nhóm | G1 |
| Đề tài | Project #1: University Research & Lab Asset Tracker (theo Final Report) |
| Phạm vi | Phase 1–4: thiết kế, triển khai SQL, truy vấn, kiểm thử và website demo |

### Thành viên thực hiện

| Họ và tên (theo Final Report) | Mã sinh viên | Email sinh viên |
| --- | --- | --- |
| Phạm An | N22DCAT002 | n22dcat002@student.ptithcm.edu.vn |
| Lâm Minh Chiến | N24DECE057 | n24dece057@student.ptithcm.edu.vn |
| Đỗ Vương Bảo Anh | N24DECE054 | n24dece054@student.ptithcm.edu.vn |

### Các giai đoạn thực hiện

| Giai đoạn | Nội dung |
| --- | --- |
| Phase 1 | Phân tích bài toán, yêu cầu, 15 quy tắc nghiệp vụ và mô hình EER |
| Phase 2 | Lược đồ quan hệ, PK/FK, chuẩn hóa đến BCNF theo báo cáo và Data Dictionary |
| Phase 3 | DDL, DML, 12 truy vấn nâng cao, functions, triggers, views, kiểm thử và RBAC |
| Phase 4 | Website demo kết nối MySQL, thao tác thiết bị và minh họa kiểm soát truy cập |

### Công nghệ và chức năng

MySQL 8.0.16 trở lên, InnoDB, MySQL Workbench, Node.js 18 trở lên, Express (^4.21.2), mysql2 (^3.12.0), dotenv (^16.4.7), HTML, CSS và JavaScript. Phiên bản thư viện cụ thể được khóa trong `package-lock.json`.

Website hỗ trợ tổng quan dữ liệu, xem phòng thí nghiệm, thiết bị, hóa chất, nhân sự, tài trợ nghiên cứu; thêm, sửa, xóa thiết bị; thử quyền truy cập và xem nhật ký. Đây là ứng dụng demo cục bộ, không phải hệ thống kiểm soát cửa vật lý.

## 1. Mã nguồn và tài liệu trong repository

Cấu trúc dưới đây là cách tổ chức đề xuất từ các file được cung cấp. Thư mục `public/` là bắt buộc đối với cấu hình phục vụ giao diện hiện tại của `server.js`.

```text
DATABASE-PROJECT---G1/
├── README.md
├── database/
│   ├── 01_schema_ddl.sql
│   ├── 02_functions_triggers_views.sql
│   ├── 03_seed_data_dml.sql
│   ├── 04_advanced_queries.sql
│   └── 05_verification_rbac.sql
├── docs/
│   └── FinalReport(2).pdf
└── Phase4/
    ├── server.js
    ├── package.json
    ├── package-lock.json
    ├── .env.example
    ├── .gitignore
    └── public/
        ├── index.html
        ├── app-real.js
        └── style.css
```

### Vai trò các thành phần

| File | Chức năng |
| --- | --- |
| `01_schema_ddl.sql` | Tạo database, 12 bảng, ràng buộc và indexes |
| `02_functions_triggers_views.sql` | Tạo 2 functions, 7 triggers và 5 views |
| `03_seed_data_dml.sql` | Nạp dữ liệu mẫu cho toàn bộ hệ thống |
| `04_advanced_queries.sql` | 12 truy vấn phân tích và báo cáo |
| `05_verification_rbac.sql` | Kiểm thử toàn vẹn và thiết lập 5 vai trò MySQL |
| `server.js` | Express server, kết nối MySQL và xử lý API |
| `public/index.html` | Khung giao diện website |
| `public/app-real.js` | Gọi API, hiển thị dữ liệu, xử lý thao tác |
| `public/style.css` | Định dạng giao diện |
| `package.json`, `package-lock.json` | Khai báo và khóa phiên bản thư viện |
| `FinalReport(2).pdf` | Báo cáo thiết kế và triển khai cơ sở dữ liệu |

`.env.example` và `.gitignore` là các file đề xuất bổ sung, chưa nằm trong bộ mã nguồn được cung cấp. Không đưa `.env`, `node_modules/` hoặc `.DS_Store` lên GitHub.

## 2. Cài đặt và nạp database

### Yêu cầu trên máy mới

Cài MySQL Server 8.0.16+ và MySQL Workbench; Node.js 18+ cùng npm. MySQL Server phải đang chạy. Workbench chỉ là công cụ kết nối và thực thi SQL.

### Thứ tự chạy SQL bằng MySQL Workbench

1. Mở kết nối MySQL, thông thường tại `127.0.0.1:3306`.
2. Chọn File → Open SQL Script, mở `01_schema_ddl.sql` và chạy toàn bộ file.
3. Chạy `02_functions_triggers_views.sql` để tạo các đối tượng xử lý nghiệp vụ trước khi nạp dữ liệu.
4. Chạy `03_seed_data_dml.sql` để nạp dữ liệu mẫu.
5. Chạy `04_advanced_queries.sql` để xem kết quả 12 truy vấn.
6. Chạy `05_verification_rbac.sql` bằng tài khoản có quyền quản trị nếu cần kiểm thử và thiết lập RBAC. Các ca âm TC01–TC08 đang được chú thích; chạy riêng từng câu lệnh để quan sát lỗi mong đợi.
7. Refresh Schemas và kiểm tra database `lab_asset_tracker`.

**Cảnh báo:** File 01 chứa `DROP DATABASE IF EXISTS lab_asset_tracker`, sẽ xóa dữ liệu cũ. Sao lưu trước khi chạy lại. Không chạy file 03 nhiều lần trên cùng bộ dữ liệu vì có thể trùng khóa. File 05 thêm hai nhật ký kiểm thử và tạo lại các tài khoản/vai trò demo; không chạy tùy tiện trên database đang sử dụng.

### Dữ liệu mẫu dự kiến sau file 03

| Bảng | Số dòng dự kiến | Bảng | Số dòng dự kiến |
| --- | ---: | --- | ---: |
| department | 5 | personnel | 22 |
| faculty | 8 | student | 11 |
| certification | 6 | person_certification | 30 |
| lab | 7 | equipment | 17 |
| chemical | 16 | research_grant | 7 |
| grant_member | 30 | access_log | 48 |

Số liệu trên lấy từ chú thích seed SQL, chưa phải kết quả đếm trực tiếp. `grant_member` gồm 23 thành viên được nạp và 7 PI được thêm bằng trigger. Sau file 05, dự kiến có thêm 2 access logs nếu cả hai lệnh INSERT thành công. Các thao tác website có thể tiếp tục thay đổi số dòng.

### Thiết kế và quy tắc nghiệp vụ

- BR1–BR5: nhân sự, chuyên biệt hóa Faculty/Student disjoint và partial, khoa, cố vấn, chứng chỉ và thời hạn hiệu lực.
- BR6–BR8: thiết bị và hóa chất thuộc phòng thí nghiệm; cấp chứng chỉ phải đáp ứng mức nguy hiểm.
- BR9–BR12: mỗi đề tài có một PI là giảng viên; nhiều thành viên có thể tham gia; kinh phí dương và ngày kết thúc sau ngày bắt đầu.
- BR13–BR15: nhật ký tham chiếu nhân sự và phòng; có thể tham chiếu một thiết bị hoặc một hóa chất, không đồng thời cả hai; Entry/Exit và quyền truy cập được xác định bởi database.

Mô hình có hai bảng liên kết N:N là `person_certification` và `grant_member`. Các ràng buộc PK, FK, UNIQUE, CHECK, NOT NULL, ENUM và trigger hỗ trợ toàn vẹn dữ liệu. Theo DDL hiện tại, `faculty.dept_id` cho phép NULL và ON DELETE SET NULL, nên chưa bắt buộc mọi giảng viên luôn thuộc một khoa như phát biểu BR2.

## 3. Cấu hình và khởi động website

### Tạo file cấu hình

Trong thư mục chứa `server.js`, tạo file `.env` với nội dung sau, thay thông tin tài khoản bằng cấu hình MySQL của máy:

```dotenv
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=<mat_khau_mysql_cua_may>
MYSQL_DATABASE=lab_asset_tracker
PORT=3000
```

Tài khoản root chỉ là ví dụ cho môi trường demo cục bộ. Không đưa mật khẩu thật vào repository. Có thể tạo `.env.example` với mật khẩu để trống và `.gitignore` chứa `.env`, `node_modules/`, `.DS_Store`.

### Cài đặt và chạy trên macOS hoặc Windows

Mở Terminal hoặc PowerShell tại thư mục `Phase4/` (hoặc thư mục thực tế chứa `package.json` và `server.js`). Đảm bảo ba file giao diện nằm trong `public/`.

```bash
node -v
npm -v
npm ci
npm start
```

Nếu không có lockfile, dùng `npm install`. Có thể dùng `npm run dev` trên phiên bản Node hỗ trợ `--watch` để tự khởi động lại khi sửa mã.

Mở trình duyệt tại http://localhost:3000 và kiểm tra http://localhost:3000/api/health. Khi kết nối thành công, API health trả về `ok: true` và database `lab_asset_tracker`. Giữ Terminal đang chạy khi demo; nhấn Ctrl+C để dừng. Server chỉ lắng nghe tại `127.0.0.1`, không triển khai công khai trên Internet.

## 4. Vận hành và luồng trình bày

| Bước | Thao tác | Kết quả cần quan sát |
| --- | --- | --- |
| 1 | Overview | Tổng quan số lượng phòng, thiết bị, hóa chất và tài trợ |
| 2 | Laboratories | Danh sách phòng và cấp nguy hiểm |
| 3 | Equipment | Thêm, sửa, xóa thiết bị; dữ liệu thay đổi trong MySQL |
| 4 | Chemicals | Xem hóa chất, số lượng, vị trí và cấp nguy hiểm |
| 5 | Personnel | Xem nhân sự và cấp chứng chỉ hợp lệ hiện tại |
| 6 | Research grants | Xem thông tin tài trợ và PI |
| 7 | Access control | Chọn nhân sự, phòng, loại truy cập và ngày để thử trigger |
| 8 | Access logs | Xem nhật ký Allowed/Denied (tối đa 100 bản ghi mới theo log_id) |

### Demo kiểm soát truy cập

Dùng ngày `2026-10-15` để phù hợp bộ dữ liệu mẫu. Chọn `Entry` và phòng `LAB-004`.

| Trường hợp | Nhân sự | Request authorized_flag = TRUE | Kết quả mong đợi |
| --- | --- | --- | --- |
| Có chứng chỉ High hợp lệ | PER-00001 | Bật | Allowed, lưu flag TRUE |
| Không đủ chứng chỉ | PER-00016 | Bật | SQLSTATE 45000, INSERT bị từ chối, không tạo log mới |
| Ghi nhận truy cập không được phép | PER-00016 | Tắt | Denied, INSERT thành công với flag FALSE |

Muốn trình bày nhật ký truy cập bị từ chối, phải dùng trường hợp thứ ba. Nếu bật checkbox và trigger báo lỗi thì bản ghi không được lưu. Website hiện chỉ gửi personId, labId, type, ngày và yêu cầu authorization; không có lựa chọn equipment_id hoặc chemical_id trong form Access control. Kiểm thử truy cập hóa chất/thiết bị cụ thể bằng SQL trong Workbench.

### Luồng dữ liệu

```text
Browser (HTML/CSS/JavaScript)
        ↓ HTTP / JSON
Express API (server.js)
        ↓ mysql2 / SQL có tham số
MySQL (lab_asset_tracker)
        ↓ Functions, Triggers, Constraints
Kết quả Allowed / Denied hoặc lỗi SQL → Website
```

`fn_hazard_rank` quy đổi None/Low/Medium/High thành 0/1/2/3. `fn_person_clearance` lấy cấp chứng chỉ cao nhất có trạng thái Active và ngày truy cập nằm trong khoảng hiệu lực. `trg_access_log_before_insert` so sánh cấp chứng chỉ với mức nguy hiểm lớn nhất giữa phòng và hóa chất (nếu có), đồng thời kiểm tra tài sản thuộc đúng phòng. `trg_access_log_before_update` chặn UPDATE trực tiếp lên nhật ký.

### Xem dữ liệu sau thao tác

```sql
USE lab_asset_tracker;
SELECT * FROM equipment ORDER BY equipment_id;
SELECT log_id, person_id, lab_id, access_timestamp, access_type, authorized_flag
FROM access_log ORDER BY log_id DESC LIMIT 10;
SELECT * FROM v_unauthorized_access;
```

## 5. Kiểm tra và kết quả

### Các đối tượng database

- 2 functions: `fn_hazard_rank`, `fn_person_clearance`.
- 7 triggers: kiểm soát INSERT/UPDATE access log, kiểm tra subtype Faculty/Student, kiểm soát thay đổi person_type, tự thêm PI và kiểm tra vai trò thành viên grant.
- 5 views: `v_valid_certification`, `v_person_clearance`, `v_unauthorized_access`, `v_lab_inventory_summary`, `v_grant_overview`.
- 5 roles: `sec_admin_role`, `lab_manager_role`, `faculty_role`, `student_role`, `auditor_role`.

### 12 truy vấn nâng cao

| STT | Nội dung |
| --- | --- |
| Q01 | Thống kê tài sản và trạng thái thiết bị theo phòng |
| Q02 | Kiểm toán truy cập trái phép và phân loại rủi ro |
| Q03 | Phân bổ kinh phí và nhân sự nghiên cứu |
| Q04 | Theo dõi chứng chỉ hết hạn và cần gia hạn |
| Q05 | Xếp hạng nhân sự theo tần suất truy cập |
| Q06 | Hồ sơ giảng viên: nghiên cứu và hướng dẫn sinh viên |
| Q07 | Theo dõi số người hiện diện trong phòng |
| Q08 | Ma trận hợp tác nghiên cứu liên khoa |
| Q09 | Kiểm tra tuân thủ khi tiếp cận hóa chất nguy hiểm |
| Q10 | Độ tin cậy thiết bị và tỷ lệ tiếp xúc với thiết bị bảo trì |
| Q11 | Mật độ truy cập theo giờ và hoạch định sức chứa |
| Q12 | Tổng hợp nghiên cứu và phòng thí nghiệm theo khoa |

Các truy vấn sử dụng JOIN, GROUP BY, CASE, subquery, CTE và window functions. Một số truy vấn sử dụng mốc cố định 2026-10-15 để đối chiếu báo cáo. Q01 nối đồng thời equipment và chemical theo lab nên các phép SUM có thể bị nhân bản; cần kiểm tra lại trước khi dùng số liệu tổng hợp thực tế.

### Kiểm thử toàn vẹn dữ liệu

| Mã | Trường hợp | Kết quả mong đợi |
| --- | --- | --- |
| TC01 | Giả mạo quyền truy cập khi thiếu chứng chỉ | Từ chối |
| TC02 | Thiết bị không thuộc phòng được chọn | Từ chối |
| TC03 | Hóa chất không thuộc phòng được chọn | Từ chối |
| TC04 | Tham chiếu đồng thời thiết bị và hóa chất | Từ chối |
| TC05 | UPDATE nhật ký truy cập | Từ chối |
| TC06 | Thêm Student vào Faculty | Từ chối |
| TC07 | Kinh phí âm hoặc ngày tài trợ không hợp lệ | Từ chối |
| TC08 | Email sai định dạng | Từ chối |
| TC09 | Ghi nhận truy cập trái phép | Lưu FALSE |
| TC10 | Truy cập với chứng chỉ phù hợp | Lưu TRUE |

Final Report ghi nhận PASS cho 10 nhóm kiểm thử trên. Đây là kết quả được báo cáo bởi nhóm, chưa được chạy lại độc lập khi soạn README. TC01–TC08 trong file 05 cần bỏ dấu chú thích và chạy từng trường hợp; TC09–TC10 là các lệnh INSERT đang hoạt động.

## 6. Tự kiểm tra và xử lý lỗi

### Kiểm tra database

```sql
USE lab_asset_tracker;
SELECT DATABASE();
SHOW FULL TABLES;
SHOW TRIGGERS;
SELECT COUNT(*) AS so_view FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE();
SELECT COUNT(*) AS so_function FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_TYPE = 'FUNCTION';
SELECT COUNT(*) FROM personnel;
SELECT COUNT(*) FROM access_log;
```

Kỳ vọng: 12 bảng, 5 views, 7 triggers và 2 functions sau khi chạy file 01–02 thành công. Kiểm tra số dòng từng bảng sau file 03.

| Hiện tượng | Cách xử lý |
| --- | --- |
| Access denied / 1045 | Kiểm tra MYSQL_USER, MYSQL_PASSWORD trong .env |
| Unknown database / 1049 | Chạy file 01 và kiểm tra MYSQL_DATABASE |
| ECONNREFUSED / lỗi 2003 | Khởi động MySQL Server, kiểm tra host và port |
| No records hoặc dữ liệu trống | Kiểm tra file 03 đã chạy thành công, API health và đúng database; Refresh database |
| Cannot GET / | Đặt index.html, app-real.js, style.css vào public/ cạnh server.js |
| Cannot find module | Chạy npm ci trong thư mục chứa package.json |
| EADDRINUSE | Dừng server cũ hoặc đổi PORT trong .env rồi mở URL tương ứng |
| SQLSTATE 45000 | Đọc thông báo trigger; kiểm tra chứng chỉ, ngày, phòng và checkbox |
| Không thấy log Denied mới | Tắt Request authorized_flag = TRUE trước khi thử nhân sự thiếu chứng chỉ |
| Lỗi khi tạo roles/users | Dùng tài khoản quản trị có quyền phù hợp; kiểm tra file 05 |

### Giới hạn và tài liệu tham khảo

Website chưa có đăng nhập, phân quyền người dùng trên UI hay chức năng CRUD cho tất cả bảng. RBAC được thiết lập ở MySQL, không đồng nghĩa với việc website đã áp dụng từng role theo người dùng. API dùng một tài khoản kết nối chung. Các tài khoản mẫu trong file 05 chỉ dành cho demo, cần đổi mật khẩu và hạn chế quyền khi triển khai thật. Trigger chặn UPDATE trực tiếp nhưng không bảo đảm nhật ký bất biến trước mọi thao tác quản trị. Mục tiêu phản hồi dưới 200 ms với 100.000 bản ghi và hoạt động 24/7 là yêu cầu phi chức năng, không khẳng định đã được kiểm chứng bởi bộ file hiện tại.

Tài liệu dự án: `FinalReport(2).pdf` và năm file SQL trong repository. Tài liệu kỹ thuật: [MySQL 8.0](https://dev.mysql.com/doc/refman/8.0/en/), [Node.js](https://nodejs.org/docs/latest/api/), [Express](https://expressjs.com/), [mysql2](https://sidorares.github.io/node-mysql2/docs).
