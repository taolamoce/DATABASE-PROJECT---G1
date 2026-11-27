# University Research & Lab Asset Tracker

*Dự án cơ sở dữ liệu quản lý phòng thí nghiệm nghiên cứu của trường đại học, tài trợ nghiên cứu, tài sản, kho hóa chất, chứng chỉ an toàn và nhật ký truy cập phòng thí nghiệm.*

### Thông tin học phần

| Thông tin | Nội dung |
| --- | --- |
| Học phần | INT1313 - Cơ sở dữ liệu |
| Nhóm | G1 |
| Phạm vi | Phase 1 - Thiết kế khái niệm |

### Thành viên thực hiện

| Họ và tên |
| --- |
| Phạm Văn An |
| Lâm Minh Chiến |
| Đỗ Vương Bảo Anh |

### Công nghệ và chức năng

Thiết kế cơ sở dữ liệu quan hệ, mô hình EER và kiểm soát quyền truy cập bằng SQL Trigger.

## 1 Tổng quan và phạm vi dự án

### Tổng quan

**University Research & Lab Asset Tracker** được thiết kế nhằm quản lý tập trung các phòng thí nghiệm nghiên cứu trong trường đại học.

Các trường đại học vận hành nhiều phòng thí nghiệm phục vụ giảng viên và sinh viên. Những phòng thí nghiệm này chứa thiết bị có giá trị cao, hóa chất và có thể nhận kinh phí từ nhiều khoản tài trợ nghiên cứu và tổ chức tài trợ khác nhau.

Trong nhiều trường hợp, tài sản, kho hóa chất và quyền truy cập được quản lý thủ công bằng hồ sơ giấy hoặc các bảng tính riêng lẻ. Điều này gây ra các vấn đề:

- Khó kiểm soát quyền truy cập hóa chất nguy hiểm và khu vực hạn chế.
- Khó truy xuất thông tin thiết bị và hóa chất khi kiểm toán.
- Thiếu cơ chế kiểm tra bắt buộc đối với chứng chỉ an toàn của nhân sự.
- Thiếu liên kết giữa nhân sự, tài trợ nghiên cứu, phòng thí nghiệm và tài sản.

Dự án giải quyết các vấn đề trên bằng cơ sở dữ liệu quan hệ tích hợp tài nguyên phòng thí nghiệm, nhân sự, tài trợ nghiên cứu, chứng chỉ và nhật ký truy cập vào một hệ thống.

### Mục tiêu dự án

Thiết kế và xây dựng cơ sở dữ liệu quan hệ **University Research & Lab Asset Tracker** để quản lý tập trung:

- Các khoản tài trợ nghiên cứu.
- Thiết bị phòng thí nghiệm.
- Kho hóa chất.
- Thông tin giảng viên và sinh viên.
- Chứng chỉ an toàn.
- Nhật ký truy cập phòng thí nghiệm.

Mục tiêu quan trọng là đảm bảo chỉ những nhân sự có chứng chỉ an toàn hợp lệ và chưa hết hạn mới được truy cập phòng thí nghiệm hoặc hóa chất nguy hiểm.

Quy tắc này sẽ được thực thi trực tiếp tại tầng cơ sở dữ liệu bằng **SQL Trigger**.

### Phạm vi dự án

#### Trong phạm vi

Hệ thống quản lý:

- Khoa, bộ môn.
- Nhân sự.
- Giảng viên.
- Sinh viên.
- Chứng chỉ an toàn.
- Phòng thí nghiệm nghiên cứu.
- Thiết bị.
- Hóa chất.
- Tài trợ nghiên cứu.
- Thành viên tham gia nghiên cứu.
- Nhật ký truy cập phòng thí nghiệm.

#### Ngoài phạm vi

- Hệ thống kế toán tài chính toàn trường.
- Quản lý học vụ và đăng ký học phần.
- Hệ thống quản lý nhân sự hoàn chỉnh.

## 2 Yêu cầu hệ thống

### Yêu cầu chức năng (Functional Requirements)

- **FR1:** Quản trị viên có thể đăng ký thiết bị mới và gán thiết bị vào một phòng thí nghiệm cụ thể.
- **FR2:** Giảng viên có thể tạo và quản lý hồ sơ tài trợ nghiên cứu, bao gồm tổ chức tài trợ, số tiền và thời gian thực hiện dự án.
- **FR3:** Hệ thống ghi lại mọi sự kiện truy cập phòng thí nghiệm, bao gồm thời điểm và loại truy cập.
- **FR4:** Hệ thống kiểm tra chứng chỉ an toàn của nhân sự trước khi cho phép truy cập phòng thí nghiệm hoặc hóa chất nguy hiểm.
- **FR5:** Hệ thống theo dõi kho hóa chất, bao gồm số lượng, vị trí lưu trữ và phân loại mức độ nguy hiểm.
- **FR6:** Nhiều nhân sự có thể tham gia một khoản tài trợ nghiên cứu với vai trò chủ nhiệm (PI), đồng chủ nhiệm (Co-PI) hoặc trợ lý nghiên cứu.
- **FR7:** Hệ thống hỗ trợ các truy vấn báo cáo như:
  - Các lần truy cập trái phép.
  - Thiết bị theo phòng thí nghiệm.
  - Hóa chất và chứng chỉ liên quan.
  - Chứng chỉ sắp hết hạn.

### Yêu cầu phi chức năng (Non-Functional Requirements)

- **Bảo mật:** Dữ liệu chứng chỉ và thông tin định danh nhân sự phải được kiểm soát truy cập nghiêm ngặt. Khuyến nghị mã hóa dữ liệu nhạy cảm khi lưu trữ.
- **Hiệu năng:** Truy vấn kiểm toán nhật ký truy cập nên trả kết quả dưới 200 ms với tối đa 100.000 bản ghi.
- **Tính sẵn sàng:** Hệ thống nên hoạt động 24/7 vì phòng thí nghiệm có thể được truy cập ngoài giờ làm việc.
- **Tính toàn vẹn dữ liệu:** Việc kiểm tra chứng chỉ khi truy cập khu vực nguy hiểm phải được thực thi tại tầng cơ sở dữ liệu, không phụ thuộc hoàn toàn vào logic ứng dụng.

## 3 Quy tắc nghiệp vụ (Business Rules)

### Nhân sự và chứng chỉ

- **BR1:** Mỗi bản ghi `PERSONNEL` có `person_id` duy nhất. Một nhân sự có thể thuộc kiểu con `FACULTY` hoặc `STUDENT`. Chuyên biệt hóa có tính rời nhau và không toàn phần (disjoint, partial).
- **BR2:** Mỗi giảng viên thuộc đúng một khoa. Một khoa có thể có nhiều giảng viên.
- **BR3:** Mỗi sinh viên có tối đa một giảng viên hướng dẫn. Một giảng viên có thể hướng dẫn nhiều sinh viên.
- **BR4:** Một nhân sự có thể có không hoặc nhiều chứng chỉ; một chứng chỉ có thể thuộc về nhiều nhân sự thông qua `PERSON_CERTIFICATION`.
- **BR5:** Chứng chỉ chỉ hợp lệ khi ngày hiện tại nằm trong khoảng từ `issue_date` đến `expiry_date`.

### Phòng thí nghiệm, thiết bị và hóa chất

- **BR6:** Mỗi thiết bị thuộc đúng một phòng thí nghiệm. Một phòng thí nghiệm có thể có không hoặc nhiều thiết bị.
- **BR7:** Mỗi hóa chất được lưu trữ tại đúng một phòng thí nghiệm. Một phòng thí nghiệm có thể lưu trữ không hoặc nhiều hóa chất.
- **BR8:** Mỗi phòng thí nghiệm và hóa chất có mức độ hoặc phân loại nguy hiểm. Nếu mức độ khác `None`, chỉ nhân sự có chứng chỉ hợp lệ với cấp độ tương ứng hoặc cao hơn mới được truy cập.

### Tài trợ nghiên cứu

- **BR9:** Mỗi khoản tài trợ nghiên cứu có đúng một chủ nhiệm nghiên cứu (PI), và PI phải là giảng viên.
- **BR10:** Một giảng viên có thể làm PI của nhiều khoản tài trợ nghiên cứu.
- **BR11:** Một khoản tài trợ nghiên cứu có thể có nhiều nhân sự tham gia thông qua `GRANT_MEMBER`.
- **BR12:** Số tiền tài trợ phải lớn hơn 0 và `end_date` phải sau `start_date`.

### Nhật ký truy cập

- **BR13:** Mỗi bản ghi `ACCESS_LOG` phải tham chiếu đến nhân sự và phòng thí nghiệm tồn tại. Có thể tham chiếu thêm thiết bị và/hoặc hóa chất.
- **BR14:** Mỗi sự kiện truy cập có `access_type` là `Entry` hoặc `Exit`. Giá trị `authorized_flag` được xác định tự động dựa trên tính hợp lệ của chứng chỉ.
- **BR15:** Hệ thống không được cho phép chèn bản ghi truy cập với `authorized_flag = TRUE` nếu nhân sự không có chứng chỉ hợp lệ theo yêu cầu.

## 4 Thiết kế cơ sở dữ liệu khái niệm

### Mô hình khái niệm

Mô hình gồm các thực thể chính:

- `DEPARTMENT`
- `PERSONNEL`
- `FACULTY`
- `STUDENT`
- `CERTIFICATION`
- `PERSON_CERTIFICATION`
- `LAB`
- `EQUIPMENT`
- `CHEMICAL`
- `RESEARCH_GRANT`
- `GRANT_MEMBER`
- `ACCESS_LOG`

Mô hình EER còn bao gồm mối quan hệ chuyên biệt hóa:

```text
PERSONNEL
   |
   +-- FACULTY
   |
   +-- STUDENT
```

- **Disjoint (rời nhau):** Một nhân sự không thể đồng thời là giảng viên và sinh viên.
- **Partial (không toàn phần):** Một nhân sự có thể không thuộc kiểu con nào trong hai kiểu trên.

### Tổng quan các thực thể

| Thực thể | Khóa chính (PK) | Mục đích |
|---|---|---|
| `DEPARTMENT` | `dept_id` | Khoa hoặc đơn vị quản lý giảng viên. |
| `PERSONNEL` | `person_id` | Kiểu cha chung của nhân sự. |
| `FACULTY` | `person_id` | Kiểu con giảng viên; có thể làm PI và hướng dẫn sinh viên. |
| `STUDENT` | `person_id` | Kiểu con sinh viên; có thể có giảng viên hướng dẫn. |
| `CERTIFICATION` | `cert_id` | Chứng chỉ an toàn và cấp độ nguy hiểm được phép truy cập. |
| `PERSON_CERTIFICATION` | `person_id, cert_id` | Thực thể liên kết ghi nhận chứng chỉ được cấp cho nhân sự và thời hạn hiệu lực. |
| `LAB` | `lab_id` | Phòng thí nghiệm có mức độ nguy hiểm riêng. |
| `EQUIPMENT` | `equipment_id` | Thiết bị được gán vào một phòng thí nghiệm cụ thể. |
| `CHEMICAL` | `chemical_id` | Hóa chất được lưu trữ trong phòng thí nghiệm và có phân loại nguy hiểm. |
| `RESEARCH_GRANT` | `grant_id` | Khoản tài trợ nghiên cứu do một PI quản lý. |
| `GRANT_MEMBER` | `grant_id, person_id` | Thực thể liên kết khoản tài trợ và nhân sự tham gia. |
| `ACCESS_LOG` | `log_id` | Nhật ký ra/vào phòng thí nghiệm kèm thông tin cấp quyền. |

### Tổng hợp các mối quan hệ

| Mối quan hệ | Bản số (Cardinality) | Quy tắc liên quan |
|---|---|---|
| `DEPARTMENT` - `FACULTY` | 1,1 - 0,N | BR2 |
| `FACULTY` - `STUDENT` | 0,1 - 0,N | BR3 |
| `PERSONNEL` - `PERSON_CERTIFICATION` - `CERTIFICATION` | N:N qua thực thể liên kết | BR4, BR5 |
| `LAB` - `EQUIPMENT` | 1,1 - 0,N | BR6 |
| `LAB` - `CHEMICAL` | 1,1 - 0,N | BR7 |
| `FACULTY` - `RESEARCH_GRANT` | 1,1 - 1,N | BR9, BR10 |
| `RESEARCH_GRANT` - `GRANT_MEMBER` - `PERSONNEL` | N:N qua thực thể liên kết | BR11 |
| `PERSONNEL` - `ACCESS_LOG` | 1,1 - 0,N | BR13 |
| `LAB` - `ACCESS_LOG` | 1,1 - 0,N | BR13 |
| `EQUIPMENT` - `ACCESS_LOG` | 0,1 - 0,N | BR13 |
| `CHEMICAL` - `ACCESS_LOG` | 0,1 - 0,N | BR13 |
| `PERSONNEL` - `FACULTY/STUDENT` | Chuyên biệt hóa rời nhau, không toàn phần | BR1 |

## 5 Giả định thiết kế

- Một nhân sự không thể đồng thời là giảng viên và sinh viên.
- Mỗi khoản tài trợ nghiên cứu chỉ có một PI tại một thời điểm.
- Nếu PI thay đổi, `pi_id` được cập nhật.
- Lịch sử thay đổi PI không được lưu trong Phase 1.
- Mỗi bản ghi nhật ký truy cập liên kết với tối đa một thiết bị hoặc một hóa chất.
- Tham chiếu thiết bị và hóa chất trong nhật ký truy cập là tùy chọn.
- Mức độ nguy hiểm sử dụng thang phân loại thống nhất giữa phòng thí nghiệm, hóa chất và chứng chỉ.
- Ví dụ về các mức độ nguy hiểm:
  - `None`: Không nguy hiểm.
  - `Low`: Thấp.
  - `Medium`: Trung bình.
  - `High`: Cao.

## 6 Thách thức cơ sở dữ liệu và kiểm soát truy cập

Thách thức chính của dự án là thực thi cơ chế truy cập an toàn đối với phòng thí nghiệm và hóa chất nguy hiểm.

Trước khi chèn một bản ghi mới vào `ACCESS_LOG`, cơ sở dữ liệu phải kiểm tra:

1. Nhân sự có tồn tại hay không.
2. Mức độ nguy hiểm của phòng thí nghiệm hoặc hóa chất liên quan.
3. Nhân sự có chứng chỉ hợp lệ hay không.
4. Cấp độ chứng chỉ có đáp ứng mức độ nguy hiểm được yêu cầu hay không.
5. Chứng chỉ đã hết hạn hay chưa.

Quy tắc này sẽ được triển khai bằng SQL Trigger như sau:

```sql
BEFORE INSERT ON ACCESS_LOG
```

Trigger sẽ ngăn việc ghi nhận một lượt truy cập trái phép thành lượt truy cập được cấp quyền.
