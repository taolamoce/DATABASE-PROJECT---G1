-- =============================================================================
-- Project   : University Research & Lab Asset Tracker (INT1313 - Group G1)
-- Phase     : 3 - Implementation & Queries
-- Script    : 03_seed_data_dml.sql
-- Purpose   : Realistic mock data (DML) covering every table and every
--             business-rule scenario used by the queries and test cases.
-- Notes     : * research_grant PIs are NOT inserted into grant_member here;
--               trigger trg_research_grant_after_insert does it (FR6).
--             * access_log.authorized_flag is NOT supplied; trigger
--               trg_access_log_before_insert derives it (BR15).
--             * Reference "today" for the report: 2026-10-15.
-- =============================================================================

USE lab_asset_tracker;

START TRANSACTION;

-- -----------------------------------------------------------------------------
-- department (5)
-- -----------------------------------------------------------------------------
INSERT INTO department (dept_id, dept_name, building)
VALUES ('DEPT-CS',   'Computer Science',        'Building A'),
       ('DEPT-EE',   'Electronics Engineering', 'Building A'),
       ('DEPT-CHEM', 'Chemistry',               'Building B'),
       ('DEPT-BIO',  'Biotechnology',           'Building C'),
       ('DEPT-MSE',  'Materials Science',       'Building D');

-- -----------------------------------------------------------------------------
-- personnel (22) : 8 Faculty, 11 Students, 3 Other (technician, visitor, officer)
-- -----------------------------------------------------------------------------
INSERT INTO personnel (person_id, full_name, email, phone, person_type)
VALUES ('PER-00001', 'Nguyễn Văn Hùng',   'hung.nv@lab.edu.vn',     '0903111001', 'Faculty'),
       ('PER-00002', 'Trần Thị Mai',      'mai.tt@lab.edu.vn',      '0903111002', 'Faculty'),
       ('PER-00003', 'Lê Minh Tuấn',      'tuan.lm@lab.edu.vn',     '0903111003', 'Faculty'),
       ('PER-00004', 'Phạm Quốc Bảo',     'bao.pq@lab.edu.vn',      '0903111004', 'Faculty'),
       ('PER-00005', 'Hoàng Thị Lan',     'lan.ht@lab.edu.vn',      '0903111005', 'Faculty'),
       ('PER-00006', 'Võ Thành Sơn',      'son.vt@lab.edu.vn',      '0903111006', 'Faculty'),
       ('PER-00007', 'Đặng Ngọc Ánh',     'anh.dn@lab.edu.vn',      NULL,         'Faculty'),
       ('PER-00008', 'Bùi Đức Thắng',     'thang.bd@lab.edu.vn',    '0903111008', 'Faculty'),
       ('PER-00009', 'Nguyễn Thị Hoa',    'hoa.nt@student.edu.vn',  '0912222009', 'Student'),
       ('PER-00010', 'Trần Quốc Việt',    'viet.tq@student.edu.vn', '0912222010', 'Student'),
       ('PER-00011', 'Lê Hoàng Nam',      'nam.lh@student.edu.vn',  '0912222011', 'Student'),
       ('PER-00012', 'Phan Thu Trang',    'trang.pt@student.edu.vn','0912222012', 'Student'),
       ('PER-00013', 'Võ Minh Khoa',      'khoa.vm@student.edu.vn', '0912222013', 'Student'),
       ('PER-00014', 'Đỗ Gia Huy',        'huy.dg@student.edu.vn',  '0912222014', 'Student'),
       ('PER-00015', 'Huỳnh Bảo Ngọc',    'ngoc.hb@student.edu.vn', '0912222015', 'Student'),
       ('PER-00016', 'Ngô Thanh Tâm',     'tam.nt@student.edu.vn',  NULL,         'Student'),
       ('PER-00017', 'Lý Khánh Linh',     'linh.lk@student.edu.vn', '0912222017', 'Student'),
       ('PER-00018', 'Trịnh Đức Minh',    'minh.td@student.edu.vn', '0912222018', 'Student'),
       ('PER-00019', 'Mai Phương Thảo',   'thao.mp@student.edu.vn', '0912222019', 'Student'),
       ('PER-00020', 'Nguyễn Văn Tài',    'tai.nv@lab.edu.vn',      '0987333020', 'Other'),
       ('PER-00021', 'Kenji Tanaka',      'k.tanaka@visitor.jp',    NULL,         'Other'),
       ('PER-00022', 'Trần Thị Bích',     'bich.tt@lab.edu.vn',     '0987333022', 'Other');

-- -----------------------------------------------------------------------------
-- faculty (8)  - trigger trg_faculty_before_insert checks person_type (BR1)
-- -----------------------------------------------------------------------------
INSERT INTO faculty (person_id, dept_id, tenure_status, office_location)
VALUES ('PER-00001', 'DEPT-CHEM', 'Tenured',      'B-401'),
       ('PER-00002', 'DEPT-BIO',  'Tenured',      'C-305'),
       ('PER-00003', 'DEPT-CS',   'Tenure-Track', 'A-512'),
       ('PER-00004', 'DEPT-EE',   'Tenured',      'A-408'),
       ('PER-00005', 'DEPT-MSE',  'Tenure-Track', 'D-210'),
       ('PER-00006', 'DEPT-CHEM', 'Adjunct',      'B-402'),
       ('PER-00007', 'DEPT-BIO',  'Emeritus',     NULL),
       ('PER-00008', 'DEPT-CS',   'Adjunct',      'A-515');

-- -----------------------------------------------------------------------------
-- student (11) - trigger trg_student_before_insert checks person_type (BR1)
-- -----------------------------------------------------------------------------
INSERT INTO student (person_id, program, enrollment_year, advisor_id)
VALUES ('PER-00009', 'Chemistry',               2023, 'PER-00001'),
       ('PER-00010', 'Chemistry',               2022, 'PER-00001'),
       ('PER-00011', 'Biotechnology',           2024, 'PER-00002'),
       ('PER-00012', 'Biotechnology',           2023, 'PER-00002'),
       ('PER-00013', 'Computer Science',        2024, 'PER-00003'),
       ('PER-00014', 'Electronics Engineering', 2022, 'PER-00004'),
       ('PER-00015', 'Materials Science',       2023, 'PER-00005'),
       ('PER-00016', 'Chemistry',               2025, 'PER-00006'),
       ('PER-00017', 'Computer Science',        2025, NULL),
       ('PER-00018', 'Materials Science',       2024, 'PER-00005'),
       ('PER-00019', 'Biotechnology',           2025, 'PER-00007');

-- -----------------------------------------------------------------------------
-- certification (6)
-- -----------------------------------------------------------------------------
INSERT INTO certification (cert_id, cert_name, hazard_level, description)
VALUES ('CERT-001', 'General Laboratory Safety',             'Low',    'Mandatory induction: PPE, emergency exits, spill basics.'),
       ('CERT-002', 'Electrical Safety Level 1',             'Low',    'Safe operation of low-voltage benches and instruments.'),
       ('CERT-003', 'Chemical Handling Level 2',             'Medium', 'Handling of flammable and corrosive reagents under fume hood.'),
       ('CERT-004', 'Biosafety Level 2 (BSL-2)',             'Medium', 'Work with moderate-risk biological agents in Class II cabinets.'),
       ('CERT-005', 'Hazardous Materials Specialist',        'High',   'Access to high-hazard labs, toxic and carcinogenic substances.'),
       ('CERT-006', 'Corrosive and Toxic Substances Handling','High',  'Handling of HF, concentrated acids and acute toxins.');

-- -----------------------------------------------------------------------------
-- person_certification (30) - mix of valid, date-expired, Expired and Revoked
-- -----------------------------------------------------------------------------
INSERT INTO person_certification (person_id, cert_id, issue_date, expiry_date, status)
VALUES ('PER-00001', 'CERT-001', '2024-01-10', '2027-01-10', 'Active'),
       ('PER-00001', 'CERT-005', '2025-03-01', '2027-03-01', 'Active'),
       ('PER-00002', 'CERT-001', '2024-02-01', '2027-02-01', 'Active'),
       ('PER-00002', 'CERT-004', '2025-01-15', '2027-01-15', 'Active'),
       ('PER-00003', 'CERT-001', '2025-09-01', '2028-09-01', 'Active'),
       ('PER-00004', 'CERT-002', '2024-05-01', '2027-05-01', 'Active'),
       ('PER-00005', 'CERT-003', '2025-02-01', '2026-12-01', 'Active'),
       ('PER-00006', 'CERT-003', '2025-06-01', '2027-06-01', 'Active'),
       ('PER-00006', 'CERT-005', '2023-06-01', '2026-06-01', 'Expired'),
       ('PER-00007', 'CERT-004', '2022-01-01', '2025-01-01', 'Expired'),
       ('PER-00009', 'CERT-001', '2025-09-15', '2026-11-30', 'Active'),
       ('PER-00009', 'CERT-003', '2025-10-01', '2027-10-01', 'Active'),
       ('PER-00010', 'CERT-005', '2025-11-01', '2027-11-01', 'Active'),
       ('PER-00010', 'CERT-006', '2026-01-10', '2028-01-10', 'Active'),
       ('PER-00011', 'CERT-004', '2025-10-01', '2027-10-01', 'Active'),
       ('PER-00012', 'CERT-001', '2024-09-01', '2026-09-01', 'Active'),
       ('PER-00013', 'CERT-001', '2025-10-01', '2027-10-01', 'Active'),
       ('PER-00014', 'CERT-002', '2024-03-01', '2026-12-20', 'Active'),
       ('PER-00015', 'CERT-003', '2025-03-01', '2027-03-01', 'Revoked'),
       ('PER-00018', 'CERT-003', '2026-02-01', '2028-02-01', 'Active'),
       ('PER-00019', 'CERT-001', '2026-09-01', '2027-09-01', 'Active'),
       ('PER-00020', 'CERT-001', '2024-01-01', '2027-12-31', 'Active'),
       ('PER-00020', 'CERT-003', '2024-01-01', '2027-12-31', 'Active'),
       ('PER-00020', 'CERT-005', '2025-01-01', '2027-12-31', 'Active'),
       ('PER-00020', 'CERT-006', '2025-01-01', '2027-12-31', 'Active'),
       ('PER-00021', 'CERT-003', '2026-09-01', '2026-12-31', 'Active'),
       ('PER-00022', 'CERT-004', '2025-05-01', '2028-05-01', 'Active'),
       ('PER-00022', 'CERT-005', '2025-05-01', '2028-05-01', 'Active'),
       ('PER-00022', 'CERT-006', '2025-05-01', '2028-05-01', 'Active'),
       ('PER-00003', 'CERT-002', '2026-01-05', '2026-12-05', 'Active');

-- -----------------------------------------------------------------------------
-- lab (7)
-- -----------------------------------------------------------------------------
INSERT INTO lab (lab_id, lab_name, building, room_number, hazard_level)
VALUES ('LAB-001', 'Computer Systems Lab',             'Building A', 'A-301', 'None'),
       ('LAB-002', 'Embedded Electronics Lab',         'Building A', 'A-205', 'Low'),
       ('LAB-003', 'Molecular Biology Lab',            'Building C', 'C-102', 'Medium'),
       ('LAB-004', 'Organic Synthesis Lab',            'Building B', 'B-210', 'High'),
       ('LAB-005', 'Materials Characterization Lab',   'Building D', 'D-110', 'Medium'),
       ('LAB-006', 'Analytical Chemistry Lab',         'Building B', 'B-105', 'Medium'),
       ('LAB-007', 'Hazardous Chemical Storage Vault', 'Building B', 'B-B01', 'High');

-- -----------------------------------------------------------------------------
-- equipment (17)
-- -----------------------------------------------------------------------------
INSERT INTO equipment (equipment_id, name, model, serial_number, purchase_date, status, lab_id)
VALUES ('EQP-001', 'High-Performance Workstation', 'Dell Precision 7960',          'SN-DP7960-0001',   '2024-03-15', 'Active',            'LAB-001'),
       ('EQP-002', 'GPU Server',                   'NVIDIA DGX Station A100',      'SN-DGXA100-0007',  '2023-08-20', 'Active',            'LAB-001'),
       ('EQP-003', 'Network Switch',               'Cisco Catalyst 9300',          'SN-C9300-1123',    '2022-05-10', 'Under Maintenance', 'LAB-001'),
       ('EQP-004', 'Digital Oscilloscope',         'Keysight DSOX3024T',           'SN-KS3024-5521',   '2023-02-01', 'Active',            'LAB-002'),
       ('EQP-005', 'FPGA Development Board',       'Xilinx Zynq ZCU104',           'SN-ZCU104-0042',   '2024-01-12', 'Active',            'LAB-002'),
       ('EQP-006', 'Soldering Station',            'Weller WX2021',                'SN-WX2021-3310',   '2021-09-09', 'Decommissioned',    'LAB-002'),
       ('EQP-007', 'PCR Thermal Cycler',           'Bio-Rad T100',                 'SN-T100-7781',     '2023-06-30', 'Active',            'LAB-003'),
       ('EQP-008', 'Biosafety Cabinet Class II',   'Esco Airstream AC2',           'SN-ESCOAC2-0210',  '2022-11-11', 'Active',            'LAB-003'),
       ('EQP-009', 'Refrigerated Centrifuge',      'Eppendorf 5810R',              'SN-EP5810R-0095',  '2024-04-04', 'Under Maintenance', 'LAB-003'),
       ('EQP-010', 'Rotary Evaporator',            'Buchi R-300',                  'SN-BR300-4410',    '2023-03-03', 'Active',            'LAB-004'),
       ('EQP-011', 'Fume Hood',                    'Labconco Protector XStream',   'SN-LCXS-8802',     '2020-07-07', 'Active',            'LAB-004'),
       ('EQP-012', 'NMR Spectrometer 400 MHz',     'Bruker Avance NEO 400',        'SN-BAN400-0012',   '2024-09-01', 'Active',            'LAB-004'),
       ('EQP-013', 'Scanning Electron Microscope', 'JEOL JSM-IT500',               'SN-JSM500-0331',   '2022-02-14', 'Active',            'LAB-005'),
       ('EQP-014', 'X-Ray Diffractometer',         'Rigaku MiniFlex 600',          'SN-RMF600-1209',   '2021-12-01', 'Active',            'LAB-005'),
       ('EQP-015', 'HPLC System',                  'Agilent 1260 Infinity II',     'SN-AG1260-6650',   '2023-10-10', 'Active',            'LAB-006'),
       ('EQP-016', 'UV-Vis Spectrophotometer',     'Shimadzu UV-1900i',            'SN-UV1900-2201',   '2024-02-20', 'Active',            'LAB-006'),
       ('EQP-017', 'Analytical Balance',           'Mettler Toledo XPR205',        NULL,               '2025-05-05', 'Active',            'LAB-006');

-- -----------------------------------------------------------------------------
-- chemical (16) - real CAS numbers
-- -----------------------------------------------------------------------------
INSERT INTO chemical (chemical_id, name, cas_number, hazard_class, quantity, unit, storage_location, lab_id)
VALUES ('CHM-001', 'Ethanol 96%',                 '64-17-5',   'Low',    20.000, 'L',  'Flammables Cabinet F1', 'LAB-003'),
       ('CHM-002', 'Agarose (molecular grade)',   '9012-36-6', 'None',  500.000, 'g',  'Shelf S2',              'LAB-003'),
       ('CHM-003', 'Formaldehyde solution 37%',   '50-00-0',   'High',    2.500, 'L',  'Toxics Cabinet T1',     'LAB-003'),
       ('CHM-004', 'Sulfuric acid 98%',           '7664-93-9', 'High',    5.000, 'L',  'Acid Cabinet A1',       'LAB-004'),
       ('CHM-005', 'Nitric acid 65%',             '7697-37-2', 'High',    2.500, 'L',  'Acid Cabinet A1',       'LAB-004'),
       ('CHM-006', 'Toluene',                     '108-88-3',  'Medium', 10.000, 'L',  'Flammables Cabinet F2', 'LAB-004'),
       ('CHM-007', 'Chloroform',                  '67-66-3',   'High',    4.000, 'L',  'Toxics Cabinet T2',     'LAB-004'),
       ('CHM-008', 'Acetone',                     '67-64-1',   'Low',    15.000, 'L',  'Flammables Cabinet F2', 'LAB-004'),
       ('CHM-009', 'Hydrochloric acid 37%',       '7647-01-0', 'Medium',  3.000, 'L',  'Acid Cabinet A2',       'LAB-006'),
       ('CHM-010', 'Sodium hydroxide pellets',    '1310-73-2', 'Medium',  2.000, 'kg', 'Base Cabinet B1',       'LAB-006'),
       ('CHM-011', 'Methanol (HPLC grade)',       '67-56-1',   'Medium',  8.000, 'L',  'Solvent Rack R1',       'LAB-006'),
       ('CHM-012', 'Acetonitrile (HPLC grade)',   '75-05-8',   'Medium',  6.000, 'L',  'Solvent Rack R1',       'LAB-006'),
       ('CHM-013', 'Isopropanol',                 '67-63-0',   'Low',     5.000, 'L',  'Cleaning Station',      'LAB-005'),
       ('CHM-014', 'Hydrofluoric acid 48%',       '7664-39-3', 'High',    0.500, 'L',  'HF Safety Cabinet',     'LAB-007'),
       ('CHM-015', 'Hydrogen peroxide 30%',       '7722-84-1', 'Medium',  4.000, 'L',  'Oxidizers Cabinet O1',  'LAB-007'),
       ('CHM-016', 'Sodium chloride',             '7647-14-5', 'None',    1.000, 'kg', 'Shelf S1',              'LAB-005');

-- -----------------------------------------------------------------------------
-- research_grant (7) - amounts in VND. PI auto-added to grant_member (T6).
-- -----------------------------------------------------------------------------
INSERT INTO research_grant (grant_id, title, funding_agency, amount, start_date, end_date, pi_id)
VALUES ('GRANT-001', 'Green Catalysts for Low-Temperature Organic Synthesis', 'NAFOSTED',                                2400000000.00, '2025-01-01', '2027-12-31', 'PER-00001'),
       ('GRANT-002', 'CRISPR-based Rapid Diagnostics for Tropical Diseases',  'Ministry of Science and Technology',      3800000000.00, '2024-06-01', '2027-05-31', 'PER-00002'),
       ('GRANT-003', 'Edge AI Accelerators for Smart Laboratory Monitoring',  'University Internal Research Fund',        650000000.00, '2026-01-15', '2027-01-14', 'PER-00003'),
       ('GRANT-004', 'Low-Power IoT Sensor Nodes for Hazard Detection',       'Samsung Global Research Outreach',        1200000000.00, '2025-09-01', '2026-08-31', 'PER-00004'),
       ('GRANT-005', 'Perovskite Thin Films for Next-Generation Solar Cells', 'VNU-HCM Research Program',                1750000000.00, '2026-03-01', '2028-02-28', 'PER-00005'),
       ('GRANT-006', 'Microplastic Detection in Mekong Delta Water Samples',  'JICA',                                    2100000000.00, '2026-11-01', '2028-10-31', 'PER-00001'),
       ('GRANT-007', 'HPLC Method Validation for Pharmaceutical Residues',    'NAFOSTED',                                 900000000.00, '2023-01-01', '2025-12-31', 'PER-00006');

-- -----------------------------------------------------------------------------
-- grant_member (non-PI members, 23 rows; + 7 PI rows created by trigger T6)
-- -----------------------------------------------------------------------------
INSERT INTO grant_member (grant_id, person_id, role_on_grant)
VALUES ('GRANT-001', 'PER-00006', 'Co-PI'),
       ('GRANT-001', 'PER-00009', 'Research Assistant'),
       ('GRANT-001', 'PER-00010', 'Research Assistant'),
       ('GRANT-001', 'PER-00020', 'Collaborator'),
       ('GRANT-002', 'PER-00007', 'Co-PI'),
       ('GRANT-002', 'PER-00011', 'Research Assistant'),
       ('GRANT-002', 'PER-00012', 'Research Assistant'),
       ('GRANT-002', 'PER-00019', 'Research Assistant'),
       ('GRANT-003', 'PER-00008', 'Co-PI'),
       ('GRANT-003', 'PER-00013', 'Research Assistant'),
       ('GRANT-003', 'PER-00017', 'Research Assistant'),
       ('GRANT-003', 'PER-00004', 'Collaborator'),
       ('GRANT-004', 'PER-00014', 'Research Assistant'),
       ('GRANT-004', 'PER-00003', 'Collaborator'),
       ('GRANT-005', 'PER-00015', 'Research Assistant'),
       ('GRANT-005', 'PER-00018', 'Research Assistant'),
       ('GRANT-005', 'PER-00021', 'Collaborator'),
       ('GRANT-006', 'PER-00010', 'Research Assistant'),
       ('GRANT-006', 'PER-00016', 'Research Assistant'),
       ('GRANT-006', 'PER-00022', 'Collaborator'),
       ('GRANT-007', 'PER-00009', 'Research Assistant'),
       ('GRANT-007', 'PER-00001', 'Collaborator'),
       ('GRANT-007', 'PER-00016', 'Research Assistant');

-- -----------------------------------------------------------------------------
-- access_log (48) - authorized_flag derived by trigger T1.
-- Expected DENIED events (flag = 0) are marked with  -- DENIED: reason
-- -----------------------------------------------------------------------------
INSERT INTO access_log (person_id, lab_id, equipment_id, chemical_id, access_timestamp, access_type)
VALUES -- Week 1 (2026-10-01 .. 2026-10-07)
       ('PER-00001', 'LAB-004', 'EQP-012', NULL,      '2026-10-01 08:05:00', 'Entry'),
       ('PER-00001', 'LAB-004', NULL,      NULL,      '2026-10-01 11:40:00', 'Exit'),
       ('PER-00010', 'LAB-004', NULL,      'CHM-007', '2026-10-01 08:30:00', 'Entry'),
       ('PER-00010', 'LAB-004', NULL,      NULL,      '2026-10-01 12:15:00', 'Exit'),
       ('PER-00016', 'LAB-004', NULL,      NULL,      '2026-10-01 09:10:00', 'Entry'),   -- DENIED: no certification
       ('PER-00003', 'LAB-001', 'EQP-002', NULL,      '2026-10-01 13:00:00', 'Entry'),
       ('PER-00003', 'LAB-001', NULL,      NULL,      '2026-10-01 17:30:00', 'Exit'),
       ('PER-00013', 'LAB-001', 'EQP-001', NULL,      '2026-10-02 08:00:00', 'Entry'),
       ('PER-00013', 'LAB-001', NULL,      NULL,      '2026-10-02 16:45:00', 'Exit'),
       ('PER-00008', 'LAB-001', NULL,      NULL,      '2026-10-02 09:20:00', 'Entry'),   -- authorized: None-level lab
       ('PER-00008', 'LAB-001', NULL,      NULL,      '2026-10-02 10:05:00', 'Exit'),
       ('PER-00002', 'LAB-003', 'EQP-007', NULL,      '2026-10-02 08:15:00', 'Entry'),
       ('PER-00002', 'LAB-003', NULL,      NULL,      '2026-10-02 12:00:00', 'Exit'),
       ('PER-00011', 'LAB-003', 'EQP-008', NULL,      '2026-10-02 13:10:00', 'Entry'),
       ('PER-00011', 'LAB-003', NULL,      NULL,      '2026-10-02 17:00:00', 'Exit'),
       ('PER-00012', 'LAB-002', NULL,      NULL,      '2026-10-03 09:00:00', 'Entry'),   -- DENIED: CERT-001 date-expired 2026-09-01
       ('PER-00004', 'LAB-002', 'EQP-004', NULL,      '2026-10-03 08:30:00', 'Entry'),
       ('PER-00004', 'LAB-002', NULL,      NULL,      '2026-10-03 11:30:00', 'Exit'),
       ('PER-00014', 'LAB-002', 'EQP-005', NULL,      '2026-10-03 13:00:00', 'Entry'),
       ('PER-00014', 'LAB-002', NULL,      NULL,      '2026-10-03 18:20:00', 'Exit'),
       ('PER-00006', 'LAB-004', NULL,      NULL,      '2026-10-05 10:00:00', 'Entry'),   -- DENIED: High cert status Expired
       ('PER-00005', 'LAB-005', 'EQP-013', NULL,      '2026-10-05 08:00:00', 'Entry'),
       ('PER-00005', 'LAB-005', NULL,      NULL,      '2026-10-05 15:00:00', 'Exit'),
       ('PER-00015', 'LAB-005', NULL,      NULL,      '2026-10-05 09:30:00', 'Entry'),   -- DENIED: Medium cert Revoked
       ('PER-00018', 'LAB-005', 'EQP-014', NULL,      '2026-10-06 08:45:00', 'Entry'),
       ('PER-00018', 'LAB-005', NULL,      NULL,      '2026-10-06 14:15:00', 'Exit'),
       ('PER-00020', 'LAB-007', NULL,      'CHM-014', '2026-10-06 07:30:00', 'Entry'),
       ('PER-00020', 'LAB-007', NULL,      NULL,      '2026-10-06 08:10:00', 'Exit'),
       ('PER-00011', 'LAB-003', NULL,      'CHM-003', '2026-10-07 10:00:00', 'Entry'),   -- DENIED: High chemical raises requirement above Medium clearance
       ('PER-00017', 'LAB-002', NULL,      NULL,      '2026-10-07 14:00:00', 'Entry'),   -- DENIED: no certification
       -- Week 2 (2026-10-08 .. 2026-10-14)
       ('PER-00009', 'LAB-006', 'EQP-015', NULL,      '2026-10-08 08:00:00', 'Entry'),
       ('PER-00009', 'LAB-006', NULL,      NULL,      '2026-10-08 12:30:00', 'Exit'),
       ('PER-00021', 'LAB-006', NULL,      'CHM-009', '2026-10-08 13:00:00', 'Entry'),
       ('PER-00021', 'LAB-006', NULL,      NULL,      '2026-10-08 16:00:00', 'Exit'),
       ('PER-00022', 'LAB-007', NULL,      NULL,      '2026-10-09 09:00:00', 'Entry'),
       ('PER-00022', 'LAB-007', NULL,      NULL,      '2026-10-09 09:45:00', 'Exit'),
       ('PER-00001', 'LAB-004', NULL,      'CHM-004', '2026-10-09 08:10:00', 'Entry'),
       ('PER-00001', 'LAB-004', NULL,      NULL,      '2026-10-09 10:40:00', 'Exit'),
       ('PER-00009', 'LAB-004', NULL,      NULL,      '2026-10-09 09:00:00', 'Entry'),   -- DENIED: Medium clearance in High lab
       ('PER-00010', 'LAB-004', 'EQP-010', NULL,      '2026-10-12 08:00:00', 'Entry'),
       ('PER-00010', 'LAB-004', NULL,      NULL,      '2026-10-12 17:10:00', 'Exit'),
       ('PER-00002', 'LAB-003', NULL,      NULL,      '2026-10-13 08:00:00', 'Entry'),
       ('PER-00002', 'LAB-003', NULL,      NULL,      '2026-10-13 10:30:00', 'Exit'),
       ('PER-00019', 'LAB-003', NULL,      NULL,      '2026-10-13 09:00:00', 'Entry'),   -- DENIED: Low clearance in Medium lab
       ('PER-00003', 'LAB-002', NULL,      NULL,      '2026-10-14 14:00:00', 'Entry'),
       ('PER-00013', 'LAB-001', 'EQP-002', NULL,      '2026-10-14 18:30:00', 'Entry'),   -- still inside (no Exit yet)
       ('PER-00020', 'LAB-004', 'EQP-011', NULL,      '2026-10-14 19:00:00', 'Entry'),   -- still inside (no Exit yet)
       ('PER-00005', 'LAB-005', NULL,      NULL,      '2026-10-14 20:15:00', 'Entry');   -- still inside (no Exit yet)

COMMIT;

-- -----------------------------------------------------------------------------
-- Row-count verification
-- -----------------------------------------------------------------------------
SELECT 'department'           AS table_name, COUNT(*) AS row_count FROM department
UNION ALL SELECT 'personnel',            COUNT(*) FROM personnel
UNION ALL SELECT 'faculty',              COUNT(*) FROM faculty
UNION ALL SELECT 'student',              COUNT(*) FROM student
UNION ALL SELECT 'certification',        COUNT(*) FROM certification
UNION ALL SELECT 'person_certification', COUNT(*) FROM person_certification
UNION ALL SELECT 'lab',                  COUNT(*) FROM lab
UNION ALL SELECT 'equipment',            COUNT(*) FROM equipment
UNION ALL SELECT 'chemical',             COUNT(*) FROM chemical
UNION ALL SELECT 'research_grant',       COUNT(*) FROM research_grant
UNION ALL SELECT 'grant_member',         COUNT(*) FROM grant_member
UNION ALL SELECT 'access_log',           COUNT(*) FROM access_log;
