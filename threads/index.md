---
type: index
title: Threads
description: Use when orienting to the persisted prose threads - working conversations captured as clean readable exchanges, one file per thread.
tags: [threads, index]
status: active
timestamp: 2026-06-25
---

# Threads

Persisted prose threads: working conversations captured as clean, readable exchanges
(prose only, tool calls and reasoning scratch stripped) so a later reader gets the
decisions without replaying a session. Floor-tier by default per the two-tier rule
(`okf/standard/tiers.md`); a thread promotes into the CB graph only when it produces an
adjudicated decision, which is authored as beliefs that cite the thread as their
stipulation artifact.

## How threads are authored

Each thread is the SSOT for its prose exchange - the canonical record of what each side
said. Tool calls, grounding queries, and reasoning scratch stay in the agent's session;
only the prose lands in the doc. Turn-based: the author writes a turn and saves; the
agent reads, runs any tool calls in-session, appends its turn to the doc, and leaves a
one-line pointer back in the session so the author knows it responded. Read-before-edit
on both sides, so neither clobbers the other's unsaved text. A thread opens at the OKF
floor and stays there while live.

Each thread's frontmatter also records the authoring agent as provenance: `model` (the
exact model id) and `effort` (the reasoning/thinking level it ran at).

## Contents
- [2026-06-25 - belief-by-belief audit (starting cb:a098)](2026-06-25-belief-audit.md) - the node-by-node belief audit and the schema questions it raised (atomicity, a negative-case field, mood-in-kind).
