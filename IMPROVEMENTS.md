# Performance Improvement Plan

## 1. SSR Optimization (Critical)
- **Issue**: QuickJS VM initialization cost is high. Currently, thread-local VMs might be getting reset or not fully utilized in multi-threaded/fiber environments effectively.
- **Solution**:
  - [x] Ensure `Thread.current[:salvia_quickjs_vm]` is persistently reused.
  - [ ] Implement a proper connection pool for VMs if moving away from thread-local storage.
  - [x] Pre-load vendor bundles only once per VM (Implemented via Class-level caching).

## 2. Sidecar Communication
- **Issue**: HTTP/1.1 over TCP (localhost) adds latency for every bundle/check request.
- **Solution**:
  - [x] Switch to **Unix Domain Sockets (UDS)** for communication between Ruby and Deno Sidecar.
  - [ ] Implement keep-alive connections more aggressively.

## 3. Database Concurrency
- **Issue**: SQLite limits concurrency due to file locking, especially with multiple workers.
- **Solution**:
  - [x] Enable **WAL (Write-Ahead Logging) mode** for SQLite in production config.
  - [ ] Recommend PostgreSQL/MySQL for high-concurrency benchmarks.

## 4. Architecture
- **Issue**: `sage dev` uses a single process/thread (mostly), masking some race conditions or locking issues.
- **Solution**:
  - [x] Verify thread-safety of `Sage::Context` and `Salvia::SSR` under `falcon serve` (multi-process/multi-thread).


## Performance Benchmarks (2025-12-12)

With YJIT enabled on Sage Dev Server (Single Worker):

| Scenario | Req/Sec | Latency (ms) | Notes |
| :--- | :--- | :--- | :--- |
| **Hello World** | **17,164** | 1.14 | Approaching 4-worker performance |
| **SSR + DB** | **15,391** | 0.62 | Post-warmup (Cached SSR) |

**Result:** Achieved exceptional performance with YJIT, demonstrating that Ruby can be extremely fast for web workloads.
