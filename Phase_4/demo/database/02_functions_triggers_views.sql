-- =============================================================================
-- Project   : University Research & Lab Asset Tracker (INT1313 - Group G1)
-- Phase     : 3 - Implementation & Queries
-- Script    : 02_functions_triggers_views.sql
-- Purpose   : Stored functions, triggers (business-rule enforcement) and views.
--             Must run BEFORE 03_seed_data_dml.sql so that every access_log row
--             gets its authorized_flag derived by the trigger.
-- DBMS      : MySQL 8.0.16+
-- =============================================================================

USE lab_asset_tracker;

DROP FUNCTION IF EXISTS fn_hazard_rank;
DROP FUNCTION IF EXISTS fn_person_clearance;
DROP TRIGGER  IF EXISTS trg_personnel_before_update;
DROP TRIGGER  IF EXISTS trg_faculty_before_insert;
DROP TRIGGER  IF EXISTS trg_student_before_insert;
DROP TRIGGER  IF EXISTS trg_research_grant_after_insert;
DROP TRIGGER  IF EXISTS trg_grant_member_before_insert;
DROP TRIGGER  IF EXISTS trg_access_log_before_insert;
DROP TRIGGER  IF EXISTS trg_access_log_before_update;

DELIMITER $$

-- =============================================================================
-- PART A. STORED FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- fn_hazard_rank: maps the shared hazard scale to an ordinal value so that
-- lab.hazard_level, chemical.hazard_class and certification.hazard_level
-- can be compared directly (Design Assumption 3.4, BR8).
-- -----------------------------------------------------------------------------
CREATE FUNCTION fn_hazard_rank (p_level VARCHAR(10))
RETURNS TINYINT UNSIGNED
DETERMINISTIC
NO SQL
COMMENT 'None=0, Low=1, Medium=2, High=3'
BEGIN
    RETURN CASE p_level
               WHEN 'Low'    THEN 1
               WHEN 'Medium' THEN 2
               WHEN 'High'   THEN 3
               ELSE 0
           END;
END$$

-- -----------------------------------------------------------------------------
-- fn_person_clearance: highest hazard rank a person is cleared for on a given
-- date. A certification counts only if status = 'Active' AND the date lies in
-- [issue_date, expiry_date] (BR5).
-- -----------------------------------------------------------------------------
CREATE FUNCTION fn_person_clearance (p_person_id VARCHAR(10), p_as_of DATE)
RETURNS TINYINT UNSIGNED
NOT DETERMINISTIC
READS SQL DATA
COMMENT 'Max valid certification rank of a person on a date (BR5, BR8)'
BEGIN
    DECLARE v_rank TINYINT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(fn_hazard_rank(c.hazard_level)), 0)
      INTO v_rank
      FROM person_certification AS pc
           INNER JOIN certification AS c
                   ON c.cert_id = pc.cert_id
     WHERE pc.person_id = p_person_id
       AND pc.status = 'Active'
       AND p_as_of BETWEEN pc.issue_date AND pc.expiry_date;

    RETURN v_rank;
END$$

-- =============================================================================
-- PART B. TRIGGERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- T1. trg_access_log_before_insert  (CENTRAL DB CHALLENGE - BR8, BR13-BR15)
--   1) An event references at most one item (equipment XOR chemical or none).
--   2) The referenced item must be located in the same lab (BR6, BR7, BR13).
--   3) required  = MAX(rank(lab.hazard_level), rank(chemical.hazard_class))
--      clearance = fn_person_clearance(person, DATE(access_timestamp))
--   4) clearance >= required  -> authorized_flag = TRUE
--      clearance <  required  -> authorized_flag = FALSE (attempt is logged
--                                for the FR7 audit report), but a client that
--                                tries to FORGE authorized_flag = TRUE is
--                                rejected with SQLSTATE 45000 (BR15).
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_access_log_before_insert
BEFORE INSERT ON access_log
FOR EACH ROW
BEGIN
    DECLARE v_lab_rank       TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_chemical_rank  TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_item_lab_id    VARCHAR(10)      DEFAULT NULL;
    DECLARE v_required_rank  TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_clearance_rank TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_message        VARCHAR(128);

    IF NEW.equipment_id IS NOT NULL AND NEW.chemical_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR13: an access event may reference one equipment item OR one chemical, not both';
    END IF;

    SELECT fn_hazard_rank(l.hazard_level)
      INTO v_lab_rank
      FROM lab AS l
     WHERE l.lab_id = NEW.lab_id;

    IF NEW.equipment_id IS NOT NULL THEN
        SELECT e.lab_id
          INTO v_item_lab_id
          FROM equipment AS e
         WHERE e.equipment_id = NEW.equipment_id;

        IF v_item_lab_id <> NEW.lab_id THEN
            SET v_message = CONCAT('BR6/BR13: equipment ', NEW.equipment_id, ' is not located in ', NEW.lab_id);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
        END IF;
    END IF;

    IF NEW.chemical_id IS NOT NULL THEN
        SELECT ch.lab_id,
               fn_hazard_rank(ch.hazard_class)
          INTO v_item_lab_id,
               v_chemical_rank
          FROM chemical AS ch
         WHERE ch.chemical_id = NEW.chemical_id;

        IF v_item_lab_id <> NEW.lab_id THEN
            SET v_message = CONCAT('BR7/BR13: chemical ', NEW.chemical_id, ' is not stored in ', NEW.lab_id);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
        END IF;
    END IF;

    SET v_required_rank  = GREATEST(v_lab_rank, v_chemical_rank);
    SET v_clearance_rank = fn_person_clearance(NEW.person_id, DATE(NEW.access_timestamp));

    IF v_clearance_rank >= v_required_rank THEN
        SET NEW.authorized_flag = TRUE;
    ELSEIF NEW.authorized_flag = TRUE THEN
        SET v_message = CONCAT('BR15: ', NEW.person_id, ' has no valid certification for the hazard level of ', NEW.lab_id);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    ELSE
        SET NEW.authorized_flag = FALSE;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- T2. trg_access_log_before_update  (NFR4 - audit trail is append-only)
-- Note: FK actions (ON DELETE SET NULL on equipment_id / chemical_id) do not
-- fire triggers in MySQL, so referential maintenance still works.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_access_log_before_update
BEFORE UPDATE ON access_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'NFR4: access_log is an append-only audit trail; UPDATE is not allowed';
END$$

-- -----------------------------------------------------------------------------
-- T3. trg_faculty_before_insert  (BR1 - disjoint specialization)
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_faculty_before_insert
BEFORE INSERT ON faculty
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1
                     FROM personnel AS p
                    WHERE p.person_id = NEW.person_id
                      AND p.person_type = 'Faculty') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR1: a FACULTY row requires personnel.person_type = ''Faculty''';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- T4. trg_student_before_insert  (BR1 - disjoint specialization)
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_student_before_insert
BEFORE INSERT ON student
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1
                     FROM personnel AS p
                    WHERE p.person_id = NEW.person_id
                      AND p.person_type = 'Student') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR1: a STUDENT row requires personnel.person_type = ''Student''';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- T5. trg_personnel_before_update  (BR1 - keep discriminator consistent)
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_personnel_before_update
BEFORE UPDATE ON personnel
FOR EACH ROW
BEGIN
    IF NEW.person_type <> OLD.person_type
       AND (   EXISTS (SELECT 1 FROM faculty AS f WHERE f.person_id = OLD.person_id)
            OR EXISTS (SELECT 1 FROM student AS s WHERE s.person_id = OLD.person_id)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR1: delete the subtype row before changing person_type';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- T6. trg_research_grant_after_insert  (BR9, FR6)
-- The PI is automatically registered as a GRANT_MEMBER with role 'PI'.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_research_grant_after_insert
AFTER INSERT ON research_grant
FOR EACH ROW
BEGIN
    INSERT INTO grant_member (grant_id, person_id, role_on_grant)
    VALUES (NEW.grant_id, NEW.pi_id, 'PI');
END$$

-- -----------------------------------------------------------------------------
-- T7. trg_grant_member_before_insert  (BR9 - only the grant's PI holds role PI)
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_grant_member_before_insert
BEFORE INSERT ON grant_member
FOR EACH ROW
BEGIN
    IF NEW.role_on_grant = 'PI'
       AND NOT EXISTS (SELECT 1
                         FROM research_grant AS rg
                        WHERE rg.grant_id = NEW.grant_id
                          AND rg.pi_id = NEW.person_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR9: role PI is reserved for research_grant.pi_id of this grant';
    END IF;
END$$

DELIMITER ;

-- =============================================================================
-- PART C. VIEWS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- V1. v_valid_certification - certifications valid today (BR5)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_valid_certification AS
SELECT pc.person_id,
       p.full_name,
       p.person_type,
       c.cert_id,
       c.cert_name,
       c.hazard_level,
       pc.issue_date,
       pc.expiry_date,
       DATEDIFF(pc.expiry_date, CURDATE()) AS days_to_expiry
  FROM person_certification AS pc
       INNER JOIN personnel AS p
               ON p.person_id = pc.person_id
       INNER JOIN certification AS c
               ON c.cert_id = pc.cert_id
 WHERE pc.status = 'Active'
   AND CURDATE() BETWEEN pc.issue_date AND pc.expiry_date;

-- -----------------------------------------------------------------------------
-- V2. v_person_clearance - current highest clearance of every person (BR8)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_person_clearance AS
SELECT p.person_id,
       p.full_name,
       p.person_type,
       COALESCE(MAX(fn_hazard_rank(vc.hazard_level)), 0) AS clearance_rank,
       CASE COALESCE(MAX(fn_hazard_rank(vc.hazard_level)), 0)
           WHEN 3 THEN 'High'
           WHEN 2 THEN 'Medium'
           WHEN 1 THEN 'Low'
           ELSE 'None'
       END AS clearance_level,
       COUNT(vc.cert_id) AS valid_cert_count
  FROM personnel AS p
       LEFT JOIN v_valid_certification AS vc
              ON vc.person_id = p.person_id
 GROUP BY p.person_id,
          p.full_name,
          p.person_type;

-- -----------------------------------------------------------------------------
-- V3. v_unauthorized_access - audit view of rejected attempts (FR7, BR15)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_unauthorized_access AS
SELECT al.log_id,
       al.access_timestamp,
       al.access_type,
       p.person_id,
       p.full_name,
       p.person_type,
       l.lab_id,
       l.lab_name,
       l.hazard_level AS lab_hazard_level,
       ch.name AS chemical_name,
       ch.hazard_class AS chemical_hazard_class,
       GREATEST(fn_hazard_rank(l.hazard_level),
                COALESCE(fn_hazard_rank(ch.hazard_class), 0)) AS required_rank,
       fn_person_clearance(al.person_id, DATE(al.access_timestamp)) AS clearance_rank_at_event
  FROM access_log AS al
       INNER JOIN personnel AS p
               ON p.person_id = al.person_id
       INNER JOIN lab AS l
               ON l.lab_id = al.lab_id
       LEFT JOIN chemical AS ch
              ON ch.chemical_id = al.chemical_id
 WHERE al.authorized_flag = FALSE;

-- -----------------------------------------------------------------------------
-- V4. v_lab_inventory_summary - assets per lab (FR1, FR5, FR7)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_lab_inventory_summary AS
SELECT l.lab_id,
       l.lab_name,
       l.building,
       l.room_number,
       l.hazard_level,
       COALESCE(eq.equipment_total, 0)  AS equipment_total,
       COALESCE(eq.equipment_active, 0) AS equipment_active,
       COALESCE(cm.chemical_count, 0)   AS chemical_count,
       COALESCE(cm.max_chemical_hazard, 'None') AS max_chemical_hazard
  FROM lab AS l
       LEFT JOIN (SELECT e.lab_id,
                         COUNT(*) AS equipment_total,
                         SUM(e.status = 'Active') AS equipment_active
                    FROM equipment AS e
                   GROUP BY e.lab_id) AS eq
              ON eq.lab_id = l.lab_id
       LEFT JOIN (SELECT ch.lab_id,
                         COUNT(*) AS chemical_count,
                         CASE MAX(fn_hazard_rank(ch.hazard_class))
                             WHEN 3 THEN 'High'
                             WHEN 2 THEN 'Medium'
                             WHEN 1 THEN 'Low'
                             ELSE 'None'
                         END AS max_chemical_hazard
                    FROM chemical AS ch
                   GROUP BY ch.lab_id) AS cm
              ON cm.lab_id = l.lab_id;

-- -----------------------------------------------------------------------------
-- V5. v_grant_overview - grant, PI, department, team size, lifecycle (FR2, FR6)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_grant_overview AS
SELECT rg.grant_id,
       rg.title,
       rg.funding_agency,
       rg.amount,
       rg.start_date,
       rg.end_date,
       pi.full_name AS pi_name,
       d.dept_name  AS pi_department,
       (SELECT COUNT(*)
          FROM grant_member AS gm
         WHERE gm.grant_id = rg.grant_id) AS member_count,
       CASE
           WHEN CURDATE() < rg.start_date THEN 'Upcoming'
           WHEN CURDATE() > rg.end_date   THEN 'Completed'
           ELSE 'Active'
       END AS grant_status
  FROM research_grant AS rg
       INNER JOIN personnel AS pi
               ON pi.person_id = rg.pi_id
       INNER JOIN faculty AS f
               ON f.person_id = rg.pi_id
       LEFT JOIN department AS d
              ON d.dept_id = f.dept_id;
