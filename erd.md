# Entity-Relationship Diagram — CodeJudge Platform

## Text ERD (Markdown Format)

```
BATCHES
  PK: batch_id
  batch_code (UNIQUE), program, start_date, end_date, batch_status
      |
      | 1
      |
      * (many)
STUDENTS
  PK: student_id
  AK: roll_number (UNIQUE)
  AK: email (UNIQUE)
  batch_id (FK → batches)
  full_name, admission_date, enrollment_status, graduation_year
      |                        |                       |
      | 1                      | 1                     | 1
      |                        |                       |
      * (many)                 * (many)                * (many)
ENROLLMENTS              SUBMISSIONS              ATTENDANCE
  PK: enrollment_id        PK: submission_id        PK: attendance_id
  FK: student_id           FK: student_id           FK: student_id
  FK: course_id            FK: problem_id           FK: session_id
  UQ: (student_id,         FK: contest_id (NULL     UQ: (session_id,
       course_id)               = practice)              student_id)
  enrolled_on,             language, submitted_at,  attendance_status,
  enrollment_status,       status, score,           marked_at
  final_grade              runtime_ms
      |                        |
      |                        | 1
      | *                      |
      |                        * (many)
COURSES                  TEST_RESULTS
  PK: course_id             PK: result_id
  AK: course_code (UNIQUE)  FK: submission_id
  course_title,             FK: test_case_id
  course_status,            UQ: (submission_id,
  credit_hours                   test_case_id)
      |                     result_status, runtime_ms,
      | 1                   memory_kb, awarded_points
      |
      |-------------------------------|-----------------|
      * (many)               * (many)          * (many)
PROBLEMS               CONTESTS           SESSIONS
  PK: problem_id         PK: contest_id     PK: session_id
  FK: course_id          FK: course_id      FK: course_id
  AK: problem_code (UQ)  contest_title,     session_title,
  title, difficulty,     start_time,        session_date,
  max_score, created_at, end_time,          session_type
  is_active              contest_status
      |                      |
      | 1                     | 1
      |                       |
      *---CONTEST_PROBLEMS----*
            (junction table)
            PK: (contest_id, problem_id)
            problem_order
      |
      | 1
      |
      * (many)
TEST_CASES
  PK: test_case_id
  FK: problem_id
  UQ: (problem_id, case_no)
  case_no, input_label,
  expected_output_label,
  points, is_hidden


SUBMISSIONS ←──────────────────────────────────────┐
  (also referenced by:)                             |
      |                        |                    |
      | 1                      | 1                  |
      |                        |                    |
      * (many)                 * (many)             |
REGRADE_REQUESTS         PLAGIARISM_FLAGS           |
  PK: request_id           PK: flag_id              |
  FK: submission_id        FK: submission_id ────────┘
  FK: student_id           FK: matched_submission_id (self-ref → submissions)
  requested_at, reason,    similarity_score,
  request_status,          flag_status, created_at
  resolved_at


RAW_STUDENT_IMPORT           OPERATION_REQUESTS
  PK: raw_row_id               PK: operation_id
  (staging — no FKs)           requested_by, operation_type,
  roll_number, full_name,      target_table, target_record_id,
  email, batch_code,           requested_at, reason,
  admission_date,              approval_status, executed_at
  import_status, import_notes
```

---

## Relationship Summary Table

| From Table | Relationship | To Table | Via |
|---|---|---|---|
| students | many → one | batches | `batch_id` |
| students | many ↔ many | courses | `enrollments` |
| students | many ↔ many | sessions | `attendance` |
| problems | many → one | courses | `course_id` |
| test_cases | many → one | problems | `problem_id` |
| contests | many → one | courses | `course_id` |
| contests | many ↔ many | problems | `contest_problems` |
| submissions | many → one | students | `student_id` |
| submissions | many → one | problems | `problem_id` |
| submissions | many → one (nullable) | contests | `contest_id` |
| test_results | many → one | submissions | `submission_id` |
| test_results | many → one | test_cases | `test_case_id` |
| regrade_requests | many → one | submissions | `submission_id` |
| plagiarism_flags | many → one | submissions | `submission_id` (×2) |
| sessions | many → one | courses | `course_id` |

---

## Key:
- `PK` = Primary Key
- `FK` = Foreign Key
- `AK` = Alternate Key (Candidate Key not chosen as PK)
- `UQ` = UNIQUE constraint
- `1` = one side of relationship
- `*` = many side of relationship
