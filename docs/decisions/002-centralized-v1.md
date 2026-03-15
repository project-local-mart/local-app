# ADR 002 — Centralized architecture for v1

**Date:** 2026-03-14
**Status:** Accepted

## Context

Localmart's long-term vision includes a federated architecture where independent community operators run their own nodes. However, federated infrastructure requires node operators to manage servers, handle uptime, and maintain databases — an unreasonable burden for volunteer community moderators.

## Decision

v1 will be a centralized, multi-tenant platform. Community moderators manage their community through a dashboard but do not manage any infrastructure. All data lives on Localmart-operated infrastructure.

## Rationale

Removing infrastructure burden from community moderators dramatically lowers the barrier to adoption. A moderator should spend their time curating their community, not debugging servers. Centralized infrastructure also allows faster iteration on the product without per-node deployment concerns.

## Consequences

The project will revisit federation in a future version once the platform has proven adoption and identified technically capable community operators who want sovereign nodes. The data model will maintain clean community boundaries (row-level security by communityId) to make a future federation migration feasible.
