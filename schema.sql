-- CodeJudge Platform — Relational Schema
-- Part 1: Task 5 — SQL DDL
PRAGMA foreign_keys = ON;


-- 1. BATCHES
CREATE TABLE batches (
    batch_id     TEXT PRIMARY KEY,
    batch_code   TEXT NOT NULL UNIQUE,
    program      TEXT NOT NULL,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    batch_status TEXT NOT NULL DEFAULT 'active',
    CONSTRAINT chk_batch_status CHECK (batch_status IN ('active', 'completed')),
    CONSTRAINT chk_batch_dates  CHECK (end_date > start_date)
);

-- =============================================================
-- 2. COURSES
-- =============================================================
CREATE TABLE courses (
    course_id     TEXT PRIMARY KEY,
    course_code   TEXT NOT NULL UNIQUE,
    course_title  TEXT NOT NULL,
    course_status TEXT NOT NULL DEFAULT 'active',
    credit_hours  INTEGER NOT NULL,
    CONSTRAINT chk_course_status  CHECK (course_status IN ('active', 'inactive')),
    CONSTRAINT chk_credit_hours   CHECK (credit_hours > 0)
);

-- =============================================================
-- 3. STUDENTS
-- =============================================================
CREATE TABLE students (
    student_id        TEXT PRIMARY KEY,
    roll_number       TEXT NOT NULL UNIQUE,
    full_name         TEXT NOT NULL,
    email             TEXT UNIQUE,          -- nullable: 1 missing in raw data; UNIQUE enforced where present
    batch_id          TEXT NOT NULL,
    admission_date    DATE NOT NULL,
    enrollment_status TEXT NOT NULL DEFAULT 'active',
    graduation_year   INTEGER,
    CONSTRAINT fk_students_batch  FOREIGN KEY (batch_id) REFERENCES batches(batch_id),
    CONSTRAINT chk_student_status CHECK (enrollment_status IN ('active', 'inactive', 'graduated', 'suspended')),
    CONSTRAINT chk_grad_year      CHECK (graduation_year IS NULL OR graduation_year > 2000)
);

-- =============================================================
-- 4. ENROLLMENTS
-- =============================================================
CREATE TABLE enrollments (
    enrollment_id     TEXT PRIMARY KEY,
    student_id        TEXT NOT NULL,
    course_id         TEXT NOT NULL,
    enrolled_on       DATE NOT NULL,
    enrollment_status TEXT NOT NULL DEFAULT 'active',
    final_grade       TEXT,                 -- nullable until course is completed
    CONSTRAINT fk_enroll_student  FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_enroll_course   FOREIGN KEY (course_id)  REFERENCES courses(course_id),
    CONSTRAINT uq_enrollment      UNIQUE (student_id, course_id),
    CONSTRAINT chk_enroll_status  CHECK (enrollment_status IN ('active', 'dropped', 'completed'))
);

-- =============================================================
-- 5. PROBLEMS
-- =============================================================
CREATE TABLE problems (
    problem_id   TEXT PRIMARY KEY,
    course_id    TEXT NOT NULL,
    problem_code TEXT NOT NULL UNIQUE,
    title        TEXT NOT NULL,
    difficulty   TEXT NOT NULL,
    max_score    INTEGER NOT NULL,
    created_at   DATETIME NOT NULL,
    is_active    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT fk_problem_course   FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT chk_difficulty      CHECK (difficulty IN ('Easy', 'Medium', 'Hard', 'Very Hard')),
    CONSTRAINT chk_max_score       CHECK (max_score > 0),
    CONSTRAINT chk_is_active       CHECK (is_active IN (0, 1))
);

-- =============================================================
-- 6. TEST CASES
-- =============================================================
CREATE TABLE test_cases (
    test_case_id          TEXT PRIMARY KEY,
    problem_id            TEXT NOT NULL,
    case_no               INTEGER NOT NULL,
    input_label           TEXT,
    expected_output_label TEXT,
    points                INTEGER NOT NULL DEFAULT 0,
    is_hidden             INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT fk_tc_problem  FOREIGN KEY (problem_id) REFERENCES problems(problem_id),
    CONSTRAINT uq_tc          UNIQUE (problem_id, case_no),
    CONSTRAINT chk_tc_points  CHECK (points >= 0),
    CONSTRAINT chk_tc_hidden  CHECK (is_hidden IN (0, 1))
);

-- =============================================================
-- 7. CONTESTS
-- =============================================================
CREATE TABLE contests (
    contest_id     TEXT PRIMARY KEY,
    course_id      TEXT NOT NULL,
    contest_title  TEXT NOT NULL,
    start_time     DATETIME NOT NULL,
    end_time       DATETIME NOT NULL,
    contest_status TEXT NOT NULL DEFAULT 'draft',
    CONSTRAINT fk_contest_course   FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT chk_contest_times   CHECK (end_time > start_time),
    CONSTRAINT chk_contest_status  CHECK (contest_status IN ('draft', 'published', 'completed', 'cancelled'))
);

-- =============================================================
-- 8. CONTEST_PROBLEMS  (junction table)
-- =============================================================
CREATE TABLE contest_problems (
    contest_id     TEXT NOT NULL,
    problem_id     TEXT NOT NULL,
    problem_order  INTEGER NOT NULL,
    PRIMARY KEY (contest_id, problem_id),
    CONSTRAINT fk_cp_contest  FOREIGN KEY (contest_id) REFERENCES contests(contest_id),
    CONSTRAINT fk_cp_problem  FOREIGN KEY (problem_id) REFERENCES problems(problem_id)
);

-- =============================================================
-- 9. SUBMISSIONS
-- =============================================================
CREATE TABLE submissions (
    submission_id TEXT PRIMARY KEY,
    student_id    TEXT NOT NULL,
    problem_id    TEXT NOT NULL,
    contest_id    TEXT,                     -- nullable: NULL = practice submission
    language      TEXT NOT NULL,
    submitted_at  DATETIME NOT NULL,
    status        TEXT NOT NULL,
    score         INTEGER DEFAULT 0,
    runtime_ms    INTEGER,
    CONSTRAINT fk_sub_student   FOREIGN KEY (student_id)  REFERENCES students(student_id),
    CONSTRAINT fk_sub_problem   FOREIGN KEY (problem_id)  REFERENCES problems(problem_id),
    CONSTRAINT fk_sub_contest   FOREIGN KEY (contest_id)  REFERENCES contests(contest_id),
    CONSTRAINT chk_sub_language CHECK (language IN ('C', 'C++', 'Python', 'Java', 'JavaScript', 'Go', 'PseudoCode')),
    CONSTRAINT chk_sub_status   CHECK (status IN ('Accepted', 'Wrong Answer', 'Runtime Error',
                                                   'Compilation Error', 'Time Limit Exceeded', 'OK')),
    CONSTRAINT chk_sub_score    CHECK (score >= 0)
);

-- =============================================================
-- 10. TEST RESULTS
-- =============================================================
CREATE TABLE test_results (
    result_id      TEXT PRIMARY KEY,
    submission_id  TEXT NOT NULL,
    test_case_id   TEXT NOT NULL,
    result_status  TEXT NOT NULL,
    runtime_ms     INTEGER,
    memory_kb      INTEGER,
    awarded_points INTEGER DEFAULT 0,
    CONSTRAINT fk_tr_submission  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id),
    CONSTRAINT fk_tr_test_case   FOREIGN KEY (test_case_id)  REFERENCES test_cases(test_case_id),
    CONSTRAINT uq_test_result    UNIQUE (submission_id, test_case_id),
    CONSTRAINT chk_tr_status     CHECK (result_status IN ('Passed', 'Failed', 'Runtime Error', 'Time Limit Exceeded')),
    CONSTRAINT chk_tr_points     CHECK (awarded_points >= 0)
);

-- =============================================================
-- 11. SESSIONS
-- =============================================================
CREATE TABLE sessions (
    session_id    TEXT PRIMARY KEY,
    course_id     TEXT NOT NULL,
    session_title TEXT NOT NULL,
    session_date  DATE NOT NULL,
    session_type  TEXT NOT NULL,
    CONSTRAINT fk_session_course  FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT chk_session_type   CHECK (session_type IN ('lecture', 'lab', 'tutorial'))
);

-- =============================================================
-- 12. ATTENDANCE
-- =============================================================
CREATE TABLE attendance (
    attendance_id     TEXT PRIMARY KEY,
    session_id        TEXT NOT NULL,
    student_id        TEXT NOT NULL,
    attendance_status TEXT NOT NULL,
    marked_at         DATETIME NOT NULL,
    CONSTRAINT fk_att_session  FOREIGN KEY (session_id) REFERENCES sessions(session_id),
    CONSTRAINT fk_att_student  FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT uq_attendance   UNIQUE (session_id, student_id),
    CONSTRAINT chk_att_status  CHECK (attendance_status IN ('present', 'absent', 'late', 'excused'))
);

-- =============================================================
-- 13. REGRADE REQUESTS
-- =============================================================
CREATE TABLE regrade_requests (
    request_id     TEXT PRIMARY KEY,
    submission_id  TEXT NOT NULL,
    student_id     TEXT NOT NULL,
    requested_at   DATETIME NOT NULL,
    reason         TEXT,
    request_status TEXT NOT NULL DEFAULT 'open',
    resolved_at    DATETIME,               -- nullable until resolved
    CONSTRAINT fk_rg_submission  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id),
    CONSTRAINT fk_rg_student     FOREIGN KEY (student_id)    REFERENCES students(student_id),
    CONSTRAINT chk_rg_status     CHECK (request_status IN ('open', 'approved', 'closed', 'rejected', 'done'))
);

-- =============================================================
-- 14. PLAGIARISM FLAGS
-- =============================================================
CREATE TABLE plagiarism_flags (
    flag_id               TEXT PRIMARY KEY,
    submission_id         TEXT NOT NULL,
    matched_submission_id TEXT NOT NULL,
    similarity_score      REAL NOT NULL,
    flag_status           TEXT NOT NULL DEFAULT 'new',
    created_at            DATETIME NOT NULL,
    CONSTRAINT fk_pf_submission  FOREIGN KEY (submission_id)         REFERENCES submissions(submission_id),
    CONSTRAINT fk_pf_matched     FOREIGN KEY (matched_submission_id) REFERENCES submissions(submission_id),
    CONSTRAINT chk_pf_score      CHECK (similarity_score BETWEEN 0 AND 100),
    CONSTRAINT chk_pf_status     CHECK (flag_status IN ('new', 'pending', 'reviewing', 'confirmed', 'cleared'))
);

-- =============================================================
-- 15. RAW STUDENT IMPORT  (staging table — minimal constraints)
-- =============================================================
CREATE TABLE raw_student_import (
    raw_row_id     TEXT PRIMARY KEY,
    roll_number    TEXT,
    full_name      TEXT,
    email          TEXT,
    batch_code     TEXT,                    -- plain string, not FK — batch may not exist yet
    admission_date DATE,
    import_status  TEXT NOT NULL DEFAULT 'new',
    import_notes   TEXT,
    CONSTRAINT chk_import_status CHECK (import_status IN ('new', 'accepted', 'rejected'))
);

-- =============================================================
-- 16. OPERATION REQUESTS
-- =============================================================
CREATE TABLE operation_requests (
    operation_id      TEXT PRIMARY KEY,
    requested_by      TEXT NOT NULL,
    operation_type    TEXT NOT NULL,
    target_table      TEXT NOT NULL,
    target_record_id  TEXT NOT NULL,
    requested_at      DATETIME NOT NULL,
    reason            TEXT,
    approval_status   TEXT NOT NULL DEFAULT 'pending',
    executed_at       DATETIME,            -- nullable until executed
    CONSTRAINT chk_op_type    CHECK (operation_type IN ('UPDATE', 'DELETE', 'MERGE', 'INSERT')),
    CONSTRAINT chk_op_status  CHECK (approval_status IN ('pending', 'approved', 'rejected'))
);
