# Development Workflow Guide

## ?? For AI Assistants / Future Development

### Context Loading Strategy

When helping with this project, **always start by reading these files in order:**

1. **PROGRESS.md** (THIS IS PRIMARY CONTEXT)
   - Complete project status
   - All implemented features
   - Architecture overview
   - What's done vs what's planned

2. **README.md**
   - Setup instructions
   - Quick start guide
   - API endpoints reference

3. **Specific feature documentation** (only if needed)
   - For authentication: `README_AUTH.md`, `LOGOUT_FEATURE.md`
   - For schedules: `RECURRING_SCHEDULE_GUIDE.md`, `REFINED_SCHEDULE_API_GUIDE.md`
   - For timezones: `TIMEZONE_HANDLING_GUIDE.md`
   - For cleanup: `SCHEDULE_CLEANUP_GUIDE.md`

### Why This Approach?

? **Faster** - No need to analyze 50+ files  
? **Accurate** - PROGRESS.md maintained as single source of truth  
? **Complete** - All features, todos, and decisions documented  
? **Efficient** - Saves token usage and time  

### Workflow for New Features

1. **Read PROGRESS.md** - Understand what exists
2. **Check README.md** - Review setup and architecture
3. **Review specific docs** - Only for relevant features
4. **Make changes** - Implement feature
5. **Update PROGRESS.md** - Document what was added
6. **Update README.md** - If public API changed

### Maintenance Tasks

**When completing a feature:**
- ? Update PROGRESS.md with completion status
- ? Add to "Completed Features" section
- ? Update metrics (lines of code, endpoints, etc.)
- ? Move from "Next Phase" to "Completed"

**When starting a new feature:**
- ? Check PROGRESS.md for existing work
- ? Review related documentation
- ? Add to "In Progress" section
- ? Update upon completion

### Example Workflow

**? Old Way (Inefficient):**
```
1. Analyze Controllers/
2. Analyze Models/
3. Analyze Services/
4. Analyze DTOs/
5. Analyze Migrations/
6. Read 10+ documentation files
7. Finally understand project
```

**? New Way (Efficient):**
```
1. Read PROGRESS.md (5 min)
2. Understand complete status
3. Review relevant section only
4. Start implementing
```

---

## ?? PROGRESS.md Structure

The PROGRESS.md file contains:

### Section 1: Overview
- Project status
- Completion percentage
- Current phase

### Section 2: Completed Features
- Detailed feature breakdown
- Implementation status
- Key files for each feature
- Documentation links

### Section 3: Architecture
- Technology stack
- Project structure
- Database schema
- Relationships

### Section 4: Timeline
- Development phases
- Week-by-week progress
- Milestones achieved

### Section 5: Next Steps
- Planned features (Phase 2)
- Technical debt
- Future considerations

### Section 6: Metrics
- Code statistics
- Feature breakdown
- Test coverage

---

## ?? Keeping PROGRESS.md Current

### After Implementing a Feature

```markdown
### [Feature Name] (100%)

- ? Feature implementation
- ? Testing
- ? Documentation

**Key Files:**
- Path/to/file.cs

**Documentation:**
- FEATURE_GUIDE.md
```

### Moving to Next Phase

Update completion percentage:
```markdown
## Current Status

### Overall Completion: **Phase 2 (50%)**

| Feature Category | Status | Completion |
|-----------------|--------|------------|
| New Feature | ?? In Progress | 50% |
```

---

## ?? Best Practices

### DO:
? Read PROGRESS.md first  
? Update PROGRESS.md when adding features  
? Keep metrics current  
? Link to detailed documentation  
? Mark completed items with ?  

### DON'T:
? Skip reading PROGRESS.md  
? Let PROGRESS.md get outdated  
? Duplicate information across files  
? Forget to update completion percentages  

---

## ?? Benefits

### For Development
- ?? Faster onboarding
- ?? Clear project status
- ?? Know what's next
- ?? Single source of truth

### For AI Assistants
- ?? Complete context quickly
- ?? No need to analyze all files
- ? Faster responses
- ?? Accurate recommendations

### For Team Members
- ?? Understand project instantly
- ??? See roadmap clearly
- ? Know what's complete
- ?? Know what's planned

---

## ?? Documentation Hierarchy

```
PROGRESS.md (START HERE)
    ?
README.md (Setup & Quick Start)
    ?
Feature-Specific Guides (Deep Dive)
    ?
Implementation Details (Technical)
    ?
Code Files (Source)
```

---

## ? Summary

**Primary Context:** `PROGRESS.md`  
**Setup Guide:** `README.md`  
**Feature Guides:** `*_GUIDE.md` files  
**Technical Details:** `*_IMPLEMENTATION.md` files  

**Workflow:**  
Read PROGRESS.md ? Understand status ? Implement ? Update PROGRESS.md

**This approach saves time and ensures accuracy!** ???
