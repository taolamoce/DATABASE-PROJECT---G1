-- =============================================================================
-- Project   : University Research & Lab Asset Tracker (INT1313 - Group G1)
-- Phase     : 3 - Implementation & Queries
-- Script    : 01_schema_ddl.sql
-- Purpose   : Create the database, all 12 base tables, constraints and indexes.
-- DBMS      : MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16)
-- Style     : SQLStyle.guide - UPPERCASE keywords, lowercase snake_case names
-- Run order : 01 -> 02 -> 03 -> 04 -> 05 (-> 06 optional performance test)
-- =============================================================================

DROP DATABASE IF EXISTS lab_asset_tracker;

CREATE DATABASE lab_asset_tracker
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE lab_asset_tracker;

-- Strict mode: invalid ENUM values / truncation raise errors instead of warnings.
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------------------------------
-- 1. department  (BR2)
-- -----------------------------------------------------------------------------
CREATE TABLE department (
    dept_id         VARCHAR(10)     NOT NULL,
    dept_name       VARCHAR(100)    NOT NULL,
    building        VARCHAR(50)     NULL DEFAULT NULL,

    CONSTRAINT pk_department PRIMARY KEY (dept_id),
    CONSTRAINT uq_department_name UNIQUE (dept_name),
    CONSTRAINT ck_department_id_format CHECK (dept_id REGEXP '^DEPT-[A-Z]{2,5}$')
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 2. personnel  (supertype - BR1)
-- -----------------------------------------------------------------------------
CREATE TABLE personnel (
    person_id       VARCHAR(10)     NOT NULL,
    full_name       VARCHAR(150)    NOT NULL,
    email           VARCHAR(100)    NOT NULL,
    phone           VARCHAR(20)     NULL DEFAULT NULL,
    person_type     ENUM('Faculty', 'Student', 'Other') NOT NULL DEFAULT 'Other',

    CONSTRAINT pk_personnel PRIMARY KEY (person_id),
    CONSTRAINT uq_personnel_email UNIQUE (email),
    CONSTRAINT ck_personnel_id_format CHECK (person_id REGEXP '^PER-[0-9]{5}$'),
    CONSTRAINT ck_personnel_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 3. faculty  (subtype of personnel - EER Method 8A, BR1, BR2)
-- -----------------------------------------------------------------------------
CREATE TABLE faculty (
    person_id       VARCHAR(10)     NOT NULL,
    dept_id         VARCHAR(10)     NULL DEFAULT NULL,
    tenure_status   ENUM('Tenured', 'Tenure-Track', 'Adjunct', 'Emeritus') NOT NULL DEFAULT 'Adjunct',
    office_location VARCHAR(50)     NULL DEFAULT NULL,

    CONSTRAINT pk_faculty PRIMARY KEY (person_id),
    CONSTRAINT fk_faculty_personnel
        FOREIGN KEY (person_id) REFERENCES personnel (person_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_faculty_department
        FOREIGN KEY (dept_id) REFERENCES department (dept_id)
        ON DELETE SET NULL
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 4. student  (subtype of personnel - BR1, BR3)
-- -----------------------------------------------------------------------------
CREATE TABLE student (
    person_id       VARCHAR(10)     NOT NULL,
    program         VARCHAR(100)    NOT NULL,
    enrollment_year SMALLINT        NOT NULL,
    advisor_id      VARCHAR(10)     NULL DEFAULT NULL,

    CONSTRAINT pk_student PRIMARY KEY (person_id),
    CONSTRAINT fk_student_personnel
        FOREIGN KEY (person_id) REFERENCES personnel (person_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_student_advisor
        FOREIGN KEY (advisor_id) REFERENCES faculty (person_id)
        ON DELETE SET NULL,
    CONSTRAINT ck_student_enrollment_year CHECK (enrollment_year BETWEEN 2000 AND 2100)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 5. certification  (BR4, BR8)
-- -----------------------------------------------------------------------------
CREATE TABLE certification (
    cert_id         VARCHAR(10)     NOT NULL,
    cert_name       VARCHAR(100)    NOT NULL,
    hazard_level    ENUM('None', 'Low', 'Medium', 'High') NOT NULL DEFAULT 'None',
    description     TEXT            NULL,

    CONSTRAINT pk_certification PRIMARY KEY (cert_id),
    CONSTRAINT uq_certification_name UNIQUE (cert_name),
    CONSTRAINT ck_certification_id_format CHECK (cert_id REGEXP '^CERT-[0-9]{3}$')
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 6. person_certification  (associative N:N - BR4, BR5)
-- -----------------------------------------------------------------------------
CREATE TABLE person_certification (
    person_id       VARCHAR(10)     NOT NULL,
    cert_id         VARCHAR(10)     NOT NULL,
    issue_date      DATE            NOT NULL,
    expiry_date     DATE            NOT NULL,
    status          ENUM('Active', 'Expired', 'Revoked') NOT NULL DEFAULT 'Active',

    CONSTRAINT pk_person_certification PRIMARY KEY (person_id, cert_id),
    CONSTRAINT fk_person_certification_personnel
        FOREIGN KEY (person_id) REFERENCES personnel (person_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_person_certification_certification
        FOREIGN KEY (cert_id) REFERENCES certification (cert_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_person_certification_dates CHECK (expiry_date > issue_date)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 7. lab  (BR6, BR7, BR8)
-- -----------------------------------------------------------------------------
CREATE TABLE lab (
    lab_id          VARCHAR(10)     NOT NULL,
    lab_name        VARCHAR(100)    NOT NULL,
    building        VARCHAR(50)     NOT NULL,
    room_number     VARCHAR(20)     NOT NULL,
    hazard_level    ENUM('None', 'Low', 'Medium', 'High') NOT NULL DEFAULT 'None',

    CONSTRAINT pk_lab PRIMARY KEY (lab_id),
    CONSTRAINT uq_lab_name UNIQUE (lab_name),
    CONSTRAINT uq_lab_location UNIQUE (building, room_number),
    CONSTRAINT ck_lab_id_format CHECK (lab_id REGEXP '^LAB-[0-9]{3}$')
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 8. equipment  (BR6, FR1)
-- -----------------------------------------------------------------------------
CREATE TABLE equipment (
    equipment_id    VARCHAR(10)     NOT NULL,
    name            VARCHAR(100)    NOT NULL,
    model           VARCHAR(100)    NULL DEFAULT NULL,
    serial_number   VARCHAR(50)     NULL DEFAULT NULL,
    purchase_date   DATE            NULL DEFAULT NULL,
    status          ENUM('Active', 'Under Maintenance', 'Decommissioned') NOT NULL DEFAULT 'Active',
    lab_id          VARCHAR(10)     NOT NULL,

    CONSTRAINT pk_equipment PRIMARY KEY (equipment_id),
    CONSTRAINT uq_equipment_serial_number UNIQUE (serial_number),
    CONSTRAINT fk_equipment_lab
        FOREIGN KEY (lab_id) REFERENCES lab (lab_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_equipment_id_format CHECK (equipment_id REGEXP '^EQP-[0-9]{3}$'),
    CONSTRAINT ck_equipment_purchase_date CHECK (purchase_date >= '1990-01-01')
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 9. chemical  (BR7, BR8, FR5)
-- -----------------------------------------------------------------------------
CREATE TABLE chemical (
    chemical_id     VARCHAR(10)     NOT NULL,
    name            VARCHAR(150)    NOT NULL,
    cas_number      VARCHAR(20)     NULL DEFAULT NULL,
    hazard_class    ENUM('None', 'Low', 'Medium', 'High') NOT NULL DEFAULT 'None',
    quantity        DECIMAL(10, 3)  NOT NULL DEFAULT 0.000,
    unit            VARCHAR(20)     NOT NULL,
    storage_location VARCHAR(100)   NULL DEFAULT NULL,
    lab_id          VARCHAR(10)     NOT NULL,

    CONSTRAINT pk_chemical PRIMARY KEY (chemical_id),
    CONSTRAINT uq_chemical_cas_number UNIQUE (cas_number),
    CONSTRAINT fk_chemical_lab
        FOREIGN KEY (lab_id) REFERENCES lab (lab_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_chemical_id_format CHECK (chemical_id REGEXP '^CHM-[0-9]{3}$'),
    CONSTRAINT ck_chemical_quantity CHECK (quantity >= 0),
    CONSTRAINT ck_chemical_cas_format CHECK (cas_number REGEXP '^[0-9]{2,7}-[0-9]{2}-[0-9]$'),
    CONSTRAINT ck_chemical_unit CHECK (unit IN ('mL', 'L', 'g', 'kg', 'mg'))
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 10. research_grant  (BR9, BR10, BR12, FR2)
-- -----------------------------------------------------------------------------
CREATE TABLE research_grant (
    grant_id        VARCHAR(10)     NOT NULL,
    title           VARCHAR(200)    NOT NULL,
    funding_agency  VARCHAR(150)    NOT NULL,
    amount          DECIMAL(15, 2)  NOT NULL,
    start_date      DATE            NOT NULL,
    end_date        DATE            NOT NULL,
    pi_id           VARCHAR(10)     NOT NULL,

    CONSTRAINT pk_research_grant PRIMARY KEY (grant_id),
    CONSTRAINT fk_research_grant_pi
        FOREIGN KEY (pi_id) REFERENCES faculty (person_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_research_grant_id_format CHECK (grant_id REGEXP '^GRANT-[0-9]{3}$'),
    CONSTRAINT ck_research_grant_amount CHECK (amount > 0),
    CONSTRAINT ck_research_grant_dates CHECK (end_date > start_date)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 11. grant_member  (associative N:N - BR11, FR6)
-- -----------------------------------------------------------------------------
CREATE TABLE grant_member (
    grant_id        VARCHAR(10)     NOT NULL,
    person_id       VARCHAR(10)     NOT NULL,
    role_on_grant   ENUM('PI', 'Co-PI', 'Research Assistant', 'Collaborator') NOT NULL DEFAULT 'Research Assistant',

    CONSTRAINT pk_grant_member PRIMARY KEY (grant_id, person_id),
    CONSTRAINT fk_grant_member_grant
        FOREIGN KEY (grant_id) REFERENCES research_grant (grant_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_grant_member_personnel
        FOREIGN KEY (person_id) REFERENCES personnel (person_id)
        ON DELETE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 12. access_log  (BR13, BR14, BR15, FR3, FR4)
--     authorized_flag is ALWAYS derived by trg_access_log_before_insert.
-- -----------------------------------------------------------------------------
CREATE TABLE access_log (
    log_id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    person_id       VARCHAR(10)     NOT NULL,
    lab_id          VARCHAR(10)     NOT NULL,
    equipment_id    VARCHAR(10)     NULL DEFAULT NULL,
    chemical_id     VARCHAR(10)     NULL DEFAULT NULL,
    access_timestamp DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    access_type     ENUM('Entry', 'Exit') NOT NULL,
    authorized_flag BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_access_log PRIMARY KEY (log_id),
    CONSTRAINT fk_access_log_personnel
        FOREIGN KEY (person_id) REFERENCES personnel (person_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_access_log_lab
        FOREIGN KEY (lab_id) REFERENCES lab (lab_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_access_log_equipment
        FOREIGN KEY (equipment_id) REFERENCES equipment (equipment_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_access_log_chemical
        FOREIGN KEY (chemical_id) REFERENCES chemical (chemical_id)
        ON DELETE SET NULL
) ENGINE = InnoDB;

-- =============================================================================
-- Secondary indexes (NFR2 - audit queries < 200 ms on 100,000 log rows)
-- InnoDB automatically indexes FK columns; composite indexes below start with
-- the FK column, so they also serve as the FK index.
-- =============================================================================
CREATE INDEX idx_access_log_person_time  ON access_log (person_id, access_timestamp);
CREATE INDEX idx_access_log_lab_time     ON access_log (lab_id, access_timestamp);
CREATE INDEX idx_access_log_auth_time    ON access_log (authorized_flag, access_timestamp);
CREATE INDEX idx_person_cert_expiry      ON person_certification (expiry_date, status);
CREATE INDEX idx_equipment_lab_status    ON equipment (lab_id, status);
CREATE INDEX idx_chemical_lab_hazard     ON chemical (lab_id, hazard_class);
CREATE INDEX idx_research_grant_pi_dates ON research_grant (pi_id, start_date, end_date);
CREATE INDEX idx_personnel_type          ON personnel (person_type);
