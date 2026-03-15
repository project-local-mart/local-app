# Localmart principles

*These principles define what Localmart is, why it exists, how it is built, and how it is governed. They are not aspirational slogans — they are the operating system for every decision made about this platform, from product design to pull request review.*

---

## Part I — Platform principles

### 1. Local means accountable

A local business is one with a human owner who is present in the community, accountable to their neighbors, and invested in the health of the place they operate in. Localmart exists to make those businesses more visible and more viable. When evaluating any product decision, the first question is: does this make it easier for a real local business owner to connect with the people in their community?

### 2. The community is not a metaphor

Every feature, policy, and design decision should strengthen the real-world community around local commerce — the neighborhood, the main street, the relationships between merchants and the people who shop with them. Localmart is not a directory. It is not a lead generation tool. It is infrastructure for local economic life.

### 3. We are not the platform — communities are

Localmart provides the technology. Local moderators provide the judgment, context, and human accountability that makes the platform trustworthy. The platform should always amplify the moderator's ability to serve their community, never replace or override it. Moderators are partners, not users.

### 4. Convenience should not come at the cost of integrity

Retail giants dominate because they are convenient. Localmart must be genuinely easy to use — for merchants, for moderators, and for consumers. But we will never trade away the things that make local commerce meaningful — community ownership, independent businesses, local accountability — in pursuit of growth or convenience. A feature that makes the platform easier but erodes its integrity is the wrong feature.

### 5. Data belongs to the community it comes from

Merchant data, product data, and community data generated on Localmart belongs to the merchants and communities that created it. Localmart will never monetize this data through advertising, sell it to third parties, or use it in ways that benefit the platform at the expense of the communities it serves. This is a binding commitment, not a privacy policy checkbox.

### 6. Privacy is not a feature — it is a right

Users of this platform — merchants, moderators, and consumers — have a right to expect that their data is handled with integrity and restraint. Localmart will never sell user data, never use it for advertising, and never share it with third parties for commercial purposes. This commitment applies to all data generated on the platform: merchant business information, product inventory, consumer search behavior, and community activity.

Localmart will collect only the data that is strictly necessary to operate the platform. Every piece of data collected must have a clear, specific purpose that serves the person who provided it — not the platform. When that purpose no longer applies, the data will be deleted.

Privacy is a design constraint, not an afterthought. Engineers building new features must ask at the outset: what data does this require, who can access it, how long is it retained, and what happens when a user asks for it to be removed. A feature that cannot answer those questions clearly is not ready to be built.

Localmart will comply with applicable privacy law — including GDPR, CCPA, and any future equivalents — as a floor, not a ceiling. Our standard is higher than legal compliance. The question is not "are we legally permitted to do this with this data?" The question is "would the person who provided this data be comfortable with how we are using it?"

### 7. Neutrality is not an option

Localmart is explicitly on the side of independent local businesses and the communities that depend on them. This is not a neutral marketplace. We make deliberate choices — about eligibility, about moderation, about feature priorities — that reflect a clear value: local, independent, community-rooted commerce is worth protecting and worth building for.

### 8. Accessibility over exclusivity

The platform must be usable by a merchant who is not technical, not well-resourced, and not fluent in e-commerce. A boutique owner who has never listed products online should be able to get their inventory discoverable within an hour of signing up. Complexity is a barrier that disproportionately affects exactly the businesses Localmart is designed to serve.

### 9. Build for the long term

Local commerce is not a trend. The shop local movement has deep roots and is growing. Localmart is not being built for a quick acquisition or a venture exit. Every architectural decision, governance choice, and community commitment should be made as if this platform will be running and serving communities in twenty years.

---

## Part II — Open source principles

### 10. Open source is the foundation, not the strategy

Localmart is open source because open source is the right model for community-owned infrastructure — not because it is a growth hack or a marketing position. The code being open means communities can trust the platform, inspect what it does, and hold it accountable. Any decision that compromises that trust compromises the entire project.

### 11. Strong vision, open contribution

Localmart is led by a small core team with a clear and opinionated vision for what this platform is and what it is not. This is intentional. The most enduring open source projects — Linux, Python, PostgreSQL, Vue — are not governed by consensus. They are led by people with strong convictions who accept contributions that advance the vision and decline contributions that do not.

This is not about gatekeeping for its own sake. It is about protecting the coherence and integrity of the platform for the communities that depend on it. Contributors are deeply valued. Their contributions are evaluated on merit and alignment — not on the seniority or prominence of who submits them.

### 12. Contribute to the direction, not just the code

The most valuable contributions are not always code. Identifying a problem with the merchant onboarding experience, documenting a policy edge case, translating the platform for a new community, or representing the perspective of a local business owner in a GitHub discussion — these contributions shape the platform as much as a pull request does. All forms of contribution are visible and valued.

### 13. Decisions are made openly and documented permanently

Significant decisions about the platform — architecture, policy, governance, roadmap — are made in the open and recorded permanently in the repository. Architecture Decision Records (ADRs) exist so that future contributors understand not just what was decided but why. A well-documented decision is more valuable than a correct decision that nobody can explain.

### 14. Disagree in the open, commit to the decision

Contributors may disagree with a direction or decision. That disagreement is welcome and should be expressed clearly, with reasoning, in the appropriate public channel — a GitHub issue, a discussion thread, a pull request comment. Once a decision is made by the core team, it is committed to and implemented. Relitigating settled decisions in every subsequent PR is not productive and will not be entertained.

### 15. The codebase is a public good — treat it as one

Every line of code merged into this repository will be read, maintained, and built upon by contributors and community operators who come after. Write code as if the person maintaining it in three years is someone you respect and will never meet. Documentation, tests, clear naming, and explanatory comments are not optional polish — they are how an open source project stays alive.

### 16. Dependencies are responsibilities

Every external dependency added to this project is a responsibility — a maintenance burden, a security surface, and a potential failure point for every community node running the platform. Dependencies should be added deliberately, with justification, and only when they provide substantial value that cannot be reasonably achieved otherwise. Preference will be given to dependencies that are themselves open source, actively maintained, and aligned with the project's values.

### 17. Protect the license with intention

Localmart is licensed under AGPL v3. This license was chosen deliberately to prevent commercial actors from taking the platform's code, building proprietary competing products, and using them against the communities Localmart is designed to serve. All contributions must be compatible with AGPL v3. All contributors must sign the Contributor License Agreement. The license is not negotiable and will not be weakened.

---

## Part III — Governance principles

### 18. Core team responsibilities

The core team is responsible for the strategic direction of the platform, the integrity of the codebase, and the health of the contributor community. Core team membership is earned through sustained, high-quality contribution and demonstrated alignment with the platform's principles. The core team will remain small by design — large committees make poor product decisions.

### 19. Moderators are community partners, not employees

Community moderators are volunteers who have chosen to invest their time in making Localmart work for their neighborhood. They are treated as partners with real standing in the project. Their feedback on how the platform serves their community is weighted heavily in product decisions. They are not support tickets to be managed.

### 20. Merchants are the reason this exists

Every product decision, every moderation policy, every onboarding flow should be evaluated from the perspective of a real independent merchant. Not a hypothetical user persona — a specific kind of person: a local business owner who has a physical store, employs people from the neighborhood, and has never had a real digital presence. If a decision makes that person's life harder, it is the wrong decision.

### 21. Growth follows value, not the other way around

Localmart will not optimize for growth metrics — active users, listing counts, node expansions — at the expense of community quality. A platform with fifty communities that are genuinely thriving is more successful than a platform with five hundred communities where merchants feel like numbers and moderators feel abandoned. Growth is a consequence of doing the work right, not a target to be chased.

---

*These principles are a living document. They will be updated as the project matures and as the communities Localmart serves teach us things we do not yet know. Changes to this document follow the same process as significant architecture decisions — proposed openly, discussed in public, and recorded with reasoning.*

*Version 1.1 — March 2026*
