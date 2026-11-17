# Project Scope: Quran Students Analytics

**Author:** Sara Ourchane
**Version:** 1.0
**Status:** Draft
**Last updated:** 2026-11-10

---

## 1. Context

Quran schools, mosque programs and community associations track their students' progress (memorization, revision, attendance) mostly on paper or in scattered spreadsheets. As a result, teachers and school managers struggle to answer simple but important questions:

- Are students really progressing, and at what pace?
- Who is falling behind, and who is at risk of dropping out?
- Which factors (attendance, revision, group, schedule) actually influence progress?

This project builds an end-to-end analytics solution (database, SQL analysis, Python analysis and dashboard) that turns attendance and evaluation records into clear, actionable insights for teachers and school managers.

## 2. Target users

| User | What they need |
|---|---|
| **School manager** | A global view of progress, attendance and dropout risk across all groups |
| **Teacher** | A view of their own group: who is progressing, who needs support |
| **Project owner (portfolio)** | A complete, well-documented analytics project demonstrating SQL, Python and BI skills |

## 3. Objectives

1. **Track progress:** measure how quickly students memorize new material and how well they retain it.
2. **Understand engagement:** quantify the relationship between attendance, revision and progress.
3. **Detect risk early:** identify the signals that precede a student dropping out, so that teachers can intervene.

## 4. Business questions

| # | Question | Main tables |
|---|---|---|
| Q1 | How many new ayahs does a student memorize per week on average, and how does this vary by age band and starting level? | `evaluations`, `students` |
| Q2 | What is the relationship between attendance rate and progress? | `attendance`, `evaluations` |
| Q3 | Which behaviors precede a dropout (consecutive absences, falling scores, reduced revision)? | `attendance`, `evaluations`, `students` |
| Q4 | Does time spent on revision improve retention over time? | `evaluations` |
| Q5 | Which groups or teachers show the strongest progress, and which factors explain it (group size, schedule)? | `groups`, `teachers`, `enrollments`, `evaluations` |
| Q6 | Which surahs generate the most errors? | `evaluations`, `surahs` |

## 5. Scope

### In scope

- Relational database design (PostgreSQL) with clear constraints
- Simulated, realistic dataset (and real anonymized data if access is obtained)
- SQL analysis: window functions, cohorts, progression metrics
- Python analysis (Pandas) and a simple dropout risk model
- Power BI dashboard for managers and teachers
- Documentation in English: scope, metrics glossary, data dictionary, README

### Out of scope (version 1)

- Web or mobile application
- User accounts and authentication
- Payments, fees or parent communication
- Real-time data entry
- Any judgment on students' religious practice or character: the project measures learning activity only

## 6. Data and privacy

Student data is sensitive, especially when students are minors. The following rules apply to the whole project:

- **No real names, phone numbers, addresses or exact birth dates** in the database or the repository.
- Students and teachers are identified by **anonymous codes** (for example `S0001`, `T001`).
- Age is stored as an **age band** (for example `10-13`), not as a birth date.
- If real data is used: written **consent from the school** (and from parents for minors) is obtained first, and any mapping between codes and real identities stays **outside the database and the repository**.
- The public repository contains **only simulated data**.
- Raw data files are listed in `.gitignore`.

## 7. Assumptions

1. A session belongs to one group on one date.
2. A student can change groups over time (history kept in `enrollments`).
3. Evaluation scores are on a scale from 0 to 10.
4. A student is considered a **dropout** when absent for 28 consecutive days or when their status is `dropped`.
5. Simulated data follows realistic patterns (seasonal absences, gradual progress, some dropouts) but is not a representation of any real school.
6. The reference table of surahs (114 surahs, 6,236 ayahs) comes from an open source.

## 8. Technology stack

| Layer | Tool |
|---|---|
| Database | PostgreSQL |
| SQL client | DBeaver |
| Data generation and analysis | Python (Pandas, Faker, scikit-learn) |
| Visualization | Power BI Desktop |
| Version control | Git and GitHub |

## 9. Deliverables

| Deliverable | Location |
|---|---|
| Project scope (this document) | `docs/01_project_scope.md` |
| Metrics glossary | `docs/02_metrics_glossary.md` |
| Data dictionary | `docs/03_data_dictionary.md` |
| Data model diagram | `docs/` |
| Database schema | `sql/01_create_schema.sql` |
| Data generation script | `python/` |
| SQL analysis scripts | `sql/` |
| Python notebooks | `python/` |
| Power BI dashboard and screenshots | `dashboard/` |
| README with findings and recommendations | repository root |

## 10. Success criteria

- The database loads without errors and rejects invalid data through constraints.
- Each business question (Q1 to Q6) has a documented query or analysis and a written insight.
- The dashboard lets a manager understand the school's situation in under a minute.
- The dropout model is evaluated honestly (metrics reported, limitations explained).
- Another person can recreate the whole project from the repository by following the README.

## 11. Planned timeline (about 5 hours per day)

| Phase | Content | Estimated duration |
|---|---|---|
| 1 | Scope, metrics and data model | 1 to 2 days |
| 2 | Simulated dataset generation | 1 to 2 days |
| 3 | SQL analysis | 3 to 4 days |
| 4 | Python analysis and risk model | 4 to 5 days |
| 5 | Power BI dashboard | 3 to 4 days |
| 6 | Documentation and README | 2 to 3 days |
| 7 | Generalization into a reusable template (optional) | 5 to 7 days |

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| No access to real data | Use a well-designed simulated dataset and state it clearly in the README |
| Simulated data is too "clean" and gives unrealistic results | Add noise, missing values, seasonal effects and irregular attendance |
| Over-engineering the template | Keep version 1 simple (CSV import, no web application) |
| Privacy concerns with real data | Follow the rules in section 6; never publish identifiable data |
| Scope creep | Add nothing that does not serve questions Q1 to Q6 |
