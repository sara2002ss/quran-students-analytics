# Metrics Glossary

**Project:** Quran Students Analytics
**Version:** 1.0
**Purpose:** Define exactly how each indicator is calculated, so that every analysis, query and dashboard uses the same rules.

> Rule: if a metric changes, it is changed **here first**, then in the SQL, Python and dashboard.

---

## 1. Basic concepts

| Term | Definition |
|---|---|
| **Ayah** | One verse of the Quran. The Quran has 6,236 ayahs in 114 surahs. |
| **New memorization** | An evaluation of type `new_memorization`: the student recites ayahs for the first time from memory. |
| **Review (muraja'a)** | An evaluation of type `review`: the student recites previously memorized ayahs. |
| **Scheduled session** | A session of a group in which the student was enrolled on that date. |
| **Active student** | A student with `status = 'active'`. |
| **Observation period** | The date range chosen for an analysis (for example, the last 8 weeks). Every metric must state its period. |

## 2. Metric summary

| ID | Metric | Used for question |
|---|---|---|
| M1 | Ayahs memorized | Q1 |
| M2 | Weekly memorization rate | Q1, Q5 |
| M3 | Attendance rate | Q2, Q3 |
| M4 | Average review score | Q4 |
| M5 | Retention score | Q4 |
| M6 | Revision volume | Q4 |
| M7 | Errors per ayah | Q6 |
| M8 | Active weeks (consistency) | Q3 |
| M9 | Days since last attendance | Q3 |
| M10 | Dropout | Q3 |
| M11 | At-risk flag | Q3 |

---

## 3. Metric definitions

### M1. Ayahs memorized

- **Definition:** number of new ayahs a student recited from memory in the observation period.
- **Formula:** sum of `(to_ayah - from_ayah + 1)` for evaluations where `record_type = 'new_memorization'`.
- **Unit:** ayahs.
- **Notes:** an evaluation covers one surah only, so the formula is always valid. Repeating the same ayahs as new memorization should not be counted twice (see data quality checks).

```sql
SELECT student_id,
       SUM(to_ayah - from_ayah + 1) AS ayahs_memorized
FROM quran.evaluations
WHERE record_type = 'new_memorization'
GROUP BY student_id;
```

### M2. Weekly memorization rate

- **Definition:** average number of new ayahs memorized per week.
- **Formula:** `M1 / number of weeks in the period`, where weeks are counted from the student's enrollment date (or the start of the period, whichever is later).
- **Unit:** ayahs per week.
- **Notes:** divide by **weeks enrolled**, not by weeks with sessions, otherwise absent students look better than they are.

### M3. Attendance rate

- **Definition:** share of scheduled sessions that the student attended.
- **Statuses used:** `present`, `absent` (unexcused) and `excused` (excused absence). There is no "late" status.
- **Formula:** `present / (present + absent)`.
- **Excused absences** (`excused`) are **excluded from the denominator**: they are not counted as attended or as missed.
- **Unit:** percentage (0 to 100).
- **Minimum data:** do not report the rate for a student with fewer than 4 scheduled sessions in the period.

```sql
SELECT student_id,
       ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'present')
             / NULLIF(COUNT(*) FILTER (WHERE status IN ('present','absent')), 0), 1) AS attendance_rate
FROM quran.attendance
GROUP BY student_id;
```

### M4. Average review score

- **Definition:** average score of the student's reviews in the observation period.
- **Formula:** `AVG(score)` where `record_type = 'review'`.
- **Unit:** score from 0 to 10.

### M5. Retention score

- **Definition:** how well a student still remembers material memorized some time ago.
- **Formula:** average score of reviews of ayahs that were first memorized **at least 30 days before** the review date.
- **Unit:** score from 0 to 10.
- **Notes:**
  - This is different from progress: progress measures *new* learning, retention measures *remembering*.
  - Comparison: retention score by revision volume group (M6), to answer Q4.
  - The 30-day window is a starting choice and can be changed.

### M6. Revision volume

- **Definition:** number of ayahs reviewed per week.
- **Formula:** sum of `(to_ayah - from_ayah + 1)` for `record_type = 'review'`, divided by weeks in the period.
- **Unit:** ayahs reviewed per week.
- **Suggested grouping for analysis:** low (bottom third), medium, high (top third), computed within the same age band.

### M7. Errors per ayah

- **Definition:** average number of errors per ayah evaluated.
- **Formula:** `SUM(error_count) / SUM(to_ayah - from_ayah + 1)`.
- **Unit:** errors per ayah.
- **Rules:**
  - Always use a **rate**, never raw totals (long surahs would always look worse).
  - Ignore surahs with fewer than **100 ayahs evaluated** in total.
  - Compare surahs **within the same student level** to avoid mixing difficulty with student ability.

### M8. Active weeks (consistency)

- **Definition:** number of weeks in which the student attended at least one session.
- **Formula:** count of distinct weeks with at least one `present` record, over the **last 8 weeks**.
- **Unit:** weeks (0 to 8).

### M9. Days since last attendance

- **Definition:** number of days between the reference date and the student's last attendance (`present`).
- **Formula:** `reference_date - MAX(session_date)` for attended sessions.
- **Unit:** days.
- **Notes:** the reference date is the last date in the dataset, not today's date, so the result does not change when the project is reopened later.

### M10. Dropout

- **Definition:** a student who has left the program.
- **Rule:** a student is a dropout if `status = 'dropped'`, **or** if M9 is **28 days or more** while the student is still enrolled.
- **Notes:**
  - Students with status `graduated` or `paused` are **not** dropouts.
  - Dropout rate = dropouts / students enrolled in the cohort.

### M11. At-risk flag

- **Definition:** a warning indicator for active students who show early signs of leaving.
- **Initial rule:** a student is at risk if **at least two** of these conditions are true:
  1. Attendance rate (M3) over the last 4 weeks is below 60%.
  2. Three or more consecutive absences (excused absences excluded).
  3. Average score over the last 4 weeks dropped by 2 points or more compared with the previous 4 weeks.
  4. Revision volume (M6) over the last 4 weeks is below half of the student's own previous average.
- **Notes:** these thresholds are **initial assumptions**. They will be tested and adjusted using the simulated data and the dropout model, and each change will be documented here.

---

## 4. Data quality rules affecting metrics

| Rule | Why it matters |
|---|---|
| `to_ayah` must be less than or equal to the number of ayahs of the surah | Avoids impossible ranges that inflate M1 and M7 |
| Exclude sessions with no attendance records | Avoids a wrong denominator for M3 |
| Count a student's attendance only while enrolled in the group | Uses `enrollments.start_date` and `end_date` |
| Score must be between 0 and 10 | Enforced by a database constraint |
| Do not report metrics on very small samples | Avoids misleading conclusions (minimums stated above) |

## 5. Change log

| Date | Change | Reason |
|---|---|---|
| 2026-11-10 | Initial version | First definition of project metrics |
