# Schema Explanation — CodeJudge Platform

## What is CodeJudge?

CodeJudge is an online coding-practice and evaluation platform run by a CS department. Students are organised into batches, enrolled in courses, and solve programming problems. Their code submissions are automatically evaluated against test cases. The platform also supports contests, attendance tracking, regrade requests, and plagiarism detection.

---

## Table-by-Table Explanation

### 1. `batches`

**What it represents:** An academic cohort or intake group. All students who join together in the same programme at the same time form a batch.

| Column | Meaning |
|--------|---------|
| `batch_id` | Surrogate identifier for the batch (e.g. `B001`) |
| `batch_code` | Human-readable code like `CSE2025A` — unique per batch |
| `program` | Degree programme (B.Tech CSE, AIML, BCA, MCA) |
| `start_date` | When the batch began |
| `end_date` | Expected end date |
| `batch_status` | `active` or `completed` |

**Used to connect:** `students.batch_id → batches.batch_id`

---

### 2. `courses`

**What it represents:** The course catalogue — individual subjects offered on the platform.

| Column | Meaning |
|--------|---------|
| `course_id` | Surrogate identifier (e.g. `C001`) |
| `course_code` | Readable unique code like `CS101` |
| `course_title` | Full name, e.g. "Programming Fundamentals" |
| `course_status` | `active` or `inactive` |
| `credit_hours` | Academic credit weight |

**Used to connect:** `problems`, `enrollments`, `sessions`, `contests` all reference `course_id`.

---

### 3. `students`

**What it represents:** The student master record. Every person who uses the platform has one row here.

| Column | Meaning |
|--------|---------|
| `student_id` | Surrogate identifier (e.g. `S0001`) |
| `roll_number` | Institution-assigned roll number — should be unique |
| `full_name` | Student's full name |
| `email` | Contact email — should be unique; some records are missing or malformed |
| `batch_id` | Which batch this student belongs to (FK → batches) |
| `admission_date` | Date of joining |
| `enrollment_status` | `active`, `inactive`, `graduated`, etc. |
| `graduation_year` | Expected or actual graduation year |

**Data quality note:** One student has a NULL email (`S0005`), and one has an email missing the `@` symbol (`S0018`). These are integrity issues to address.

---

### 4. `enrollments`

**What it represents:** The many-to-many relationship between students and courses. One student can be enrolled in many courses; one course can have many students.

| Column | Meaning |
|--------|---------|
| `enrollment_id` | Surrogate row identifier |
| `student_id` | FK → students |
| `course_id` | FK → courses |
| `enrolled_on` | Date of enrollment |
| `enrollment_status` | `active`, `dropped`, `completed` |
| `final_grade` | Grade awarded at the end (nullable) |

**Composite uniqueness:** `(student_id, course_id)` should be unique — a student should not appear twice in the same course. One duplicate exists in the raw data (`S0001` in course `C006`).

---

### 5. `problems`

**What it represents:** Individual programming problems associated with a course.

| Column | Meaning |
|--------|---------|
| `problem_id` | Surrogate identifier (e.g. `P0001`) |
| `course_id` | Which course this problem belongs to (FK → courses) |
| `problem_code` | Unique readable code like `CS101_P01` |
| `title` | Problem title |
| `difficulty` | `Easy`, `Medium`, `Hard`, `Very Hard` |
| `max_score` | Maximum achievable score (range: 50–120) |
| `created_at` | When the problem was added |
| `is_active` | Whether the problem is currently published (0/1) |

---

### 6. `test_cases`

**What it represents:** Individual test cases used to evaluate a submission for a problem.

| Column | Meaning |
|--------|---------|
| `test_case_id` | Surrogate identifier |
| `problem_id` | FK → problems |
| `case_no` | Sequential test case number within a problem |
| `input_label` | Label/reference for input data (e.g. `input_1`) |
| `expected_output_label` | Label/reference for expected output |
| `points` | Points awarded if this test case passes |
| `is_hidden` | Whether students can see this test case (0 = visible, 1 = hidden) |

**Composite uniqueness:** `(problem_id, case_no)` should be unique.

---

### 7. `contests`

**What it represents:** Timed coding contests linked to a specific course.

| Column | Meaning |
|--------|---------|
| `contest_id` | Surrogate identifier |
| `course_id` | FK → courses |
| `contest_title` | Name of the contest |
| `start_time` / `end_time` | Contest window |
| `contest_status` | `published`, `completed`, `draft` |

---

### 8. `contest_problems`

**What it represents:** A mapping table — which problems appear in which contest, and in what order. This is a pure junction/bridge table implementing a many-to-many relationship between contests and problems.

| Column | Meaning |
|--------|---------|
| `contest_id` | FK → contests |
| `problem_id` | FK → problems |
| `problem_order` | Display order of the problem within the contest |

**Composite key:** `(contest_id, problem_id)` is the natural primary key.

---

### 9. `submissions`

**What it represents:** Every code submission made by a student for a problem. A submission may be tied to a contest or be a standalone practice attempt.

| Column | Meaning |
|--------|---------|
| `submission_id` | Surrogate identifier |
| `student_id` | FK → students |
| `problem_id` | FK → problems |
| `contest_id` | FK → contests (nullable — NULL means practice submission) |
| `language` | Programming language: C, C++, Python, Java, JavaScript, Go, PseudoCode |
| `submitted_at` | Timestamp of submission |
| `status` | `Accepted`, `Wrong Answer`, `Runtime Error`, `Compilation Error`, `Time Limit Exceeded`, `OK` |
| `score` | Score awarded |
| `runtime_ms` | Execution time in milliseconds |

---

### 10. `test_results`

**What it represents:** The per-test-case result of running a submission through the judge. One submission produces one row here per test case evaluated.

| Column | Meaning |
|--------|---------|
| `result_id` | Surrogate identifier |
| `submission_id` | FK → submissions |
| `test_case_id` | FK → test_cases |
| `result_status` | `Passed`, `Failed`, `Runtime Error`, `Time Limit Exceeded` |
| `runtime_ms` | Per-test-case runtime |
| `memory_kb` | Memory used |
| `awarded_points` | Points given for this test case |

**Composite uniqueness:** `(submission_id, test_case_id)` should be unique.

---

### 11. `sessions`

**What it represents:** Scheduled course sessions — lectures, labs, or tutorials.

| Column | Meaning |
|--------|---------|
| `session_id` | Surrogate identifier |
| `course_id` | FK → courses |
| `session_title` | Descriptive title |
| `session_date` | Date of the session |
| `session_type` | `lecture`, `lab`, `tutorial` |

---

### 12. `attendance`

**What it represents:** Whether a student was present or absent at a session. One row per (student, session) pair.

| Column | Meaning |
|--------|---------|
| `attendance_id` | Surrogate identifier |
| `session_id` | FK → sessions |
| `student_id` | FK → students |
| `attendance_status` | `present` or `absent` |
| `marked_at` | When attendance was recorded |

**Composite uniqueness:** `(session_id, student_id)` should be unique.

---

### 13. `regrade_requests`

**What it represents:** A request raised by a student asking for their submission to be re-evaluated.

| Column | Meaning |
|--------|---------|
| `request_id` | Surrogate identifier |
| `submission_id` | FK → submissions |
| `student_id` | FK → students (denormalised — can be derived via submission) |
| `requested_at` | When the request was raised |
| `reason` | Textual reason given by student |
| `request_status` | `open`, `approved`, `closed`, `rejected`, `done` |
| `resolved_at` | Nullable — when it was resolved |

**Data issue:** One regrade request references a `submission_id` that doesn't exist in the submissions table — referential integrity violation.

---

### 14. `plagiarism_flags`

**What it represents:** A record indicating two submissions have been flagged as potentially similar.

| Column | Meaning |
|--------|---------|
| `flag_id` | Surrogate identifier |
| `submission_id` | The flagged submission (FK → submissions) |
| `matched_submission_id` | The submission it was matched against (FK → submissions) |
| `similarity_score` | Similarity percentage (range: 60–125; values >100 are a data quality issue) |
| `flag_status` | `new`, `pending`, `reviewing`, `confirmed`, `cleared` |
| `created_at` | When the flag was created |

---

### 15. `raw_student_import`

**What it represents:** A staging table for bulk import of new students. Records here are not yet validated or promoted to the `students` table. This represents data that is intentionally messy and not yet normalised.

| Column | Meaning |
|--------|---------|
| `raw_row_id` | Staging row identifier |
| `roll_number` | Proposed roll number |
| `full_name` | Student name |
| `email` | Email |
| `batch_code` | Batch code as a string (not a FK — raw staging) |
| `admission_date` | Admission date |
| `import_status` | `new`, `accepted`, `rejected` |
| `import_notes` | Notes on why a record was rejected or flagged |

---

### 16. `operation_requests`

**What it represents:** Administrative requests to change data — updates, deletes, or merges — that require approval before execution. Used for safe change management.

| Column | Meaning |
|--------|---------|
| `operation_id` | Surrogate identifier |
| `requested_by` | Email of the requester |
| `operation_type` | `UPDATE`, `DELETE`, `MERGE`, etc. |
| `target_table` | Which table the operation targets |
| `target_record_id` | ID of the record to change |
| `requested_at` | Request timestamp |
| `reason` | Justification |
| `approval_status` | `pending`, `approved`, `rejected` |
| `executed_at` | Nullable — when it was carried out |

---

## Entity Identification Summary

| Entity | Type | Why it is separate |
|--------|------|--------------------|
| Batches | Core | Groups students by cohort; independent of courses |
| Courses | Core | Independent academic subjects |
| Students | Core | Core user entity |
| Enrollments | Junction | Many-to-many between students and courses |
| Problems | Core | Content entity tied to a course |
| Test Cases | Dependent | Belongs to a problem; needs its own table due to many-to-one |
| Contests | Core | Timed evaluation events; linked to a course |
| Contest Problems | Junction | Many-to-many between contests and problems |
| Submissions | Event | Student action; ties student + problem + (optional) contest |
| Test Results | Dependent | Per-test-case result of a submission |
| Sessions | Core | Scheduled class events per course |
| Attendance | Junction | Many-to-many between students and sessions |
| Regrade Requests | Event | Student-raised dispute per submission |
| Plagiarism Flags | Audit | Pairs of similar submissions |
| Raw Student Import | Staging | Pre-validation data; intentionally not normalised |
| Operation Requests | Audit | Administrative change approval log |
