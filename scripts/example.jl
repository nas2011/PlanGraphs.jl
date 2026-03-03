include("../src/PlanGraphs.jl")
using .PlanGraphs
using Compose

bio_plan = PlanGraph("Binder-Discovery", "Multi-agent protein design")

# 2. Define the Root Agent

target_analyst = StepConfig(
    name="Target Profiler", 
    about="Extracting binding pockets", 
    run=x -> println("Executing: Target Profiler"),
    maxIter=1, level=1
)
addStep!(bio_plan, target_analyst)

# 3. Define Parallel Analysis Agents
struct_agent = StepConfig(
    name="AlphaFold-Consultant", 
    about="Structural flexibility", 
    run=x -> println("Executing: AlphaFold-Consultant"),
    maxIter=3, level=2
)

lit_agent = StepConfig(
    name="PubMed-Miner", 
    about="Literature mining", 
    run=x -> println("Executing: PubMed-Miner"),
    maxIter=5, level=2
)

# Add them to the graph, specifying they follow the 'target_analyst'
addStep!(bio_plan, struct_agent, afterNodes=[target_analyst])
addStep!(bio_plan, lit_agent,    afterNodes=[target_analyst])

# 4. Define a Consolidation Step (Convergence)
design_coord = StepConfig(
    name="Design-Coordinator", 
    about="Consolidating reports", 
    run=x -> println("Executing: Design-Coordinator"),
    maxIter=1, level=3
)
addStep!(bio_plan, design_coord, afterNodes=[struct_agent, lit_agent])

printPlanLevels(bio_plan)

bioViz = plotPG(bio_plan)
draw(SVG("./scripts/exViz.svg",25cm, 25cm), bioViz)