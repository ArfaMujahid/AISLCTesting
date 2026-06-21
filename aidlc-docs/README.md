# aidlc-docs — AI-DLC artifacts

Phase artifacts for the **AI Development Life Cycle**. Claude Code reads these at
the start of a session to understand *what's already been decided* so it doesn't
re-litigate settled architecture.

```
aidlc-docs/
├── requirements/   ← what we're building and why
├── architecture/   ← how the system is shaped
└── decisions/      ← ADRs: one file per significant, intentional decision
```

Rule of thumb: if a choice was deliberate and someone might later ask "why is it
this way?", write it down here as a decision record.
