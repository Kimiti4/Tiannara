  
Why Agentic Coding Is a Trap for Serious Engineers  
Sebastian Buzdugan

Agentic coding feels like cheating in the best possible way, until you realize you just shipped a pile of code you do not really understand. At that point, you are not an engineer anymore, you are tech support for a black box.

Before Agentic Coding, After Agentic Coding  
Before agentic coding, you wrote code, you debugged it, and your pain taught you things.

After agentic coding, you describe the feature, press a button, and a swarm of agents plans, edits, runs tests, and opens a pull request.

You feel productive. Your repo fills up. Your understanding does not.

That gap is the trap.

What Agentic Coding Actually Is  
If you have no idea what “agentic coding” is, think of it as Copilot with a nervous system.

Instead of single prompts that spit out snippets, you get multi step workflows.

The agent can:

Index your codebase and build a mental model of it.  
Plan a sequence of edits to implement a feature.  
Touch multiple files and modules.  
Run tests, read failures, and iterate.  
Frameworks like LangGraph, AutoGen, CrewAI, and SmolAgents are all playing in this space.

The sales pitch is simple. You stop being the implementer and become the orchestrator.

You tell the system what you want in a declarative way, then watch it do the imperative grind.

On paper, this sounds like the next logical upgrade to our jobs. In practice, it creates a nasty mix of technical debt and cognitive debt.

The Real Trap: Cognitive Debt  
Technical debt is code you owe. Cognitive debt is understanding you owe.

Agentic coding is extremely good at creating the second one.

When an agent edits ten files, passes the tests, and opens a PR, you now own that change. But you did not write it, and you did not discover the edge cases that normally would have hurt you along the way.

You can review the diff, sure. You cannot review the reasoning that never happened in your own head.

The more you lean on agents, the more your internal model of the system diverges from what is actually in the repo.

That divergence is cognitive debt.

It behaves like technical debt, but worse. You do not see it until something breaks in production and you realize you do not even know where to start.

Cognitive Atrophy Is Not A Hypothetical  
Skills degrade when you stop using them.

Right now, agents are pushing hardest on the exact skills that define a strong engineer.

Refactoring. Debugging. Architecture decisions. Careful migration work.

If you let the agent handle the “boring” parts, you are also giving up the friction that used to teach you.

Junior developers are especially exposed. They get the illusion of speed without the slow, annoying, foundational experiences that actually build expertise.

You can absolutely become the person who can talk about systems, but cannot fix one without an agent.

Once you are there, your career is now coupled to the tool’s availability, pricing, and failure modes.

That is not leverage. That is dependency.

Jagged Intelligence: Why Agents Are So Dangerous When They “Work”  
LLMs have what researchers call jagged intelligence.

They are absurdly good at some tasks and surprisingly bad at others.

You can get a beautiful multi step refactor, then discover a rookie mistake that no human with one month of framework experience would have made.

There is a real example from a Laravel codebase. One model generated an API call that used env() directly. If you have shipped Laravel apps, you know this blows up when you run config:cache in production.

Another model reviewed the code, caught the env() issue, and replaced it with config(). It still missed the production constraints around config caching.

So you had:

A system smart enough to refactor and review.  
A system dumb enough to miss a framework level footgun.  
That is jagged intelligence.

Agentic workflows multiply this effect. You are not just getting one jagged suggestion, you are getting a whole jagged plan.

If you are not deeply grounded in the code and the stack, you will not spot the cliffs.

The 80 Percent Problem  
Most agentic tools today consistently get you to about 80 percent correctness.

The last 20 percent is the ugly stuff.

Edge cases. Integration details. Weird environment constraints. Race conditions. Performance quirks.

A lot of engineers report a familiar pattern. The agent gets them a big head start, but debugging and hardening that code takes longer than writing a smaller, simpler version themselves.

The trap is that the 80 percent feels like a win. You see a ton of code. You see tests. Things run locally.

You do not see the missing 20 percent until you are deep in production issues.

Agentic coding does not remove work. It shifts work from “before merge” to “after incident”.

That is a bad trade if you care about reliability.

Why This Hits Production Teams Harder Than Hobby Projects  
Vibe coding is fine when you are hacking on a side project.

Paste some context, get some code, tweak it, ship it. Your risk surface is small and the blast radius is you.

Agentic engineering is different. We are talking about production environments, compliance requirements, and real users.

You are not allowed to vibe your way into a security vulnerability or a data loss incident.

In production, the job is not just to generate code. The job is to preserve the quality bar while scaling throughput.

Agentic systems do not naturally do that. You have to build the discipline layer around them.

Specs. Guardrails. Tests that actually matter. Review processes that are more than “skim the diff and click approve”.

Without that discipline, agentic coding is just a way to generate legacy code faster.

The RPI Workflow: A Saner Pattern  
One useful pattern that has emerged is the RPI workflow.

Research. Plan. Implement.

You use the agent heavily in the first two stages. You keep a tight grip on the third.

Research means getting context. Let the agent index the codebase, summarize modules, highlight dependencies, and find relevant patterns.

Planning means designing the change. You can ask the agent to propose a migration plan, outline steps, and surface risks.

Implementation is where the trap lives.

If you let the agent go wild here, you get a flood of edits with uneven quality and hidden assumptions.

A safer approach is:

Use the agent to propose specific diffs with very narrow scope.  
Keep edits small enough that you can review every line with real attention.  
Treat the agent as a collaborator, not an autonomous committer.  
The art is not “let the agent implement the whole feature”. The art is “let the agent do local, auditable work inside a plan you actually understand”.

Never Generate More Code Than You Can Review  
There is a simple rule that keeps you out of the worst traps.

Never generate more code than you can realistically review.

If an agent opens a PR that touches 40 files and you are “reviewing” it in 5 minutes, you are not reviewing. You are rubber stamping.

The review burden scales with the blast radius of the change. Agentic systems make it easy to explode that radius without feeling the cost.

You need to reintroduce friction.

Smaller tasks. Smaller diffs. Narrower scopes.

If the agent wants to refactor a whole subsystem, force it to do it in slices. File by file. Layer by layer.

Yes, this feels slower. It is still faster than debugging a giant, opaque refactor that broke in production.

Why Agentic Coding Is a Trap for Serious Engineers  
Sebastian Buzdugan

Agentic coding feels like cheating in the best possible way, until you realize you just shipped a pile of code you do not really understand. At that point, you are not an engineer anymore, you are tech support for a black box.

Before Agentic Coding, After Agentic Coding  
Before agentic coding, you wrote code, you debugged it, and your pain taught you things.

After agentic coding, you describe the feature, press a button, and a swarm of agents plans, edits, runs tests, and opens a pull request.

You feel productive. Your repo fills up. Your understanding does not.

That gap is the trap.

What Agentic Coding Actually Is  
If you have no idea what “agentic coding” is, think of it as Copilot with a nervous system.

Instead of single prompts that spit out snippets, you get multi step workflows.

The agent can:

Index your codebase and build a mental model of it.  
Plan a sequence of edits to implement a feature.  
Touch multiple files and modules.  
Run tests, read failures, and iterate.  
Frameworks like LangGraph, AutoGen, CrewAI, and SmolAgents are all playing in this space.

The sales pitch is simple. You stop being the implementer and become the orchestrator.

You tell the system what you want in a declarative way, then watch it do the imperative grind.

On paper, this sounds like the next logical upgrade to our jobs. In practice, it creates a nasty mix of technical debt and cognitive debt.

The Real Trap: Cognitive Debt  
Technical debt is code you owe. Cognitive debt is understanding you owe.

Agentic coding is extremely good at creating the second one.

When an agent edits ten files, passes the tests, and opens a PR, you now own that change. But you did not write it, and you did not discover the edge cases that normally would have hurt you along the way.

You can review the diff, sure. You cannot review the reasoning that never happened in your own head.

The more you lean on agents, the more your internal model of the system diverges from what is actually in the repo.

That divergence is cognitive debt.

It behaves like technical debt, but worse. You do not see it until something breaks in production and you realize you do not even know where to start.

Cognitive Atrophy Is Not A Hypothetical  
Skills degrade when you stop using them.

Right now, agents are pushing hardest on the exact skills that define a strong engineer.

Refactoring. Debugging. Architecture decisions. Careful migration work.

If you let the agent handle the “boring” parts, you are also giving up the friction that used to teach you.

Junior developers are especially exposed. They get the illusion of speed without the slow, annoying, foundational experiences that actually build expertise.

You can absolutely become the person who can talk about systems, but cannot fix one without an agent.

Once you are there, your career is now coupled to the tool’s availability, pricing, and failure modes.

That is not leverage. That is dependency.

Jagged Intelligence: Why Agents Are So Dangerous When They “Work”  
LLMs have what researchers call jagged intelligence.

They are absurdly good at some tasks and surprisingly bad at others.

You can get a beautiful multi step refactor, then discover a rookie mistake that no human with one month of framework experience would have made.

There is a real example from a Laravel codebase. One model generated an API call that used env() directly. If you have shipped Laravel apps, you know this blows up when you run config:cache in production.

Another model reviewed the code, caught the env() issue, and replaced it with config(). It still missed the production constraints around config caching.

So you had:

A system smart enough to refactor and review.  
A system dumb enough to miss a framework level footgun.  
That is jagged intelligence.

Agentic workflows multiply this effect. You are not just getting one jagged suggestion, you are getting a whole jagged plan.

If you are not deeply grounded in the code and the stack, you will not spot the cliffs.

The 80 Percent Problem  
Most agentic tools today consistently get you to about 80 percent correctness.

The last 20 percent is the ugly stuff.

Edge cases. Integration details. Weird environment constraints. Race conditions. Performance quirks.

A lot of engineers report a familiar pattern. The agent gets them a big head start, but debugging and hardening that code takes longer than writing a smaller, simpler version themselves.

The trap is that the 80 percent feels like a win. You see a ton of code. You see tests. Things run locally.

You do not see the missing 20 percent until you are deep in production issues.

Agentic coding does not remove work. It shifts work from “before merge” to “after incident”.

That is a bad trade if you care about reliability.

Why This Hits Production Teams Harder Than Hobby Projects  
Vibe coding is fine when you are hacking on a side project.

Paste some context, get some code, tweak it, ship it. Your risk surface is small and the blast radius is you.

Agentic engineering is different. We are talking about production environments, compliance requirements, and real users.

You are not allowed to vibe your way into a security vulnerability or a data loss incident.

In production, the job is not just to generate code. The job is to preserve the quality bar while scaling throughput.

Agentic systems do not naturally do that. You have to build the discipline layer around them.

Specs. Guardrails. Tests that actually matter. Review processes that are more than “skim the diff and click approve”.

Without that discipline, agentic coding is just a way to generate legacy code faster.

The RPI Workflow: A Saner Pattern  
One useful pattern that has emerged is the RPI workflow.

Research. Plan. Implement.

You use the agent heavily in the first two stages. You keep a tight grip on the third.

Research means getting context. Let the agent index the codebase, summarize modules, highlight dependencies, and find relevant patterns.

Planning means designing the change. You can ask the agent to propose a migration plan, outline steps, and surface risks.

Implementation is where the trap lives.

If you let the agent go wild here, you get a flood of edits with uneven quality and hidden assumptions.

A safer approach is:

Use the agent to propose specific diffs with very narrow scope.  
Keep edits small enough that you can review every line with real attention.  
Treat the agent as a collaborator, not an autonomous committer.  
The art is not “let the agent implement the whole feature”. The art is “let the agent do local, auditable work inside a plan you actually understand”.

Never Generate More Code Than You Can Review  
There is a simple rule that keeps you out of the worst traps.

Never generate more code than you can realistically review.

If an agent opens a PR that touches 40 files and you are “reviewing” it in 5 minutes, you are not reviewing. You are rubber stamping.

The review burden scales with the blast radius of the change. Agentic systems make it easy to explode that radius without feeling the cost.

You need to reintroduce friction.

Smaller tasks. Smaller diffs. Narrower scopes.

If the agent wants to refactor a whole subsystem, force it to do it in slices. File by file. Layer by layer.

Yes, this feels slower. It is still faster than debugging a giant, opaque refactor that broke in production.

Never Delegate What You Could Not Do Yourself  
Another rule that sounds harsh but works in practice.

Never delegate a task to an agent that you could not do yourself at a basic level.

You do not need to be the fastest person at implementing the feature. You do need to be able to reason about it.

If you cannot design a migration, you should not let an agent design it for you. You will not know if the plan is structurally unsafe.

If you cannot write a secure auth flow, you should not accept an agent generated one. You will not see the subtle security bugs.

This is not about gatekeeping. It is about epistemic grounding.

You want code that is correct for the right reasons, not just by pattern matching.

Research on agentic systems in safety contexts is already pushing in this direction. They argue for agents that can explain their reasoning and be checked for “right behavior for the right reasons”.

You should demand the same from yourself.

If you cannot explain why a change is safe, you are not in control. The agent is.

Use Agents Where They Shine  
This all sounds negative, so let us be precise.

Agentic coding is not useless. It is just misused.

Agents are great at:

Context gathering and summarization.  
Generating candidate designs and tradeoff lists.  
Producing boring, repetitive boilerplate.  
Exploring alternate implementations for you to compare.  
They are less great at:

Owning end to end implementation in unfamiliar systems.  
Making subtle architectural tradeoffs.  
Handling environment specific constraints.  
Discovering edge cases that only show up in weird traffic patterns.  
So tilt your usage.

Let agents help you think. Keep humans in the loop for the parts where correctness actually matters.

Use agents to:

Build task lists for a feature.  
Suggest refactor plans.  
Draft tests based on your spec.  
Generate scaffolding that you immediately trim and reshape.  
Do not use them as autonomous engineers.

Practical Guardrails For Teams  
If you run a team, you need policy, not vibes.

Some practical guardrails that work in real orgs:

Require human authored specs for non trivial changes, even if the agent helps draft them.  
Cap the number of files a single agent driven change can touch without extra review.  
Treat agent changes as “high risk” until they have survived a release or two.  
Track incidents where agents were involved and adjust workflows based on real failures.  
Also, monitor costs.

Agentic pipelines with indexing, planning, iteration, and testing can quietly rack up token bills. You might discover that the “productivity gain” is just moving spend from engineers to GPUs.

The Hidden Cost: Losing Your Internal Model  
The most dangerous part of agentic coding is not the bugs.

It is the erosion of your internal model of the system.

Great engineers carry a mental map of their codebases. They know how data flows, where invariants live, which parts are brittle.

Agentic workflows try to replace that with external memory. Indexes, embeddings, graphs, traces.

Those are useful. They are not a substitute for understanding.

Once you lose that internal model, you cannot make good tradeoffs. You cannot see how a seemingly local change will ripple through the system.

At that point, you have turned your own codebase into an opaque legacy system. Except this time, you built it.

Final Thoughts  
Agentic coding is not evil. It is just very easy to use it in a way that slowly destroys your skills and your systems.

The trap is not one big failure. It is a series of small delegations where you stop thinking just a bit earlier each time.

Use agents aggressively for research and planning. Use them carefully for implementation.

Never generate more code than you can honestly review. Never delegate work you cannot reason about yourself.

Raise your floor with AI, sure. Do not lower your ceiling.