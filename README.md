# University Research & Lab Asset Tracker

*A database project for managing university research laboratories, research grants, laboratory assets, chemical inventory, safety certifications, and laboratory access records.*

## Table of Contents
1. [Overview](#overview)
2. [Project Objective](#project-objective)
3. [Project Scope](#project-scope)
4. [Functional Requirements](#functional-requirements)
5. [Non-Functional Requirements](#non-functional-requirements)
6. [Business Rules](#business-rules)
7. [Conceptual Database Design](#conceptual-database-design)
8. [Entity Overview](#entity-overview)
9. [Relationship Summary](#relationship-summary)
10. [Design Assumptions](#design-assumptions)
11. [Database Challenge](#database-challenge)
12. [Team Members](#team-members)

---

## Overview

The **University Research & Lab Asset Tracker** is designed to provide centralized management for university research laboratories.

Universities operate multiple laboratories that serve both faculty members and students. These laboratories contain high-value equipment and chemicals and may receive funding from different research grants and funding organizations.

In many cases, laboratory assets, chemical inventory, and access rights are managed manually using paper records or separate spreadsheets. This creates several problems:

- Difficulty controlling access to hazardous chemicals and restricted areas.
- Difficulty tracing equipment and chemicals during audits.
- Lack of mandatory checks to ensure that personnel have appropriate safety certifications.
- Insufficient links between personnel, research grants, laboratories, and laboratory assets.

The project addresses these problems by designing a relational database that integrates laboratory resources, personnel, research grants, certifications, and access logs into one system.

---

## Project Objective

The objective of this project is to design and build a relational database named **University Research & Lab Asset Tracker** for the centralized management of:

- Research grants
- Laboratory equipment
- Chemical inventory
- Faculty and student information
- Safety certifications
- Laboratory access records

A key objective is to ensure that only personnel with valid and unexpired safety certifications can access hazardous laboratories or chemicals.

This rule will be enforced directly at the database layer using an **SQL Trigger**.

---

## Project Scope

### In Scope

The system includes the management of:

- Departments
- Personnel
- Faculty members
- Students
- Safety certifications
- Research laboratories
- Equipment
- Chemicals
- Research grants
- Grant participants
- Laboratory access logs

### Out of Scope

The following systems are not included:

- Full university financial accounting
- Academic administration and course registration
- Complete human resources management

---

## Functional Requirements

The system must support the following functions:

- **FR1:** An Administrator can register new laboratory equipment and assign it to a specific laboratory.
- **FR2:** Faculty members can create and manage research grant records, including funding organization, grant amount, and project duration.
- **FR3:** The system records every laboratory access event, including timestamp and access type.
- **FR4:** The system validates a person's safety certification before allowing access to hazardous laboratories or chemicals.
- **FR5:** The system tracks chemical inventory, including quantity, storage location, and hazard classification.
- **FR6:** Multiple personnel members can participate in a research grant with roles such as PI, Co-PI, or Research Assistant.
- **FR7:** The system supports reporting queries such as:
  - Unauthorized access attempts
  - Equipment by laboratory
  - Chemicals and related certifications
  - Certifications nearing expiration

---

## Non-Functional Requirements

- **Security:** Certification data and personnel identification information must have strict access control. Encryption at rest is recommended for sensitive fields.
- **Performance:** Access-log audit queries should return results in under 200 ms with up to 100,000 records.
- **Availability:** The system should be available 24/7 because laboratories may be accessed outside normal working hours.
- **Data Integrity:** Certification validation for hazardous access must be enforced at the database layer and must not rely entirely on application logic.

---

## Business Rules

### Personnel & Certification

- **BR1:** Each `PERSONNEL` record has a unique `person_id`. A person may be specialized as either `FACULTY` or `STUDENT`. The specialization is **disjoint and partial**.
- **BR2:** Each Faculty member belongs to exactly one Department. A Department may contain many Faculty members.
- **BR3:** Each Student may have at most one Faculty advisor. A Faculty member may advise many Students.
- **BR4:** A Personnel member may hold zero or more Certifications, and a Certification may belong to many Personnel members through `PERSON_CERTIFICATION`.
- **BR5:** A Certification is valid only when the current date is between its `issue_date` and `expiry_date`.

### Laboratories, Equipment & Chemicals

- **BR6:** Each Equipment item belongs to exactly one Lab. A Lab may contain zero or more Equipment items.
- **BR7:** Each Chemical is stored in exactly one Lab. A Lab may store zero or more Chemicals.
- **BR8:** Each Lab and Chemical has a hazard level/class. If the hazard level is not `None`, only Personnel with a valid certification at the corresponding or higher hazard level may access it.

### Research Grants

- **BR9:** Each Research Grant has exactly one Principal Investigator, and the PI must be a Faculty member.
- **BR10:** A Faculty member may be the PI of multiple Research Grants.
- **BR11:** A Research Grant may have many participating Personnel members through `GRANT_MEMBER`.
- **BR12:** The grant amount must be greater than 0, and `end_date` must be later than `start_date`.

### Access Log

- **BR13:** Each `ACCESS_LOG` record must reference an existing Personnel member and Lab. It may optionally reference Equipment and/or Chemical.
- **BR14:** Each access event has an `access_type` of `Entry` or `Exit`. The `authorized_flag` is automatically determined based on certification validity.
- **BR15:** The system must not allow an access record to be inserted with `authorized_flag = TRUE` when the Personnel member does not have the required valid Certification.

---

## Conceptual Database Design

The conceptual model contains the following main entities:

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

The EER design also includes a specialization relationship:

```text
PERSONNEL
   |
   +-- FACULTY
   |
   +-- STUDENT
```

The specialization is:

- **Disjoint:** a Personnel member cannot be both Faculty and Student.
- **Partial:** a Personnel member may belong to neither subtype.

---

## Entity Overview

| Entity | Primary Key | Purpose |
|---|---|---|
| `DEPARTMENT` | `dept_id` | Department or unit responsible for managing faculty members. |
| `PERSONNEL` | `person_id` | Common supertype for personnel. |
| `FACULTY` | `person_id` | Faculty subtype; may act as PI and advise students. |
| `STUDENT` | `person_id` | Student subtype; may have a Faculty advisor. |
| `CERTIFICATION` | `cert_id` | Safety certification and authorized hazard-access level. |
| `PERSON_CERTIFICATION` | `person_id, cert_id` | Associative entity recording certifications issued to personnel and their validity. |
| `LAB` | `lab_id` | Laboratory with its own hazard level. |
| `EQUIPMENT` | `equipment_id` | Equipment assigned to a specific laboratory. |
| `CHEMICAL` | `chemical_id` | Chemical stored in a laboratory with a hazard class. |
| `RESEARCH_GRANT` | `grant_id` | Research grant managed by one PI. |
| `GRANT_MEMBER` | `grant_id, person_id` | Associative entity between grants and participating personnel. |
| `ACCESS_LOG` | `log_id` | Laboratory entry/exit record with authorization information. |

---

## Relationship Summary

| Relationship | Cardinality | Related Business Rule |
|---|---|---|
| `DEPARTMENT` - `FACULTY` | 1,1 - 0,N | BR2 |
| `FACULTY` - `STUDENT` | 0,1 - 0,N | BR3 |
| `PERSONNEL` - `PERSON_CERTIFICATION` - `CERTIFICATION` | N:N through associative entity | BR4, BR5 |
| `LAB` - `EQUIPMENT` | 1,1 - 0,N | BR6 |
| `LAB` - `CHEMICAL` | 1,1 - 0,N | BR7 |
| `FACULTY` - `RESEARCH_GRANT` | 1,1 - 1,N | BR9, BR10 |
| `RESEARCH_GRANT` - `GRANT_MEMBER` - `PERSONNEL` | N:N through associative entity | BR11 |
| `PERSONNEL` - `ACCESS_LOG` | 1,1 - 0,N | BR13 |
| `LAB` - `ACCESS_LOG` | 1,1 - 0,N | BR13 |
| `EQUIPMENT` - `ACCESS_LOG` | 0,1 - 0,N | BR13 |
| `CHEMICAL` - `ACCESS_LOG` | 0,1 - 0,N | BR13 |
| `PERSONNEL` - `FACULTY/STUDENT` | Disjoint, partial specialization | BR1 |

---

## Design Assumptions

- A Personnel member cannot be both Faculty and Student at the same time.
- A Research Grant has only one PI at a time.
- If the PI changes, the `pi_id` is updated.
- PI change history is not stored in Phase 1.
- Each Access Log record is associated with at most one Equipment item or one Chemical.
- Equipment and Chemical references in an Access Log are optional.
- Hazard levels use a consistent categorical scale across Lab, Chemical, and Certification.
- Example hazard levels may include:
  - `None`
  - `Low`
  - `Medium`
  - `High`

---

## Database Challenge

The main database challenge of this project is enforcing safe access to hazardous laboratories and chemicals.

Before inserting a new record into `ACCESS_LOG`, the database must check:

1. The Personnel member exists.
2. The related Lab or Chemical hazard level.
3. Whether the Personnel member has a valid Certification.
4. Whether the Certification level is sufficient for the requested hazard level.
5. Whether the Certification has expired.

The rule will be implemented using an SQL Trigger such as:

```sql
BEFORE INSERT ON ACCESS_LOG
```

The trigger will prevent unauthorized access from being recorded as authorized.

---

## Team Members

**Team G1**

- Phạm An
- Lâm Minh Chiến
- Đỗ Vương Bảo Anh

Course: **INT1313 - Databases**  
Phase: **Phase 1 - Conceptual Design**
