# Versemend (version 1.0.0; current build = Contract 8) — TRIS form-input worksheet

The requestor's working worksheet for this product's TRIS form (Technology Request Information Sheet): every requestor-facing field, pre-filled from the submission evidence wherever the evidence supports a value. Anything only the requestor can supply is marked **[INPUT NEEDED: …]** — nothing here is invented. Numbers in parentheses are the TRIS template's row numbers, so each line can be checked against the form and against [CHECKLIST.md](CHECKLIST.md).

This is one product's slice of the combined six-product submission worksheet prepared 2026-11-11 (ONTrack, LightShow, Fathom, Versemend, the Salesforce MCP integration, and Niflheim were submitted together in one email). IT reviewer fields (template rows 66–91) need no requestor input and are not listed here.

## Shared submitter fields (rows 3–6, repeated on all six forms)

- Requestor (3): Matt A. Porter — Field Service Technician (FST), matthew.porter@tdstelecom.com
- Requestor's Manager (4): Josh Barter
- PAT Manager (5): [INPUT NEEDED: PAT Manager name — note: the process document names an Internal Employee Tools PAT contact as the AIR-access contact; that is not evidence he is the PAT Manager for this request]
- CoE Director (6): [INPUT NEEDED: CoE Director for the accountable Agile team — if left blank, the TRIS Administrator determines the accountable team, AM, and AD per the process document]

## Shared vendor fields (rows 10, 11, 42, plus the shared open-source fact at row 46)

Applies to the five Qompass AI products. The Salesforce integration's vendor is Salesforce; its vendor fields are in its own block below.

- Vendor Name (10): Qompass AI (the requestor's company; he is the developer/vendor)
- Website (11): qompass.ai
- What are the company's financial resources? (42): [INPUT NEEDED: the vendor financial-resources statement you want on record for Qompass AI — no figures exist in the package evidence]
- Has the governing Open Source license previously been reviewed by legal? (46, asked on every form): [INPUT NEEDED: whether Apache-2.0 has previously been reviewed by TDS legal — if not, this answer triggers legal review on each form]

## Product answers

- Technology Name (8): Versemend
- Technology Version (9): 1.0.0 (tree version). Current build is the Contract 8 build — curriculum Domain 8 complete; Android APK built 2026-11-10 (181,987,126 bytes, sha256 on record in the build report).
- Website (11): qompass.ai (no product-specific page in evidence; public repo: qompassai/versemend)
- Description (14): A structured training game that teaches the Lua programming language: a curriculum of domains (eight complete), each with gated, self-verifying exercises, adversarial "wrong draft" cases the player must diagnose, and boss challenges — Domain 8's boss is a sandboxed plugin host that runs hostile guest modules under capability grants. Rust host with vendored Lua 5.5; content in Lua. Current build passes 464/464 self-checks.
- How used at TDS (15): Self-paced scripting-fluency training for technical staff. Advancement is gated on verified mastery inside the game, so completion is measurable without an external assessment.
- Who will use it (16): Developers and technical staff who opt into the training. No operational user group.
- Technology replaced/removed (17): Nothing. No TDS technology, training product, or process is displaced.
- Direct customer impact (18): No — a standalone training game; touches no TDS customer system, website, or service.
- Supported internally or by vendor (19): Internally — by the developer (the requestor / Qompass AI).
- Production or test/development (20): Neither, in the TDS-systems sense — training content running on user devices; not a component of any TDS system.
- Impact if discontinued (21): Nothing operational; trainees lose a training aid.
- Backout plan/cost (22): Uninstall the app. Progress is stored on-device only; no data migration. Cost negligible.
- Similar technologies at TDS (23): [INPUT NEEDED: TDS training platforms already in use to name as related technology (e.g., Trailhead / LinkedIn Learning class offerings), if IT wants them named]
- Alternatives considered (24): [INPUT NEEDED: alternatives considered — e.g., conventional Lua courses, documentation self-study — and why a gated, self-verifying game is requested]
- AI component (26): No — a deterministic curriculum game; no AI component or model in the build. (Development used AI-assisted tooling — a method, not a component.)
- Internet access (28): No — offline single-player; no network features in the build record.
- Hosted internal/external (29): On the user's device only. No vendor-site hosting, no server component.
- Uploads data outside the Enterprise network (30): No.
- Inbound access to the Enterprise network (31): No — no network capability in the build record.
- Data collected (32): None — game progress and saves are stored on the device only.
- Java required (33): No user-facing Java requirement (the Android build uses the standard Gradle/Android toolchain at build time only).
- Microsoft 365 integration (34): No.
- Security risk assessment required (35): Requestor position: not required — offline training game, no data collection, no network, open-source code. Final determination is Security Engineering's.
- Cardholder/banking data (36): No.
- How licensed (38): Open Source — Apache License 2.0 (license field in the host Cargo.toml).
- License model (39): No per-user, concurrent, or server model; use is not controlled by license software or by TDS.
- License fees and quantity (40): No fees. Quantity not applicable — unrestricted open-source use.
- Support/maintenance fees (41): None.
- How long around (43): In active development through 2026; eight curriculum domains complete as of 2026-11-10 (Domain 9 is next and not yet started).
- Governing License (45): Apache License 2.0.
- License previously reviewed by legal (46): See the shared vendor block.
- Distributed / external use (47): Yes — public repository (qompassai/versemend). Per the template this requires legal review; declared openly.
- Modified by TDS (48): No modification by TDS planned.
- Directly impacts a product or service provided to customers (49): No — a standalone training game.
- Mobile — developer (51): Third party — the requestor (Matt A. Porter) as a Qompass AI product.
- Mobile — store certification (52): [INPUT NEEDED: store/listing status — the release APK is built in-house and hash-recorded; no store listing is in the evidence, and the APK's on-emulator install/launch verification has not yet run]
- Mobile — platforms (53): Google Android (APK); desktop via the Rust host (Linux build in evidence). No iOS build.
- Mobile — TDS fee / required for a TDS service (54): No fee; not required to use any TDS service.
- Mobile — confidential information (55): No — the game processes no user data beyond on-device progress.
- Mobile — third-party code (56): Yes — open-source Rust crates and the vendored Lua 5.5 runtime (via mlua), all open source; the open-source section above is completed. A dependency inventory can be generated from Cargo.lock on request.
- Mobile — user data collection language (57): The game collects no user data; progress stays on the device.
- Mobile — development tools/SDKs (58): Rust toolchain; Android SDK/Gradle for the APK build.
- Mobile — in-app purchase (59) / Apple push (60) / Game Center (61) / iCloud (62) / Passes (63) / Apple Maps (64): No — no iOS build.

---
*Worksheet slice prepared 2026-11-11 from the TRIS template and process documents and the submission package evidence. DRAFT — not yet submitted. See [README.md](README.md) for the status summary and the public-copy notes.*
