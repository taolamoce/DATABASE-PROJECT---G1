-- =============================================================================
-- Project   : University Research & Lab Asset Tracker (INT1313 - Group G1)
-- Phase     : 3 - Implementation & Queries
-- Script    : 05_verification_rbac.sql
-- Purpose   : Verification test cases (5.1) showing constraints & triggers
--             prevent bad data insertion, and Role-Based Access Control (5.2).
-- DBMS      : MySQL 8.0.16+
-- =============================================================================

USE lab_asset_tracker;

-- =============================================================================
-- 5.1 VERIFICATION TEST CASES (NEGATIVE & POSITIVE INTEGRITY TESTS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TC01: Prevent forged authorized access to High-hazard lab without certification
-- Target Rule : BR8, BR15 (Central DB Challenge)
-- Expected    : FAILS with SQLSTATE 45000: 'BR15: PER-00016 has no valid certification...'
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- INSERT INTO access_log (person_id, lab_id, access_timestamp, access_type, authorized_flag)
-- VALUES ('PER-00016', 'LAB-004', NOW(), 'Entry', TRUE);

-- -----------------------------------------------------------------------------
-- TC02: Prevent referencing equipment not physically housed in the specified lab
-- Target Rule : BR6, BR13
-- Expected    : FAILS with SQLSTATE 45000: 'BR6/BR13: equipment EQP-001 is not located in LAB-004'
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- INSERT INTO access_log (person_id, lab_id, equipment_id, access_timestamp, access_type)
-- VALUES ('PER-00001', 'LAB-004', 'EQP-001', NOW(), 'Entry');

-- -----------------------------------------------------------------------------
-- TC03: Prevent referencing chemical not physically stored in the specified lab
-- Target Rule : BR7, BR13
-- Expected    : FAILS with SQLSTATE 45000: 'BR7/BR13: chemical CHM-001 is not stored in LAB-004'
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- INSERT INTO access_log (person_id, lab_id, chemical_id, access_timestamp, access_type)
-- VALUES ('PER-00001', 'LAB-004', 'CHM-001', NOW(), 'Entry');

-- -----------------------------------------------------------------------------
-- TC04: Prevent referencing BOTH equipment and chemical in a single access event
-- Target Rule : BR13, Design Assumption 3.4
-- Expected    : FAILS with SQLSTATE 45000: 'BR13: an access event may reference one equipment item OR one chemical, not both'
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- INSERT INTO access_log (person_id, lab_id, equipment_id, chemical_id, access_timestamp, access_type)
-- VALUES ('PER-00001', 'LAB-004', 'EQP-010', 'CHM-004', NOW(), 'Entry');

-- -----------------------------------------------------------------------------
-- TC05: Prevent tampering with immutable audit trail (UPDATE on access_log)
-- Target Rule : NFR4 (Append-only audit integrity)
-- Expected    : FAILS with SQLSTATE 45000: 'NFR4: access_log is an append-only audit trail; UPDATE is not allowed'
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- UPDATE access_log SET authorized_flag = TRUE WHERE log_id = 5;

-- -----------------------------------------------------------------------------
-- TC06: Prevent inserting Student identity into Faculty subtype table
-- Target Rule : BR1 (Disjoint specialization)
-- Expected    : FAILS with SQLSTATE 45000: 'BR1: a FACULTY row requires personnel.person_type = ''Faculty'''
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- INSERT INTO faculty (person_id, dept_id, tenure_status, office_location)
-- VALUES ('PER-00009', 'DEPT-CHEM', 'Tenured', 'B-101');

-- -----------------------------------------------------------------------------
-- TC07: Prevent grant with non-positive funding amount or invalid dates
-- Target Rule : BR12, CHECK constraints ck_research_grant_amount / ck_research_grant_dates
-- Expected    : FAILS with Check constraint violation
-- -----------------------------------------------------------------------------
-- TEST EXECUTION (Amount <= 0):
-- INSERT INTO research_grant (grant_id, title, funding_agency, amount, start_date, end_date, pi_id)
-- VALUES ('GRANT-999', 'Invalid Grant', 'Test Agency', -5000.00, '2026-01-01', '2027-01-01', 'PER-00001');

-- TEST EXECUTION (End date <= Start date):
-- INSERT INTO research_grant (grant_id, title, funding_agency, amount, start_date, end_date, pi_id)
-- VALUES ('GRANT-998', 'Invalid Date Grant', 'Test Agency', 100000.00, '2027-01-01', '2026-01-01', 'PER-00001');

-- -----------------------------------------------------------------------------
-- TC08: Prevent malformed personnel email format
-- Target Rule : ISO/IEC 11179 Data Quality, CHECK constraint ck_personnel_email_format
-- Expected    : FAILS with Check constraint violation
-- -----------------------------------------------------------------------------
-- TEST EXECUTION:
-- INSERT INTO personnel (person_id, full_name, email, phone, person_type)
-- VALUES ('PER-99999', 'Bad Email User', 'invalid_email_format', NULL, 'Other');

-- -----------------------------------------------------------------------------
-- TC09 (Positive): Record rejected access event for security auditing
-- Target Rule : BR14, FR7 (Audit log must record unauthorized attempts with flag=FALSE)
-- Expected    : SUCCEEDS, authorized_flag is set to FALSE automatically by trigger.
-- -----------------------------------------------------------------------------
INSERT INTO access_log (person_id, lab_id, access_timestamp, access_type)
VALUES ('PER-00016', 'LAB-004', '2026-10-15 08:00:00', 'Entry');

-- Verify inserted record:
SELECT log_id, person_id, lab_id, access_type, authorized_flag
  FROM access_log
 WHERE person_id = 'PER-00016'
   AND lab_id = 'LAB-004'
   AND access_timestamp = '2026-10-15 08:00:00';

-- -----------------------------------------------------------------------------
-- TC10 (Positive): Record authorized access event for properly certified personnel
-- Target Rule : BR8, BR14 (PER-00001 has active High-level certification CERT-005)
-- Expected    : SUCCEEDS, authorized_flag is set to TRUE automatically by trigger.
-- -----------------------------------------------------------------------------
INSERT INTO access_log (person_id, lab_id, equipment_id, access_timestamp, access_type)
VALUES ('PER-00001', 'LAB-004', 'EQP-012', '2026-10-15 08:30:00', 'Entry');

-- Verify inserted record:
SELECT log_id, person_id, lab_id, equipment_id, access_type, authorized_flag
  FROM access_log
 WHERE person_id = 'PER-00001'
   AND lab_id = 'LAB-004'
   AND access_timestamp = '2026-10-15 08:30:00';

-- =============================================================================
-- 5.2 ROLE-BASED ACCESS CONTROL (RBAC) DEFINITION
-- =============================================================================

-- Drop existing roles if necessary
DROP ROLE IF EXISTS sec_admin_role;
DROP ROLE IF EXISTS lab_manager_role;
DROP ROLE IF EXISTS faculty_role;
DROP ROLE IF EXISTS student_role;
DROP ROLE IF EXISTS auditor_role;

-- -----------------------------------------------------------------------------
-- 1. Create Roles
-- -----------------------------------------------------------------------------
CREATE ROLE sec_admin_role;
CREATE ROLE lab_manager_role;
CREATE ROLE faculty_role;
CREATE ROLE student_role;
CREATE ROLE auditor_role;

-- -----------------------------------------------------------------------------
-- 2. Define Privileges per Role (Principle of Least Privilege)
-- -----------------------------------------------------------------------------

-- A. sec_admin_role: Full DDL/DML and User administration
GRANT ALL PRIVILEGES ON lab_asset_tracker.* TO sec_admin_role WITH GRANT OPTION;

-- B. lab_manager_role: Manage equipment, chemicals, view lab logs and safety views
GRANT SELECT, INSERT, UPDATE ON lab_asset_tracker.equipment TO lab_manager_role;
GRANT SELECT, INSERT, UPDATE ON lab_asset_tracker.chemical TO lab_manager_role;
GRANT SELECT ON lab_asset_tracker.lab TO lab_manager_role;
GRANT SELECT ON lab_asset_tracker.access_log TO lab_manager_role;
GRANT SELECT ON lab_asset_tracker.v_lab_inventory_summary TO lab_manager_role;
GRANT SELECT ON lab_asset_tracker.v_valid_certification TO lab_manager_role;
GRANT SELECT ON lab_asset_tracker.v_person_clearance TO lab_manager_role;

-- C. faculty_role: Research grant management, view advising, view lab views
GRANT SELECT, INSERT, UPDATE ON lab_asset_tracker.research_grant TO faculty_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_asset_tracker.grant_member TO faculty_role;
GRANT SELECT ON lab_asset_tracker.student TO faculty_role;
GRANT SELECT ON lab_asset_tracker.department TO faculty_role;
GRANT SELECT ON lab_asset_tracker.equipment TO faculty_role;
GRANT SELECT ON lab_asset_tracker.chemical TO faculty_role;
GRANT SELECT ON lab_asset_tracker.v_grant_overview TO faculty_role;
GRANT SELECT ON lab_asset_tracker.v_valid_certification TO faculty_role;

-- D. student_role: Read-only access to equipment catalog, chemical locations & self-clearance
GRANT SELECT ON lab_asset_tracker.equipment TO student_role;
GRANT SELECT (chemical_id, name, hazard_class, storage_location, lab_id) ON lab_asset_tracker.chemical TO student_role;
GRANT SELECT ON lab_asset_tracker.lab TO student_role;
GRANT SELECT ON lab_asset_tracker.v_valid_certification TO student_role;

-- E. auditor_role: Read-only audit access to security views and access log
GRANT SELECT ON lab_asset_tracker.access_log TO auditor_role;
GRANT SELECT ON lab_asset_tracker.v_unauthorized_access TO auditor_role;
GRANT SELECT ON lab_asset_tracker.v_valid_certification TO auditor_role;
GRANT SELECT ON lab_asset_tracker.v_person_clearance TO auditor_role;
GRANT SELECT ON lab_asset_tracker.v_lab_inventory_summary TO auditor_role;
GRANT SELECT ON lab_asset_tracker.person_certification TO auditor_role;
GRANT SELECT (person_id, full_name, email, person_type) ON lab_asset_tracker.personnel TO auditor_role;

-- -----------------------------------------------------------------------------
-- 3. Provision Sample Users & Role Binding
-- -----------------------------------------------------------------------------
DROP USER IF EXISTS 'dba_admin'@'localhost';
DROP USER IF EXISTS 'lab_mgr'@'localhost';
DROP USER IF EXISTS 'faculty_user'@'localhost';
DROP USER IF EXISTS 'student_user'@'localhost';
DROP USER IF EXISTS 'audit_officer'@'localhost';

CREATE USER 'dba_admin'@'localhost' IDENTIFIED BY 'Admin@Secure2026!';
CREATE USER 'lab_mgr'@'localhost' IDENTIFIED BY 'LabMgr@Secure2026!';
CREATE USER 'faculty_user'@'localhost' IDENTIFIED BY 'Faculty@Secure2026!';
CREATE USER 'student_user'@'localhost' IDENTIFIED BY 'Student@Secure2026!';
CREATE USER 'audit_officer'@'localhost' IDENTIFIED BY 'Audit@Secure2026!';

GRANT sec_admin_role   TO 'dba_admin'@'localhost';
GRANT lab_manager_role TO 'lab_mgr'@'localhost';
GRANT faculty_role     TO 'faculty_user'@'localhost';
GRANT student_role     TO 'student_user'@'localhost';
GRANT auditor_role     TO 'audit_officer'@'localhost';

-- Set default roles on logon
SET DEFAULT ROLE ALL TO 'dba_admin'@'localhost',
                        'lab_mgr'@'localhost',
                        'faculty_user'@'localhost',
                        'student_user'@'localhost',
                        'audit_officer'@'localhost';
