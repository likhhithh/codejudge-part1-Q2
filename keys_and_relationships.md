# Keys and Relationships — CodeJudge Schema

## Overview

This document identifies and justifies all keys and constraints for each table in the CodeJudge relational design, using actual column names from the dataset.

---

## 1. `batches`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `batch_id` | Unique surrogate identifier; referenced by `students.batch_id` |
| Candidate Key | `batch_code` | Human-readable, unique per batch (e.g. `CSE2025A`) |
| Alternate Key | `batch_code` | Candidate key not chosen as PK; would work but is mutable |
| NOT NULL | `batch_id`, `batch_code`, `program`, `start_date`, `batch_status` | All core attributes must be present |
| CHECK | `batch_status IN ('active', 'completed')` | Prevents invalid status values |
| CHECK | `end_date > start_date` | Logical date ordering |

---

## 2. `courses`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `course_id` | Stable surrogate; referenced widely |
| Candidate Key | `course_code` | Each course has a unique readable code like `CS101` |
| Alternate Key | `course_code` | Could serve as PK but is mutable; kept as UNIQUE constraint |
| NOT NULL | `course_id`, `course_code`, `course_title`, `course_status` | Core attributes always required |
| CHECK | `credit_hours > 0` | Credits must be positive |
| CHECK | `course_status IN ('active', 'inactive')` | Restrict to valid values |

---

## 3. `students`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `student_id` | Surrogate identifier; referenced by enrollments, submissions, attendance, etc. |
| Candidate Key | `roll_number` | Institution-assigned roll number should be globally unique |
| Candidate Key | `email` | Email should be unique across all students |
| Alternate Keys | `roll_number`, `email` | Both are valid candidate keys; neither chosen as PK to avoid mutable PK issues |
| Foreign Key | `batch_id → batches(batch_id)` | Every student belongs to exactly one batch |
| NOT NULL | `student_id`, `roll_number`, `full_name`, `batch_id`, `admission_date`, `enrollment_status` | Core fields required |
| UNIQUE | `roll_number` | Enforces candidate key |
| UNIQUE | `email` | Enforces candidate key (note: 1 NULL, 1 malformed in raw data — data cleaning required) |
| CHECK | `enrollment_status IN ('active', 'inactive', 'graduated', 'suspended')` | Valid status values |

---

## 4. `enrollments`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `enrollment_id` | Surrogate row identifier |
| Composite Candidate Key | `(student_id, course_id)` | A student should be enrolled in a course at most once |
| Foreign Key | `student_id → students(student_id)` | Must refer to a real student |
| Foreign Key | `course_id → courses(course_id)` | Must refer to a real course |
| UNIQUE | `(student_id, course_id)` | Enforces the composite candidate key |
| NOT NULL | `enrollment_id`, `student_id`, `course_id`, `enrolled_on`, `enrollment_status` | Required fields |
| CHECK | `enrollment_status IN ('active', 'dropped', 'completed')` | Valid values only |

**Note:** The raw data contains one duplicate `(S0001, C006)` pair — this violates the composite uniqueness requirement and must be resolved before importing into the clean schema.

---

## 5. `problems`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `problem_id` | Surrogate; referenced by test_cases, submissions, contest_problems |
| Candidate Key | `problem_code` | Unique readable identifier like `CS101_P01` |
| Alternate Key | `problem_code` | Enforced via UNIQUE constraint |
| Foreign Key | `course_id → courses(course_id)` | Each problem belongs to one course |
| NOT NULL | `problem_id`, `course_id`, `problem_code`, `title`, `difficulty`, `max_score`, `is_active` | All required |
| CHECK | `difficulty IN ('Easy', 'Medium', 'Hard', 'Very Hard')` | Controlled vocabulary |
| CHECK | `max_score > 0` | Score must be positive |
| CHECK | `is_active IN (0, 1)` | Boolean flag |

---

## 6. `test_cases`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `test_case_id` | Surrogate; referenced by test_results |
| Composite Candidate Key | `(problem_id, case_no)` | Test case numbers are unique per problem |
| Foreign Key | `problem_id → problems(problem_id)` | Every test case belongs to a problem |
| UNIQUE | `(problem_id, case_no)` | Enforces composite candidate key |
| NOT NULL | `test_case_id`, `problem_id`, `case_no`, `points`, `is_hidden` | Required |
| CHECK | `points >= 0` | Points must be non-negative |
| CHECK | `is_hidden IN (0, 1)` | Boolean flag |

---

## 7. `contests`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `contest_id` | Surrogate; referenced by submissions and contest_problems |
| Foreign Key | `course_id → courses(course_id)` | Contest belongs to one course |
| NOT NULL | `contest_id`, `course_id`, `contest_title`, `start_time`, `end_time`, `contest_status` | All required |
| CHECK | `end_time > start_time` | Contest must end after it starts |
| CHECK | `contest_status IN ('draft', 'published', 'completed', 'cancelled')` | Valid values |

---

## 8. `contest_problems`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key (Composite) | `(contest_id, problem_id)` | Natural PK — a problem appears in a contest exactly once |
| Foreign Key | `contest_id → contests(contest_id)` | Must refer to a real contest |
| Foreign Key | `problem_id → problems(problem_id)` | Must refer to a real problem |
| NOT NULL | `contest_id`, `problem_id`, `problem_order` | All required |

**Note:** This is a pure junction table. No surrogate PK is needed — the composite is sufficient and semantically meaningful.

---

## 9. `submissions`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `submission_id` | Surrogate; referenced by test_results, regrade_requests, plagiarism_flags |
| Foreign Key | `student_id → students(student_id)` | Submission belongs to a student |
| Foreign Key | `problem_id → problems(problem_id)` | Submission is for a problem |
| Foreign Key | `contest_id → contests(contest_id)` | Nullable FK — NULL means practice, non-NULL means contest submission |
| NOT NULL | `submission_id`, `student_id`, `problem_id`, `language`, `submitted_at`, `status` | Required |
| CHECK | `language IN ('C', 'C++', 'Python', 'Java', 'JavaScript', 'Go', 'PseudoCode')` | Valid languages |
| CHECK | `status IN ('Accepted', 'Wrong Answer', 'Runtime Error', 'Compilation Error', 'Time Limit Exceeded', 'OK')` | Valid statuses |
| CHECK | `score >= 0` | Score must be non-negative |

---

## 10. `test_results`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `result_id` | Surrogate identifier |
| Composite Candidate Key | `(submission_id, test_case_id)` | A submission is run against each test case at most once |
| Foreign Key | `submission_id → submissions(submission_id)` | Result belongs to a submission |
| Foreign Key | `test_case_id → test_cases(test_case_id)` | Result is for a specific test case |
| UNIQUE | `(submission_id, test_case_id)` | Enforces composite candidate key |
| NOT NULL | `result_id`, `submission_id`, `test_case_id`, `result_status` | Required |
| CHECK | `result_status IN ('Passed', 'Failed', 'Runtime Error', 'Time Limit Exceeded')` | Valid values |
| CHECK | `awarded_points >= 0` | Non-negative |

---

## 11. `sessions`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `session_id` | Surrogate; referenced by attendance |
| Foreign Key | `course_id → courses(course_id)` | Session belongs to a course |
| NOT NULL | `session_id`, `course_id`, `session_title`, `session_date`, `session_type` | All required |
| CHECK | `session_type IN ('lecture', 'lab', 'tutorial')` | Controlled vocabulary |

---

## 12. `attendance`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `attendance_id` | Surrogate identifier |
| Composite Candidate Key | `(session_id, student_id)` | A student has one attendance record per session |
| Foreign Key | `session_id → sessions(session_id)` | Must refer to a real session |
| Foreign Key | `student_id → students(student_id)` | Must refer to a real student |
| UNIQUE | `(session_id, student_id)` | Enforces composite candidate key |
| NOT NULL | `attendance_id`, `session_id`, `student_id`, `attendance_status`, `marked_at` | All required |
| CHECK | `attendance_status IN ('present', 'absent', 'late', 'excused')` | Valid values |

---

## 13. `regrade_requests`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `request_id` | Surrogate identifier |
| Foreign Key | `submission_id → submissions(submission_id)` | Each request targets one submission |
| Foreign Key | `student_id → students(student_id)` | Denormalised reference — can also be derived via submission |
| NOT NULL | `request_id`, `submission_id`, `student_id`, `requested_at`, `request_status` | Required |
| CHECK | `request_status IN ('open', 'approved', 'closed', 'rejected', 'done')` | Valid statuses |

**Note on denormalisation:** `student_id` is redundant here since it can be derived via `submissions`. It is kept because it allows direct filtering by student without a join, which is a reasonable performance trade-off — but it must always match the student on the submission.

---

## 14. `plagiarism_flags`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `flag_id` | Surrogate identifier |
| Foreign Key | `submission_id → submissions(submission_id)` | The submission being flagged |
| Foreign Key | `matched_submission_id → submissions(submission_id)` | The matching submission |
| NOT NULL | `flag_id`, `submission_id`, `matched_submission_id`, `similarity_score`, `flag_status`, `created_at` | All required |
| CHECK | `similarity_score BETWEEN 0 AND 100` | Percentage must be 0–100 (raw data has values >100 — data quality issue) |
| CHECK | `flag_status IN ('new', 'pending', 'reviewing', 'confirmed', 'cleared')` | Valid statuses |

---

## 15. `raw_student_import`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `raw_row_id` | Staging row identifier |
| NOT NULL | `raw_row_id` | Row must be identifiable |
| CHECK | `import_status IN ('new', 'accepted', 'rejected')` | Valid processing states |

**No foreign keys** — this is a staging table. `batch_code` is stored as a plain string and not a FK, because the referenced batch may not yet exist in the clean schema.

---

## 16. `operation_requests`

| Key Type | Column(s) | Justification |
|----------|-----------|---------------|
| Primary Key | `operation_id` | Surrogate identifier |
| NOT NULL | `operation_id`, `requested_by`, `operation_type`, `target_table`, `target_record_id`, `requested_at`, `approval_status` | All core fields required |
| CHECK | `operation_type IN ('UPDATE', 'DELETE', 'MERGE', 'INSERT')` | Valid operations |
| CHECK | `approval_status IN ('pending', 'approved', 'rejected')` | Valid statuses |

---

## Relationship Summary

| Relationship | Type | Tables Involved |
|---|---|---|
| Student belongs to Batch | Many-to-one | students → batches |
| Student enrolled in Course | Many-to-many | students ↔ courses via enrollments |
| Problem belongs to Course | Many-to-one | problems → courses |
| Test Case belongs to Problem | Many-to-one | test_cases → problems |
| Contest linked to Course | Many-to-one | contests → courses |
| Contest contains Problems | Many-to-many | contests ↔ problems via contest_problems |
| Submission by Student for Problem | Many-to-one (each FK) | submissions → students, problems |
| Submission in Contest | Many-to-one (nullable) | submissions → contests |
| Test Result for Submission | Many-to-one | test_results → submissions |
| Test Result for Test Case | Many-to-one | test_results → test_cases |
| Session belongs to Course | Many-to-one | sessions → courses |
| Attendance links Student to Session | Many-to-many | students ↔ sessions via attendance |
| Regrade Request for Submission | Many-to-one | regrade_requests → submissions |
| Plagiarism Flag links two Submissions | Self-referencing | plagiarism_flags → submissions (×2) |
