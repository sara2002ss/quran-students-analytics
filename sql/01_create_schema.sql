-- =====================================================================
-- Project : Quran Students Analytics
-- File    : sql/01_create_schema.sql
-- Purpose : Create the schema, tables, constraints and indexes
-- Database: quran_analytics (PostgreSQL, UTF8)
-- Privacy : all identifiers are anonymous codes; no real personal data
-- =====================================================================

-- Uncomment the next line ONLY to reset everything (it deletes all data)
-- DROP SCHEMA IF EXISTS quran CASCADE;

CREATE SCHEMA IF NOT EXISTS quran;
SET search_path TO quran, public;

-- ---------------------------------------------------------------------
-- 1. Reference table: the 114 surahs (loaded once, see phase 2)
-- ---------------------------------------------------------------------
CREATE TABLE surahs (
    surah_number  SMALLINT    PRIMARY KEY CHECK (surah_number BETWEEN 1 AND 114),
    name_en       VARCHAR(50) NOT NULL,
    name_ar       VARCHAR(50),
    ayah_count    SMALLINT    NOT NULL CHECK (ayah_count > 0)
);

-- ---------------------------------------------------------------------
-- 2. Teachers (anonymous)
-- ---------------------------------------------------------------------
CREATE TABLE teachers (
    teacher_id    SERIAL      PRIMARY KEY,
    teacher_code  VARCHAR(10) NOT NULL UNIQUE,     -- e.g. T001
    join_date     DATE        NOT NULL
);

-- ---------------------------------------------------------------------
-- 3. Groups (classes led by a teacher)
-- ---------------------------------------------------------------------
CREATE TABLE groups (
    group_id      SERIAL      PRIMARY KEY,
    group_name    VARCHAR(50) NOT NULL,
    teacher_id    INTEGER     NOT NULL REFERENCES teachers(teacher_id),
    level         VARCHAR(20) CHECK (level IN ('beginner', 'intermediate', 'advanced')),
    weekday       SMALLINT    CHECK (weekday BETWEEN 1 AND 7),   -- 1 = Monday
    start_time    TIME
);

-- ---------------------------------------------------------------------
-- 4. Students (anonymous)
-- ---------------------------------------------------------------------
CREATE TABLE students (
    student_id       SERIAL      PRIMARY KEY,
    student_code     VARCHAR(10) NOT NULL UNIQUE,  -- e.g. S0001
    age_band         VARCHAR(10) CHECK (age_band IN ('6-9', '10-13', '14-17', '18+')),
    gender           CHAR(1)     CHECK (gender IN ('F', 'M')),
    enrollment_date  DATE        NOT NULL,
    starting_level   VARCHAR(20) CHECK (starting_level IN ('beginner', 'intermediate', 'advanced')),
    status           VARCHAR(15) NOT NULL DEFAULT 'active'
                     CHECK (status IN ('active', 'dropped', 'graduated', 'paused')),
    exit_date        DATE,
    exit_reason      VARCHAR(50),                  -- short categories only
    CHECK (exit_date IS NULL OR exit_date >= enrollment_date)
);

-- ---------------------------------------------------------------------
-- 5. Enrollments (history of student <-> group)
-- ---------------------------------------------------------------------
CREATE TABLE enrollments (
    enrollment_id SERIAL  PRIMARY KEY,
    student_id    INTEGER NOT NULL REFERENCES students(student_id),
    group_id      INTEGER NOT NULL REFERENCES groups(group_id),
    start_date    DATE    NOT NULL,
    end_date      DATE,
    CHECK (end_date IS NULL OR end_date >= start_date)
);

-- ---------------------------------------------------------------------
-- 6. Sessions (one group on one date)
-- ---------------------------------------------------------------------
CREATE TABLE sessions (
    session_id    SERIAL   PRIMARY KEY,
    group_id      INTEGER  NOT NULL REFERENCES groups(group_id),
    session_date  DATE     NOT NULL,
    duration_min  SMALLINT CHECK (duration_min > 0),
    UNIQUE (group_id, session_date)
);

-- ---------------------------------------------------------------------
-- 7. Attendance (one row per enrolled student per session, absences included)
--    present = attended | absent = unexcused absence | excused = excused absence
-- ---------------------------------------------------------------------
CREATE TABLE attendance (
    session_id    INTEGER     NOT NULL REFERENCES sessions(session_id),
    student_id    INTEGER     NOT NULL REFERENCES students(student_id),
    status        VARCHAR(10) NOT NULL CHECK (status IN ('present', 'absent', 'excused')),
    PRIMARY KEY (session_id, student_id)
);

-- ---------------------------------------------------------------------
-- 8. Evaluations (recitation records)
-- ---------------------------------------------------------------------
CREATE TABLE evaluations (
    evaluation_id SERIAL      PRIMARY KEY,
    session_id    INTEGER     NOT NULL REFERENCES sessions(session_id),
    student_id    INTEGER     NOT NULL REFERENCES students(student_id),
    record_type   VARCHAR(20) NOT NULL
                  CHECK (record_type IN ('new_memorization', 'review', 'tajweed', 'recitation')),
    surah_number  SMALLINT    NOT NULL REFERENCES surahs(surah_number),
    from_ayah     SMALLINT    NOT NULL CHECK (from_ayah > 0),
    to_ayah       SMALLINT    NOT NULL,
    score         NUMERIC(3,1) CHECK (score BETWEEN 0 AND 10),
    error_count   SMALLINT    CHECK (error_count >= 0),
    CHECK (to_ayah >= from_ayah)
);

-- ---------------------------------------------------------------------
-- 9. Rule that a simple CHECK cannot express:
--    to_ayah must not exceed the number of ayahs of the surah
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION quran.check_ayah_range()
RETURNS trigger AS $$
DECLARE
    max_ayah SMALLINT;
BEGIN
    SELECT ayah_count INTO max_ayah
    FROM quran.surahs
    WHERE surah_number = NEW.surah_number;

    IF NEW.to_ayah > max_ayah THEN
        RAISE EXCEPTION 'to_ayah (%) exceeds the ayah count (%) of surah %',
            NEW.to_ayah, max_ayah, NEW.surah_number;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_ayah_range
BEFORE INSERT OR UPDATE ON quran.evaluations
FOR EACH ROW EXECUTE FUNCTION quran.check_ayah_range();

-- ---------------------------------------------------------------------
-- 10. Indexes for the most common joins and filters
-- ---------------------------------------------------------------------
CREATE INDEX idx_enroll_student   ON enrollments (student_id);
CREATE INDEX idx_enroll_group     ON enrollments (group_id);
CREATE INDEX idx_sessions_group   ON sessions (group_id);
CREATE INDEX idx_sessions_date    ON sessions (session_date);
CREATE INDEX idx_att_student      ON attendance (student_id);
CREATE INDEX idx_eval_student     ON evaluations (student_id);
CREATE INDEX idx_eval_session     ON evaluations (session_id);
CREATE INDEX idx_eval_surah       ON evaluations (surah_number);
CREATE INDEX idx_eval_type        ON evaluations (record_type);

-- ---------------------------------------------------------------------
-- OPTIONAL EXTENSION (not in version 1): tajweed error types
-- Uncomment only if you want to analyze errors by tajweed rule.
-- ---------------------------------------------------------------------
-- CREATE TABLE error_types (
--     error_type_id SERIAL      PRIMARY KEY,
--     rule_name     VARCHAR(50) NOT NULL UNIQUE,
--     category      VARCHAR(30)
-- );
--
-- CREATE TABLE evaluation_errors (
--     evaluation_id INTEGER  NOT NULL REFERENCES evaluations(evaluation_id),
--     error_type_id INTEGER  NOT NULL REFERENCES error_types(error_type_id),
--     error_count   SMALLINT NOT NULL CHECK (error_count > 0),
--     PRIMARY KEY (evaluation_id, error_type_id)
-- );
