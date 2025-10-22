---
description: Comprehensive GitLab merge request review using MCP tools
args:
  project_name: Name of the GitLab project (e.g., "gitlab-mr-mcp")
  mr_number: Merge request IID number (e.g., 42)
---

# GitLab Merge Request Review

You are performing a comprehensive code review of a GitLab merge request using ONLY the GitLab MCP tools available to you. You MUST NOT use bash, git, or any other command-line tools.

## Parameters
- **Project Name**: {{project_name}}
- **MR Number**: {{mr_number}}

## Workflow Instructions

Follow these steps EXACTLY in order:

### Step 1: Find Project ID

Call the `get_projects` MCP tool to retrieve all projects. Search through the results to find a project matching "{{project_name}}". The match can be:
- Exact match on project name
- Match on name_with_namespace
- Partial match (case-insensitive)

Extract the numeric project ID from the matching project.

If no matching project is found, inform the user and STOP.

### Step 2: Get File List

Call `merge_request_changes(project_id={{FOUND_ID}}, merge_request_id={{mr_number}})` to get the list of changed files.

This will return:
- MR title and metadata
- List of files with indices (0, 1, 2, ...)
- File status (new, modified, deleted, renamed)

Parse this output to extract:
- Total number of files changed
- File indices for each file

### Step 3: Fetch ALL File Diffs in Parallel

**CRITICAL**: Make parallel MCP tool calls to retrieve every single file diff, regardless of how many files there are.

In a SINGLE message, make multiple `merge_request_file_diff` calls like this:
- `merge_request_file_diff(project_id={{FOUND_ID}}, merge_request_id={{mr_number}}, file_index=0)`
- `merge_request_file_diff(project_id={{FOUND_ID}}, merge_request_id={{mr_number}}, file_index=1)`
- `merge_request_file_diff(project_id={{FOUND_ID}}, merge_request_id={{mr_number}}, file_index=2)`
- ... continue for ALL files

**Important**:
- Do NOT skip any files
- Do NOT use sequential calls - make them ALL in parallel in one message
- If there are 200 files, make 200 parallel calls
- This is the ONLY way to efficiently review large MRs

### Step 4: Analyze Each File

For each file diff retrieved, perform a thorough code review looking for:

#### Security Issues (CRITICAL Priority)
- SQL injection vulnerabilities
- XSS (Cross-Site Scripting) vulnerabilities
- Command injection risks
- Hardcoded secrets, API keys, passwords, tokens
- Insecure cryptography or weak hashing
- Authentication/authorization bypasses
- Path traversal vulnerabilities
- Insecure deserialization
- CSRF vulnerabilities
- Information disclosure

#### Bug Patterns (HIGH Priority)
- Null/undefined reference errors
- Off-by-one errors
- Race conditions or concurrency issues
- Resource leaks (unclosed files, connections, etc.)
- Incorrect error handling (swallowing exceptions, wrong error types)
- Logic errors (wrong conditionals, incorrect operators)
- Type mismatches or unsafe type conversions
- Infinite loops or recursion without base case
- Missing return statements
- Dead code or unreachable code

#### Performance Issues (MEDIUM Priority)
- N+1 query problems
- Inefficient algorithms (O(n²) where O(n log n) possible)
- Unnecessary loops or redundant operations
- Missing database indices
- Large object allocations in loops
- Synchronous operations that should be async
- Memory leaks
- Missing pagination for large datasets
- Inefficient data structures

#### Code Quality Issues (LOW to MEDIUM Priority)
- Code duplication (DRY violations)
- Overly complex functions (high cyclomatic complexity)
- Poor naming (unclear variables, functions, classes)
- Magic numbers without constants
- Inconsistent code style
- Missing or unclear comments for complex logic
- Long functions that should be split
- God classes or functions doing too much
- Tight coupling between modules
- Missing input validation

#### Testing & Documentation
- Missing test coverage for new features
- Missing test cases for edge cases
- Breaking changes without tests
- Missing or outdated documentation
- Missing error message clarity

### Step 5: Generate Comprehensive Report

Produce a structured markdown report with the following format:

```markdown
# Merge Request Review: [MR Title]

**Project**: {{project_name}}
**MR Number**: {{mr_number}}
**Files Analyzed**: [X files]
**Total Issues Found**: [Y issues]

---

## 🔴 Critical Issues

[List all critical security vulnerabilities here with:]
- **File**: path/to/file.ext:line_number
- **Issue**: Brief description
- **Impact**: Why this is critical
- **Recommendation**: How to fix

[If none found, write: "No critical issues found."]

---

## 🟠 High Priority Issues

[List all high-priority bugs and problems here with same format]

[If none found, write: "No high priority issues found."]

---

## 🟡 Medium Priority Issues

[List all medium-priority performance and quality issues]

[If none found, write: "No medium priority issues found."]

---

## 🟢 Low Priority Issues

[List all low-priority code quality suggestions]

[If none found, write: "No low priority issues found."]

---

## ✅ Positive Observations

[List good practices, well-written code, good test coverage, etc.]

---

## 📋 Summary & Recommendations

[Provide a concise summary of the review]

**Overall Assessment**: [APPROVE / APPROVE WITH COMMENTS / REQUEST CHANGES / REJECT]

**Key Actions Required**:
1. [Action item 1]
2. [Action item 2]
...

**Optional Improvements**:
1. [Suggestion 1]
2. [Suggestion 2]
...
```

## Constraints & Best Practices

**STRICT RULES**:
1. ✅ ONLY use GitLab MCP tools (get_projects, merge_request_changes, merge_request_file_diff)
2. ❌ DO NOT use bash, git, or any command-line tools
3. ✅ MUST fetch ALL files in parallel (single message, multiple tool calls)
4. ✅ MUST analyze EVERY file, even if there are 200+ files
5. ✅ MUST categorize issues by severity (Critical/High/Medium/Low)
6. ✅ MUST provide specific file paths and line numbers when possible
7. ✅ MUST provide actionable recommendations
8. ✅ Be thorough but concise - focus on real issues, not nitpicks

**Review Philosophy**:
- Prioritize security and correctness over style
- Be constructive and educational in feedback
- Acknowledge good practices when you see them
- Provide specific, actionable recommendations
- Consider the context and project type when reviewing

---

Begin the review now following the workflow above.
