# CodeJudge Database — Part 1: Relational Design, Keys & Normalization

## Overview

This repository contains the relational schema design for the **CodeJudge** platform — an online coding-practice and evaluation system used by a Computer Science department. The raw CSV exports have been analysed, and a normalised relational schema has been designed and implemented in SQL.

## Files

| File | Description |
|------|-------------|
| `schema.sql` | SQL DDL — all `CREATE TABLE` statements with constraints |
| `schema_explanation.md` | What each table represents and what each key column means |
| `keys_and_relationships.md` | Primary keys, candidate keys, foreign keys, composite keys, constraints with justification |
| `normalization_notes.md` | Redundancy analysis, functional dependencies, 1NF/2NF/3NF reasoning |
| `erd.md` | Entity-Relationship Diagram in Markdown text format |
| `assumptions.md` | Design assumptions and trade-offs |

## How to Run

```bash
sqlite3 codejudge.db < schema.sql
```

Or open `schema.sql` in **DB Browser for SQLite**.

## Dataset Summary

| Table | Rows |
|-------|------|
| batches | 6 |
| courses | 10 |
| students | 320 |
| enrollments | 719 |
| problems | 67 |
| test_cases | 330 |
| contests | 12 |
| contest_problems | 63 |
| submissions | 2501 |
| test_results | 9673 |
| sessions | 48 |
| attendance | 2352 |
| regrade_requests | 80 |
| plagiarism_flags | 60 |
| raw_student_import | 80 |
| operation_requests | 35 |
