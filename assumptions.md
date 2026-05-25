# Design Assumptions — CodeJudge Schema

This document records the assumptions and design decisions made during schema design where the raw data was ambiguous or contained quality issues.

---

## 1. Email Nullability in `students`

**Assumption:** `email` is allowed to be NULL in the schema, but a UNIQUE constraint is still applied.

**Reason:** The raw `students.csv` contains one record (`S0005`) with a NULL email and one (`S0018`) with a malformed email missing the `@` symbol. Rather than reject these records outright, we allow NULL and flag malformed values as a data quality issue to be resolved during import. Once cleaned, all emails should be present and unique.

---

## 2. `contest_id` is NULL for Practice Submissions

**Assumption:** A NULL `contest_id` in `submissions` means the submission was a standalone practice attempt, not tied to any contest.

**Reason:** 633 out of 2501 submissions (approximately 25%) have no `contest_id`. This is clearly intentional — students can practise problems outside contests. The FK constraint is still enforced for non-NULL values.

---

## 3. Duplicate Enrollment Handling

**Assumption:** The duplicate enrollment record for `(S0001, C006)` in the raw data is an error and should be deduplicated before importing into the clean schema.

**Reason:** The UNIQUE constraint on `(student_id, course_id)` reflects the business rule that a student cannot be enrolled in the same course twice. The duplicate rows have identical non-key values, confirming it is a data entry error.

---

## 4. Plagiarism Similarity Score > 100

**Assumption:** Similarity scores exceeding 100 (e.g., `125.0` in the raw data) are data quality errors. The schema enforces `similarity_score BETWEEN 0 AND 100`.

**Reason:** A percentage-based similarity score cannot logically exceed 100. These values must be corrected or excluded during the data cleaning step before import.

---

## 5. Regrade Request with Missing Submission

**Assumption:** One `regrade_requests` row references a `submission_id` that does not exist in `submissions`. This row will be rejected by the FK constraint during import.

**Reason:** The referential integrity rule requires every regrade request to point to a valid submission. The orphaned record is a data quality issue that should be investigated (the submission may have been deleted or the ID may be a typo).

---

## 6. `student_id` Retained in `regrade_requests`

**Assumption:** We retain the `student_id` column in `regrade_requests` as a denormalised convenience field, even though it can be derived via `submission_id → submissions.student_id`.

**Reason:** This is a deliberate 3NF trade-off. It allows administrators to filter regrade requests by student without joining to the submissions table, which is a common query pattern. The value must always match the student on the related submission.

---

## 7. `raw_student_import` Has No Foreign Keys

**Assumption:** The `batch_code` column in `raw_student_import` is stored as a plain string and not enforced as a FK to `batches(batch_code)`.

**Reason:** This is a staging table. Imported rows may reference batch codes that don't yet exist in the system, or may have typos. The FK check is deferred to the validation step when records are promoted to the `students` table.

---

## 8. Submission Status Values

**Assumption:** The status values `'Accepted'` and `'OK'` are treated as distinct valid statuses as they both appear in the raw data.

**Reason:** Both values are present in `submissions.csv`. While they may represent the same logical outcome, we preserve the distinction as-found to avoid data loss. A data migration or cleanup step could normalise these to a single value if required.

---

## 9. Batch–Course Relationship

**Assumption:** Courses are not directly tied to batches in the schema. The link between a student's batch and the courses they attend is implicit through `enrollments`.

**Reason:** The raw data shows students from different batches enrolled in the same courses, and the `courses` table has no `batch_id` column. Courses are platform-wide resources; batch-level scheduling (if any) is not modelled in the provided data.

---

## 10. `operation_requests` is an Audit/Log Table

**Assumption:** `operation_requests` is not used to enforce actual database changes — it is an approval log. Actual changes are performed separately after approval.

**Reason:** The table contains fields like `approval_status` and `executed_at`, which indicate a workflow where a request is submitted, reviewed, approved, and then acted upon. The schema reflects this as a standalone log table with no FK to the records being changed (since `target_record_id` spans multiple tables).
