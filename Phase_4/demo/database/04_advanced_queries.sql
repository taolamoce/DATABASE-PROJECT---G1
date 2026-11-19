-- =============================================================================
-- Project   : University Research & Lab Asset Tracker (INT1313 - Group G1)
-- Phase     : 3 - Implementation & Queries
-- Script    : 04_advanced_queries.sql
-- Purpose   : 12 complex analytical queries fulfilling Phase 3 requirements:
--             Multi-table JOINs, Subqueries, Aggregations, Window Functions,
--             and Common Table Expressions (CTEs).
-- DBMS      : MySQL 8.0.16+
-- Style     : SQLStyle.guide compliant
-- =============================================================================

USE lab_asset_tracker;

-- -----------------------------------------------------------------------------
-- Q01. Laboratory Asset Inventory & Operational Status Breakdown
-- Concept : Multi-table JOINs, conditional aggregations, CASE expressions.
-- Purpose : Provides lab managers an operational dashboard of active vs
--           under-maintenance equipment alongside chemical hazard footprints.
-- -----------------------------------------------------------------------------
SELECT l.lab_id,
       l.lab_name,
       l.building,
       l.hazard_level AS lab_hazard_level,
       COUNT(DISTINCT e.equipment_id) AS total_equipment,
       SUM(CASE WHEN e.status = 'Active' THEN 1 ELSE 0 END) AS active_equipment,
       SUM(CASE WHEN e.status = 'Under Maintenance' THEN 1 ELSE 0 END) AS maintenance_equipment,
       COUNT(DISTINCT ch.chemical_id) AS total_chemicals,
       COALESCE(ROUND(SUM(CASE WHEN ch.hazard_class = 'High' THEN ch.quantity ELSE 0 END), 2), 0.00) AS high_hazard_stock
  FROM lab AS l
       LEFT JOIN equipment AS e
              ON e.lab_id = l.lab_id
       LEFT JOIN chemical AS ch
              ON ch.lab_id = l.lab_id
 GROUP BY l.lab_id,
          l.lab_name,
          l.building,
          l.hazard_level
 ORDER BY total_equipment DESC, total_chemicals DESC;

-- -----------------------------------------------------------------------------
-- Q02. Unauthorized Access Incident Audit & Threat Classification
-- Concept : Multi-table JOIN, subquery comparison, CASE categorization.
-- Purpose : Security audit query identifying all denied lab entry attempts,
--           the exact certification deficiency, and risk severity rating.
-- -----------------------------------------------------------------------------
SELECT al.log_id,
       al.access_timestamp,
       p.person_id,
       p.full_name,
       p.person_type,
       l.lab_id,
       l.lab_name,
       l.hazard_level AS lab_hazard,
       COALESCE(ch.name, 'N/A') AS target_chemical,
       COALESCE(ch.hazard_class, 'N/A') AS chemical_hazard,
       GREATEST(fn_hazard_rank(l.hazard_level),
                COALESCE(fn_hazard_rank(ch.hazard_class), 0)) AS required_rank,
       fn_person_clearance(p.person_id, DATE(al.access_timestamp)) AS actual_clearance_rank,
       CASE
           WHEN fn_person_clearance(p.person_id, DATE(al.access_timestamp)) = 0 THEN 'Critical: No Safety Clearance'
           WHEN GREATEST(fn_hazard_rank(l.hazard_level), COALESCE(fn_hazard_rank(ch.hazard_class), 0)) -
                fn_person_clearance(p.person_id, DATE(al.access_timestamp)) >= 2 THEN 'High: Multiple Tier Gap'
           ELSE 'Moderate: Single Tier Gap'
       END AS risk_severity
  FROM access_log AS al
       INNER JOIN personnel AS p
               ON p.person_id = al.person_id
       INNER JOIN lab AS l
               ON l.lab_id = al.lab_id
       LEFT JOIN chemical AS ch
              ON ch.chemical_id = al.chemical_id
 WHERE al.authorized_flag = FALSE
 ORDER BY al.access_timestamp DESC;

-- -----------------------------------------------------------------------------
-- Q03. Research Grant Funding Distribution & Personnel Allocation
-- Concept : Aggregation, Window Functions (SUM() OVER), percentage calculation.
-- Purpose : Evaluates grant budget distribution across departments and
--           computes each grant's percentage share of total university research.
-- -----------------------------------------------------------------------------
SELECT rg.grant_id,
       rg.title,
       rg.funding_agency,
       d.dept_name AS host_department,
       pi.full_name AS principal_investigator,
       rg.amount AS grant_budget,
       COUNT(gm.person_id) AS total_team_members,
       ROUND(rg.amount / (SUM(rg.amount) OVER ()) * 100, 2) AS pct_of_total_funding,
       ROUND(rg.amount / NULLIF(COUNT(gm.person_id), 0), 2) AS budget_per_member
  FROM research_grant AS rg
       INNER JOIN faculty AS f
               ON f.person_id = rg.pi_id
       LEFT JOIN department AS d
              ON d.dept_id = f.dept_id
       INNER JOIN personnel AS pi
               ON pi.person_id = rg.pi_id
       LEFT JOIN grant_member AS gm
              ON gm.grant_id = rg.grant_id
 GROUP BY rg.grant_id,
          rg.title,
          rg.funding_agency,
          d.dept_name,
          pi.full_name,
          rg.amount
 ORDER BY rg.amount DESC;

-- -----------------------------------------------------------------------------
-- Q04. Safety Certification Expiration Timeline & Urgent Action List
-- Concept : Temporal filtering, DATEDIFF(), CASE expressions, multi-table JOIN.
-- Purpose : Proactively notifies personnel whose certifications expire within
--           60 days or have already expired, preventing lab access lockout.
-- -----------------------------------------------------------------------------
SELECT pc.person_id,
       p.full_name,
       p.email,
       p.person_type,
       c.cert_name,
       c.hazard_level,
       pc.issue_date,
       pc.expiry_date,
       DATEDIFF(pc.expiry_date, '2026-10-15') AS days_remaining,
       CASE
           WHEN pc.status = 'Revoked' THEN 'URGENT: Certification Revoked'
           WHEN pc.status = 'Expired' OR DATEDIFF(pc.expiry_date, '2026-10-15') < 0 THEN 'EXPIRED: Renewal Required'
           WHEN DATEDIFF(pc.expiry_date, '2026-10-15') <= 30 THEN 'CRITICAL: Expiring in <= 30 Days'
           WHEN DATEDIFF(pc.expiry_date, '2026-10-15') <= 60 THEN 'WARNING: Expiring in <= 60 Days'
           ELSE 'Active'
       END AS renewal_status
  FROM person_certification AS pc
       INNER JOIN personnel AS p
               ON p.person_id = pc.person_id
       INNER JOIN certification AS c
               ON c.cert_id = pc.cert_id
 WHERE DATEDIFF(pc.expiry_date, '2026-10-15') <= 60
    OR pc.status IN ('Expired', 'Revoked')
 ORDER BY days_remaining ASC;

-- -----------------------------------------------------------------------------
-- Q05. High-Frequency Lab Personnel Ranking by Activity Volume
-- Concept : Common Table Expression (CTE), Window Function (DENSE_RANK()).
-- Purpose : Identifies the top laboratory users per department to determine
--           resource allocation and heavy-user safety supervision.
-- -----------------------------------------------------------------------------
WITH lab_activity AS (
    SELECT p.person_id,
           p.full_name,
           p.person_type,
           COALESCE(d.dept_name, 'External / Unassigned') AS department_name,
           COUNT(al.log_id) AS total_access_events,
           SUM(CASE WHEN al.authorized_flag = TRUE THEN 1 ELSE 0 END) AS authorized_entries,
           SUM(CASE WHEN al.authorized_flag = FALSE THEN 1 ELSE 0 END) AS rejected_entries
      FROM personnel AS p
           LEFT JOIN faculty AS f
                  ON f.person_id = p.person_id
           LEFT JOIN student AS s
                  ON s.person_id = p.person_id
           LEFT JOIN faculty AS af
                  ON af.person_id = s.advisor_id
           LEFT JOIN department AS d
                  ON d.dept_id = COALESCE(f.dept_id, af.dept_id)
           INNER JOIN access_log AS al
                   ON al.person_id = p.person_id
     GROUP BY p.person_id,
              p.full_name,
              p.person_type,
              department_name
)
SELECT person_id,
       full_name,
       person_type,
       department_name,
       total_access_events,
       authorized_entries,
       rejected_entries,
       DENSE_RANK() OVER (ORDER BY total_access_events DESC) AS university_rank
  FROM lab_activity
 ORDER BY university_rank ASC, full_name ASC;

-- -----------------------------------------------------------------------------
-- Q06. Faculty Comprehensive Academic Profile (Research vs Mentorship)
-- Concept : EER subtype traversal, multiple LEFT JOINs, COUNT(DISTINCT).
-- Purpose : Generates annual faculty performance reviews balancing external
--           grant acquisition with graduate student mentorship responsibilities.
-- -----------------------------------------------------------------------------
SELECT f.person_id,
       p.full_name AS faculty_name,
       d.dept_name,
       f.tenure_status,
       f.office_location,
       COUNT(DISTINCT s.person_id) AS advised_students_count,
       COUNT(DISTINCT rg.grant_id) AS pi_grants_count,
       COALESCE(SUM(DISTINCT rg.amount), 0.00) AS total_pi_grant_funding,
       COUNT(DISTINCT gm.grant_id) AS total_grants_involved
  FROM faculty AS f
       INNER JOIN personnel AS p
               ON p.person_id = f.person_id
       LEFT JOIN department AS d
              ON d.dept_id = f.dept_id
       LEFT JOIN student AS s
              ON s.advisor_id = f.person_id
       LEFT JOIN research_grant AS rg
              ON rg.pi_id = f.person_id
       LEFT JOIN grant_member AS gm
              ON gm.person_id = f.person_id
 GROUP BY f.person_id,
          p.full_name,
          d.dept_name,
          f.tenure_status,
          f.office_location
 ORDER BY total_pi_grant_funding DESC, advised_students_count DESC;

-- -----------------------------------------------------------------------------
-- Q07. Current Real-Time Laboratory Occupancy Tracker
-- Concept : Correlated Subquery / Self-JOIN, finding unclosed 'Entry' events.
-- Purpose : In the event of emergency evacuation, provides real-time roster of
--           all persons currently inside laboratory buildings.
-- -----------------------------------------------------------------------------
SELECT al.log_id,
       al.person_id,
       p.full_name,
       p.phone,
       p.person_type,
       l.lab_id,
       l.lab_name,
       l.building,
       l.room_number,
       l.hazard_level,
       al.access_timestamp AS entry_time,
       TIMESTAMPDIFF(MINUTE, al.access_timestamp, '2026-10-15 00:00:00') AS minutes_inside
  FROM access_log AS al
       INNER JOIN personnel AS p
               ON p.person_id = al.person_id
       INNER JOIN lab AS l
               ON l.lab_id = al.lab_id
 WHERE al.access_type = 'Entry'
   AND al.authorized_flag = TRUE
   AND NOT EXISTS (
       SELECT 1
         FROM access_log AS ex
        WHERE ex.person_id = al.person_id
          AND ex.lab_id = al.lab_id
          AND ex.access_type = 'Exit'
          AND ex.access_timestamp > al.access_timestamp
   )
 ORDER BY al.access_timestamp ASC;

-- -----------------------------------------------------------------------------
-- Q08. Inter-Departmental Collaboration Matrix in Research Grants
-- Concept : Multi-hop JOIN, aggregation, filtering across faculty departments.
-- Purpose : Identifies research grants fostering cross-disciplinary collaboration
--           between distinct academic departments.
-- -----------------------------------------------------------------------------
SELECT rg.grant_id,
       rg.title,
       lead_dept.dept_name AS lead_department,
       COUNT(DISTINCT part_dept.dept_id) AS distinct_participating_departments,
       GROUP_CONCAT(DISTINCT part_dept.dept_name ORDER BY part_dept.dept_name SEPARATOR '; ') AS participating_departments,
       COUNT(DISTINCT gm.person_id) AS total_researchers
  FROM research_grant AS rg
       INNER JOIN faculty AS pi_f
               ON pi_f.person_id = rg.pi_id
       INNER JOIN department AS lead_dept
               ON lead_dept.dept_id = pi_f.dept_id
       INNER JOIN grant_member AS gm
               ON gm.grant_id = rg.grant_id
       LEFT JOIN faculty AS mem_f
              ON mem_f.person_id = gm.person_id
       LEFT JOIN student AS mem_s
              ON mem_s.person_id = gm.person_id
       LEFT JOIN faculty AS adv_f
              ON adv_f.person_id = mem_s.advisor_id
       LEFT JOIN department AS part_dept
              ON part_dept.dept_id = COALESCE(mem_f.dept_id, adv_f.dept_id)
 GROUP BY rg.grant_id,
          rg.title,
          lead_dept.dept_name
HAVING COUNT(DISTINCT part_dept.dept_id) > 1
 ORDER BY distinct_participating_departments DESC;

-- -----------------------------------------------------------------------------
-- Q09. Hazardous Chemical Handling Compliance: Handlers lacking High Clearance
-- Concept : Correlated Subquery with NOT EXISTS, Subquery Aggregation.
-- Purpose : Identifies personnel who accessed laboratories storing High-hazard
--           chemicals but do not hold High-tier safety certifications.
-- -----------------------------------------------------------------------------
SELECT DISTINCT
       p.person_id,
       p.full_name,
       p.person_type,
       p.email,
       l.lab_id,
       l.lab_name,
       l.hazard_level AS lab_hazard,
       fn_person_clearance(p.person_id, '2026-10-15') AS current_clearance_rank
  FROM access_log AS al
       INNER JOIN personnel AS p
               ON p.person_id = al.person_id
       INNER JOIN lab AS l
               ON l.lab_id = al.lab_id
 WHERE l.lab_id IN (
       SELECT DISTINCT ch.lab_id
         FROM chemical AS ch
        WHERE ch.hazard_class = 'High'
   )
   AND fn_person_clearance(p.person_id, '2026-10-15') < 3
 ORDER BY current_clearance_rank ASC, p.full_name ASC;

-- -----------------------------------------------------------------------------
-- Q10. Equipment Reliability & Maintenance Exposure Rate
-- Concept : Conditional aggregation, ratio computation, HAVING clause.
-- Purpose : Evaluates equipment failure rates per laboratory to guide
--           preventive maintenance budgets and capital asset replacement.
-- -----------------------------------------------------------------------------
SELECT l.lab_id,
       l.lab_name,
       l.building,
       COUNT(e.equipment_id) AS total_equipment,
       SUM(CASE WHEN e.status = 'Active' THEN 1 ELSE 0 END) AS active_units,
       SUM(CASE WHEN e.status = 'Under Maintenance' THEN 1 ELSE 0 END) AS maintenance_units,
       SUM(CASE WHEN e.status = 'Decommissioned' THEN 1 ELSE 0 END) AS retired_units,
       ROUND(SUM(CASE WHEN e.status = 'Under Maintenance' THEN 1 ELSE 0 END) /
             NULLIF(COUNT(e.equipment_id), 0) * 100, 1) AS maintenance_rate_pct
  FROM lab AS l
       LEFT JOIN equipment AS e
              ON e.lab_id = l.lab_id
 GROUP BY l.lab_id,
          l.lab_name,
          l.building
HAVING COUNT(e.equipment_id) > 0
 ORDER BY maintenance_rate_pct DESC, total_equipment DESC;

-- -----------------------------------------------------------------------------
-- Q11. Peak Hourly Laboratory Traffic Density & Capacity Planning
-- Concept : Temporal EXTRACT/HOUR function, conditional aggregations.
-- Purpose : Dissects access patterns across business hours to schedule
--           safety inspections during lowest-density windows.
-- -----------------------------------------------------------------------------
SELECT HOUR(al.access_timestamp) AS hour_of_day,
       COUNT(al.log_id) AS total_events,
       SUM(CASE WHEN al.access_type = 'Entry' THEN 1 ELSE 0 END) AS total_entries,
       SUM(CASE WHEN al.access_type = 'Exit' THEN 1 ELSE 0 END) AS total_exits,
       SUM(CASE WHEN al.authorized_flag = TRUE THEN 1 ELSE 0 END) AS authorized_events,
       SUM(CASE WHEN al.authorized_flag = FALSE THEN 1 ELSE 0 END) AS denied_events,
       ROUND(SUM(CASE WHEN al.authorized_flag = FALSE THEN 1 ELSE 0 END) /
             NULLIF(COUNT(al.log_id), 0) * 100, 1) AS denial_rate_pct
  FROM access_log AS al
 GROUP BY HOUR(al.access_timestamp)
 ORDER BY hour_of_day ASC;

-- -----------------------------------------------------------------------------
-- Q12. Comprehensive Departmental Research & Laboratory Summary
-- Concept : Multi-table outer joins, multiple CTEs, composite metrics.
-- Purpose : Executive university dashboard summarizing human capital,
--           grant funding, laboratories, and equipment assets by department.
-- -----------------------------------------------------------------------------
WITH dept_faculty AS (
    SELECT d.dept_id,
           COUNT(f.person_id) AS faculty_count
      FROM department AS d
           LEFT JOIN faculty AS f ON f.dept_id = d.dept_id
     GROUP BY d.dept_id
),
dept_grants AS (
    SELECT d.dept_id,
           COUNT(rg.grant_id) AS grant_count,
           COALESCE(SUM(rg.amount), 0.00) AS total_funding
      FROM department AS d
           LEFT JOIN faculty AS f ON f.dept_id = d.dept_id
           LEFT JOIN research_grant AS rg ON rg.pi_id = f.person_id
     GROUP BY d.dept_id
)
SELECT d.dept_id,
       d.dept_name,
       d.building,
       df.faculty_count,
       dg.grant_count,
       dg.total_funding
  FROM department AS d
       LEFT JOIN dept_faculty AS df ON df.dept_id = d.dept_id
       LEFT JOIN dept_grants AS dg ON dg.dept_id = d.dept_id
 ORDER BY dg.total_funding DESC;
