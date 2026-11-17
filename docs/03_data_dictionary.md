# Data Dictionary

**Project:** Quran Students Analytics
**Database:** PostgreSQL, database `quran_analytics`, schema `quran`
**Version:** 1.0
**Privacy note:** all identifiers are anonymous codes. No real names, phone numbers, addresses or birth dates are stored.

---

## 1. Overview

| Table | Description | Grain (one row = ...) |
|---|---|---|
| `surahs` | Reference list of the 114 surahs | one surah |
| `teachers` | Teachers (anonymous) | one teacher |
| `groups` | Classes taught by a teacher | one group |
| `students` | Students (anonymous) | one student |
| `enrollments` | History of which student belongs to which group | one student in one group for a period |
| `sessions` | Class sessions held by a group | one group on one date |
| `attendance` | Attendance status of each student in each session | one student in one session |
| `evaluations` | Recitation records (new memorization, review, tajweed, recitation) | one evaluated passage for one student in one session |

## 2. Relationships

```
teachers 1 --- N groups
groups   1 --- N enrollments N --- 1 students
groups   1 --- N sessions
sessions 1 --- N attendance  N --- 1 students
sessions 1 --- N evaluations N --- 1 students
surahs   1 --- N evaluations
```

- A teacher leads many groups.
- A student can belong to different groups over time (history in `enrollments`).
- A session belongs to one group; each enrolled student has one `attendance` row per session.
- An evaluation belongs to one student, one session and one surah.

---

## 3. Table details

### 3.1 `surahs`

Reference table loaded once (114 rows, 6,236 ayahs in total).

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `surah_number` | SMALLINT | No | Number of the surah in the Quran | `2` | Primary key, 1 to 114 |
| `name_en` | VARCHAR(50) | No | English transliterated name | `Al-Baqarah` | |
| `name_ar` | VARCHAR(50) | Yes | Arabic name | `البقرة` | |
| `ayah_count` | SMALLINT | No | Number of ayahs in the surah | `286` | Greater than 0 |

### 3.2 `teachers`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `teacher_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `teacher_code` | VARCHAR(10) | No | Anonymous teacher code | `T001` | Unique |
| `join_date` | DATE | No | Date the teacher started at the school | `2023-09-01` | |

### 3.3 `groups`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `group_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `group_name` | VARCHAR(50) | No | Name of the group | `Beginners A` | |
| `teacher_id` | INTEGER | No | Teacher leading the group | `1` | Foreign key to `teachers` |
| `level` | VARCHAR(20) | Yes | Level of the group | `beginner` | `beginner`, `intermediate` or `advanced` |
| `weekday` | SMALLINT | Yes | Usual day of the session (1 = Monday, 7 = Sunday) | `6` | 1 to 7 |
| `start_time` | TIME | Yes | Usual start time | `16:00` | |

### 3.4 `students`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `student_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `student_code` | VARCHAR(10) | No | Anonymous student code | `S0001` | Unique |
| `age_band` | VARCHAR(10) | Yes | Age range instead of exact age | `10-13` | `6-9`, `10-13`, `14-17` or `18+` |
| `gender` | CHAR(1) | Yes | Gender (used only for group-level analysis) | `F` | `F` or `M` |
| `enrollment_date` | DATE | No | Date the student joined the program | `2024-09-15` | |
| `starting_level` | VARCHAR(20) | Yes | Level at enrollment | `beginner` | |
| `status` | VARCHAR(15) | No | Current status | `active` | `active`, `dropped`, `graduated` or `paused`; default `active` |
| `exit_date` | DATE | Yes | Date the student left (if applicable) | `2025-03-10` | Empty for active students |
| `exit_reason` | VARCHAR(50) | Yes | General reason for leaving | `moved` | Categories only, no free text with personal details |

### 3.5 `enrollments`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `enrollment_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `student_id` | INTEGER | No | Student | `1` | Foreign key to `students` |
| `group_id` | INTEGER | No | Group | `1` | Foreign key to `groups` |
| `start_date` | DATE | No | Date the student joined this group | `2024-09-15` | |
| `end_date` | DATE | Yes | Date the student left this group | `2025-01-31` | Empty if still in the group; must be on or after `start_date` |

### 3.6 `sessions`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `session_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `group_id` | INTEGER | No | Group that held the session | `1` | Foreign key to `groups` |
| `session_date` | DATE | No | Date of the session | `2025-02-08` | Unique per group and date |
| `duration_min` | SMALLINT | Yes | Length of the session in minutes | `90` | Greater than 0 |

### 3.7 `attendance`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `session_id` | INTEGER | No | Session | `1` | Part of primary key; foreign key to `sessions` |
| `student_id` | INTEGER | No | Student | `1` | Part of primary key; foreign key to `students` |
| `status` | VARCHAR(10) | No | Attendance status | `present` | `present`, `absent` (unexcused) or `excused` (excused absence) |

Rules:
- There is **one row per enrolled student per session**, including absences. Without absence rows, the attendance rate cannot be calculated correctly.
- `excused` is excluded from the denominator of the attendance rate (see Metrics Glossary, M3).

### 3.8 `evaluations`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `evaluation_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `session_id` | INTEGER | No | Session in which the evaluation happened | `1` | Foreign key to `sessions` |
| `student_id` | INTEGER | No | Student evaluated | `1` | Foreign key to `students` |
| `record_type` | VARCHAR(20) | No | Type of recitation | `new_memorization` | `new_memorization`, `review`, `tajweed` or `recitation` |
| `surah_number` | SMALLINT | No | Surah recited | `78` | Foreign key to `surahs` |
| `from_ayah` | SMALLINT | No | First ayah recited | `1` | Greater than 0 |
| `to_ayah` | SMALLINT | No | Last ayah recited | `10` | Must be greater than or equal to `from_ayah` |
| `score` | NUMERIC(3,1) | Yes | Teacher's score | `8.5` | 0 to 10 |
| `error_count` | SMALLINT | Yes | Number of errors noted | `2` | 0 or more |

---

## 4. Optional extension: tajweed error types

Not included in version 1. To analyze **which tajweed rules** cause the most errors, two tables would be added:

### `error_types`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `error_type_id` | SERIAL | No | Technical identifier | `1` | Primary key |
| `rule_name` | VARCHAR(50) | No | Name of the tajweed rule | `Ghunnah` | Unique |
| `category` | VARCHAR(30) | Yes | Group of rules | `Noon sakinah` | |

### `evaluation_errors`

| Column | Type | Null | Description | Example | Constraints |
|---|---|---|---|---|---|
| `evaluation_id` | INTEGER | No | Evaluation concerned | `1` | Part of primary key; foreign key to `evaluations` |
| `error_type_id` | INTEGER | No | Type of error | `1` | Part of primary key; foreign key to `error_types` |
| `error_count` | SMALLINT | No | Number of errors of this type | `2` | Greater than 0 |

This requires teachers to record the error type, which is extra work in a real school. For this reason it stays optional and can be tested with simulated data first.

---

## 5. Data quality checks

Run these checks after every data load. Each should return **0 rows**.

```sql
-- 1. Ayah range beyond the surah length
SELECT e.evaluation_id
FROM quran.evaluations e
JOIN quran.surahs s USING (surah_number)
WHERE e.to_ayah > s.ayah_count;

-- 2. Attendance recorded outside the student's enrollment period
SELECT a.session_id, a.student_id
FROM quran.attendance a
JOIN quran.sessions s USING (session_id)
LEFT JOIN quran.enrollments en
  ON en.student_id = a.student_id
 AND en.group_id = s.group_id
 AND s.session_date >= en.start_date
 AND (en.end_date IS NULL OR s.session_date <= en.end_date)
WHERE en.enrollment_id IS NULL;

-- 3. Evaluation for a student marked absent in that session
SELECT e.evaluation_id
FROM quran.evaluations e
JOIN quran.attendance a USING (session_id, student_id)
WHERE a.status = 'absent';

-- 4. Active students with an exit date, or dropped students without one
SELECT student_id
FROM quran.students
WHERE (status = 'active' AND exit_date IS NOT NULL)
   OR (status = 'dropped' AND exit_date IS NULL);
```

## 6. Privacy rules

- Students and teachers appear only as anonymous codes.
- Age is stored as a band, never as a birth date.
- `exit_reason` uses short categories (for example `moved`, `schedule`, `lost_interest`, `other`), never free text.
- If real data is used, the table linking codes to real identities is kept **outside the database and outside the repository**.
- The public repository contains only simulated data.

## 7. Change log

| Date | Change | Reason |
|---|---|---|
| 2026-11-10 | Initial version | First version of the data model |
