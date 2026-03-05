# PlanGraphs.jl

[![Build Status](https://github.com/nas2011/PlanGraph.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/nas2011/PlanGraph.jl/actions/workflows/CI.yml?query=branch%3Amaster)

`PlanGraphs.jl` is a lightweight Julia framework for modeling workflows as **Directed Acyclic Graphs (DAGs)**.  
It allows you to define tasks as nodes, specify dependencies between them, and visualize how a multi-step process should be structured or parallelized.

The package is built on top of `MetaGraphsNext.jl` and is useful for planning structured workflows such as research pipelines, agentic processes, and reproducible task sequences.

---

## Installation

Install using the Julia package manager.

From the Julia REPL press `]` to enter the package prompt and run:

```julia
pkg> add https://github.com/nas2011/PlanGraphs.jl
```

---

## Core Concepts

The package revolves around two main structures:

* **StepConfig** — defines an individual workflow step
* **PlanGraph** — stores and manages the workflow DAG

---

## StepConfig

`StepConfig` defines a single unit of work within a workflow.

```julia
@kwdef mutable struct StepConfig
    name::String
    about::String
    run::Function
    maxIter::Int
    level::Int
end
```

Fields:

| Field     | Description                                                                    |
| --------- | ------------------------------------------------------------------------------ |
| `name`    | Unique identifier for the step within a graph                                  |
| `about`   | Human-readable description of the step                                         |
| `run`     | Function representing the step's logic (stored as metadata)                    |
| `maxIter` | Optional metadata describing the maximum number of iterations the step may run |
| `level`   | User-defined hierarchy level used for grouping and visualization               |

**Important:** `name` must be unique within a `PlanGraph`.

---

## PlanGraph

`PlanGraph` is the container that holds the workflow structure.

```julia
mutable struct PlanGraph
    mg::MetaGraph
    name::String
    about::String
end
```

Internally it wraps a `MetaGraph` built on `Graphs.jl` to store the DAG structure and step metadata.

---

## Defining Dependencies

Dependencies between steps are specified using `addStep!`.

```julia
addStep!(pg::PlanGraph, step::StepConfig; afterNodes=nothing)
```

* `step` is the `StepConfig` to add
* `afterNodes` is an optional vector of steps that **must precede** the new step

**Note:** `addStep!` asserts that all steps listed in `afterNodes` already exist in the graph. Passing a step that has not yet been added will raise an error.

If step **B** lists step **A** in `afterNodes`, the graph will contain the directed edge:

```
A → B
```

Multiple steps depending on the same predecessor naturally represent **parallel branches** in the workflow.

---

## Quick Start Example: Milk Run Workflow

This example shows how a simple set of instructions can be modeled as a workflow graph.

```julia
using PlanGraphs

milk_plan = PlanGraph("Milk Run", "A simple household errand workflow")

check_fridge = StepConfig(
    name="Check Fridge",
    about="Determine if milk is needed",
    run=x->println("Checking fridge"),
    maxIter=1,
    level=1
)

grab_keys = StepConfig(
    name="Grab Keys",
    about="Retrieve car keys",
    run=x->println("Keys grabbed"),
    maxIter=1,
    level=2
)

drive_store = StepConfig(
    name="Drive to Store",
    about="Travel to the grocery store",
    run=x->println("Driving"),
    maxIter=1,
    level=3
)

buy_milk = StepConfig(
    name="Buy Milk",
    about="Purchase milk",
    run=x->println("Purchasing milk"),
    maxIter=1,
    level=4
)

addStep!(milk_plan, check_fridge)
addStep!(milk_plan, grab_keys, afterNodes=[check_fridge])
addStep!(milk_plan, drive_store, afterNodes=[grab_keys])
addStep!(milk_plan, buy_milk, afterNodes=[drive_store])
```

This produces a simple linear dependency chain:

```
Check Fridge → Grab Keys → Drive to Store → Buy Milk
```

---

## Advanced Example: Multi-Agent Bioinformatics Workflow

This example models a research workflow where several analysis steps occur after initial target profiling.

```julia
using PlanGraphs

bio_plan = PlanGraph("Binder-Discovery", "Multi-agent protein design")

target_analyst = StepConfig(
    name="Target Profiler",
    about="Identify binding pockets",
    run=x->println("Executing: Target Profiler"),
    maxIter=1,
    level=1
)

addStep!(bio_plan, target_analyst)

struct_agent = StepConfig(
    name="AlphaFold-Consultant",
    about="Analyze structural flexibility",
    run=x->println("Executing: AlphaFold-Consultant"),
    maxIter=3,
    level=2
)

lit_agent = StepConfig(
    name="PubMed-Miner",
    about="Mine literature for known binders",
    run=x->println("Executing: PubMed-Miner"),
    maxIter=5,
    level=2
)

addStep!(bio_plan, struct_agent, afterNodes=[target_analyst])
addStep!(bio_plan, lit_agent, afterNodes=[target_analyst])

design_coord = StepConfig(
    name="Design-Coordinator",
    about="Consolidate analysis outputs",
    run=x->println("Executing: Design-Coordinator"),
    maxIter=1,
    level=3
)

addStep!(bio_plan, design_coord, afterNodes=[struct_agent, lit_agent])
```

This workflow creates a **branching DAG** where two analyses occur in parallel after target profiling and then converge at a consolidation step.

---

## Inspecting Workflow Levels

The function `printPlanLevels` prints the workflow grouped by user-defined levels, showing how steps could be distributed across threads for parallel execution.

```julia
printPlanLevels(bio_plan)
```

Example output:

```
|Level 1
|  1) Target Profiler<-----Run on Thread 1
|->Level 2
|    1) PubMed-Miner<-----Run on Thread 1
|    2) AlphaFold-Consultant<-----Run on Thread 2
|->->Level 3
|      1) Design-Coordinator<-----Run on Thread 1
```

Steps at the same level represent tasks that are independent of one another and can be run in parallel. The thread labels reflect a suggested layout based on level grouping.

---

## Visualizing the Graph

You can generate a graphical representation of the workflow.

```julia
plotPG(bio_plan)
```

Example output:

![Example Visual](./scripts/exViz.svg)

The visualization uses `GraphPlot.jl` and `Compose.jl` to display the structure of the DAG.

---

## When to Use PlanGraphs

`PlanGraphs.jl` is useful when you want to:

* Model structured workflows as DAGs
* Represent dependencies between steps
* Plan multi-agent or research pipelines
* Visualize task relationships before implementation
* Prototype workflow logic in Julia

---

## Dependencies

PlanGraphs builds on several Julia ecosystem packages:

* `Graphs.jl`
* `MetaGraphsNext.jl`
* `GraphPlot.jl`
* `GraphIO.jl`
* `EzXML.jl`
* `Compose.jl`
* `Cairo.jl`
* `Fontconfig.jl`
* `Colors.jl`

> **Note:** `Cairo.jl` and `Fontconfig.jl` may require system-level libraries to be installed on your platform. Refer to their respective documentation if you encounter installation issues.

---

## Contributing

Contributions, issues, and suggestions are welcome.

Feel free to open a pull request or issue on the [GitHub repository](https://github.com/nas2011/PlanGraphs.jl).