# Normalization Notes — CodeJudge Schema

## Repeated / Redundant Data in the Raw CSVs

### Example 1 — `program` and `batch_status` repeated across students
In the raw data, if student records were joined with their batch info inline, every student in `CSE2025A` would repeat `B.Tech CSE`, `2025-01-10`, `2025-06-09`, and `active`. With 320 students across 6 batches, this is significant repetition. Separating `batches` into its own table and using `batch_id` as a foreign key in `students` eliminates this.

### Example 2 — `course_title` and `course_code` repeated across problems, enrollments
If course information were embedded in the `problems` or `enrollments` rows, `CS101 – Programming Fundamentals` would repeat 67+ times (once per problem) and many more times across enrollments. The `courses` table isolates this; all other tables reference `course_id`.

### Example 3 — `student_id` in `regrade_requests` is partially redundant
`regrade_requests` stores both `submission_id` and `student_id`. Since every submission already has a `student_id`, this is redundant data. If a submission's student ever changed (unlikely, but theoretically), these two could become inconsistent. The redundancy is a deliberate design trade-off for query performance (see trade-offs section).

### Example 4 — Submission language and status repeated per test result
In the raw `test_results`, the `submission_id` points back to the parent submission where `language`, `student_id`, and `problem_id` live. If `test_results` had duplicated these columns, thousands of rows would carry repeated data. The current design avoids this via FK normalisation.

### Example 5 — `batch_code` stored as plain string in `raw_student_import`
The staging table stores `batch_code` as a raw string instead of a `batch_id` FK. This is intentional for staging, but it means the same batch like `CSE2025A` is repeated as a string across many rows rather than being normalised to a single reference.

---

## Where Separating Data Into Another Table Improves Design

### Separation 1 — `test_cases` separated from `problems`
Without a separate `test_cases` table, you would need multi-valued columns or repeated rows per problem. Since each problem has 3–7 test cases, embedding them in `problems` would either violate 1NF (multi-value cells) or cause massive row duplication. The `test_cases` table with `problem_id` FK cleanly handles this one-to-many relationship.

### Separation 2 — `contest_problems` as a junction table
A contest can include many problems, and a problem can appear in many contests. Without `contest_problems`, you'd need to embed a list of problems in each `contests` row (violates 1NF) or repeat contest details in every problem (massive redundancy). The junction table is the correct relational solution.

---

## Functional Dependencies and Partial Dependencies

### Functional Dependency 1 — In `enrollments`
`enrollment_id → student_id, course_id, enrolled_on, enrollment_status, final_grade`

Also: `(student_id, course_id) → enrolled_on, enrollment_status, final_grade`

This means the composite `(student_id, course_id)` is itself a candidate key and functionally determines all non-key attributes. There is no partial dependency issue here since we use a surrogate PK.

### Functional Dependency 2 — In `test_results`
`result_id → submission_id, test_case_id, result_status, runtime_ms, memory_kb, awarded_points`

Also: `(submission_id, test_case_id) → result_status, runtime_ms, memory_kb, awarded_points`

Both the surrogate PK and the composite key fully determine all attributes — no partial dependency.

### Partial Dependency Example — In `regrade_requests`
`(request_id) → student_id` and also `submission_id → student_id`

This is a transitive / partial redundancy: `student_id` in `regrade_requests` can be derived from `submission_id → submissions.student_id`. Strictly speaking, this is a 3NF concern since `student_id` is determined by a non-key attribute (`submission_id`). It has been kept as a deliberate performance trade-off (see below).

---

## Normal Form Assessment

### 1NF — First Normal Form
**Achieved.** All tables have:
- Atomic (single-valued) columns — no comma-separated lists or arrays in any field
- A defined primary key per table
- No repeating groups

The `raw_student_import` table is intentionally staging and not held to the same standard as the relational schema.

### 2NF — Second Normal Form
**Achieved.** No table with a composite primary key has a non-key attribute that depends on only part of the composite key.

For example, in `contest_problems`, the only non-key attribute is `problem_order`, and it depends on the full `(contest_id, problem_id)` pair — not just one of them. If it depended only on `problem_id`, that would be a partial dependency. It does not.

### 3NF — Third Normal Form
**Mostly achieved.** Most non-key attributes depend directly on the primary key and nothing else.

One deliberate deviation: `regrade_requests.student_id` is transitively determined via `submission_id`. This is a trade-off — strictly 3NF would remove `student_id` from `regrade_requests` and require a join to retrieve it. We keep it for query convenience.

---

## Trade-offs in This Design

| Decision | Trade-off Made | Justification |
|----------|----------------|---------------|
| `student_id` kept in `regrade_requests` | Slight 3NF violation | Avoids join through submissions just to filter by student |
| Surrogate PKs used everywhere | Slightly more storage than natural keys | Avoids cascading updates if natural keys change (e.g. roll number correction) |
| `raw_student_import` not normalised | Redundant `batch_code` strings | Staging tables are intentionally denormalised; data is validated before promotion to main tables |
| `contest_id` nullable in `submissions` | Cannot use NOT NULL | Needed to represent practice submissions that are not part of any contest |
| `similarity_score > 100` allowed in raw data | CHECK constraint added in schema | Raw data has values like `125.0` — the schema enforces 0–100; data cleaning needed before import |
