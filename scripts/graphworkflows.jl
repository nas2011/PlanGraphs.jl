begin
    using Pkg
    Pkg.activate(".")
    include("../src/PlanGraphs.jl")
    using .PlanGraphs
    using Compose
end



##
# 1. Initialize the Plan
pipeline = PlanGraph("Churn Prediction", "End-to-end ML pipeline with parallel training")

# --- STEP 1: Ingestion (The Root) ---
ingest = StepConfig(name="Data Ingestion", about="Load from S3", maxIter=1, level=1,run=()->print("Start"))
addStep!(pipeline, ingest) # afterNodes defaults to nothing

# --- STEP 2: Validation (Series) ---
validate = StepConfig(name="Data Validation", about="Check for schema drift", maxIter=1, level=2,run=()->print("Second Step"))
addStep!(pipeline, validate, afterNodes=[ingest])

# --- STEP 3: Feature Engineering (Parallel Branching) ---
# We branch out here: numeric and text processing happen at the same time
feat_num = StepConfig(name="Numeric Scaling", about="StandardScaler on continuous vars", maxIter=1, level=3,run=()->print("level 3"))
feat_text = StepConfig(name="Text Vectorization", about="TF-IDF on support tickets", maxIter=1, level=3,run=()->print("level 3"))

addStep!(pipeline, feat_num, afterNodes=[validate])
addStep!(pipeline, feat_text, afterNodes=[validate])

# --- STEP 4: Model Training (Parallel) ---
# Model A waits for numeric features; Model B waits for both
train_rf = StepConfig(name="Random Forest", about="Train baseline RF", maxIter=5, level=4,run=()->print("level 4"))
train_xgb = StepConfig(name="XGBoost", about="Train gradient boosted trees", maxIter=10, level=4,run=()->print("level 4"))

addStep!(pipeline, train_rf, afterNodes=[feat_num])
addStep!(pipeline, train_xgb, afterNodes=[feat_num, feat_text])

# --- STEP 5: Evaluation (Convergence / Join) ---
# This step won't trigger until both training steps are complete
evaluate = StepConfig(name="Model Evaluation", about="Compare ROC-AUC scores", maxIter=1, level=5,run=()->print("level 5"))
addStep!(pipeline, evaluate, afterNodes=[train_rf, train_xgb])

# --- STEP 6: Deployment (Final Series) ---
deploy = StepConfig(name="Deployment", about="Push winning model to SageMaker", maxIter=1, level=6,run=()->print("End"))
addStep!(pipeline, deploy, afterNodes=[evaluate])
##

printPlanLevels(pipeline)

viz = plotPG(pipeline)

draw(SVG("test.svg",25cm, 25cm), viz)


## Agent Example
# --- INITIALIZE PLAN ---
bio_plan = PlanGraph("Bio-Agent-Discovery", "Multi-agent protein binder design")

# --- STAGE 1: TARGET PROFILING ---
target_analyst = StepConfig(
    name="Target Profiler", 
    about="Extracting binding pockets", 
    run=x -> println("Executing: Target Profiler"),
    maxIter=1, level=1
)
addStep!(bio_plan, target_analyst)

# --- STAGE 2: PARALLEL ANALYSIS ---
struct_agent = StepConfig(
    name="AlphaFold-Consultant", 
    about="Structural flexibility", 
    run=x -> println("Executing: AlphaFold-Consultant"),
    maxIter=3, level=2
)
func_agent = StepConfig(
    name="Pathway-Specialist", 
    about="Biological context", 
    run=x -> println("Executing: Pathway-Specialist"),
    maxIter=1, level=2
)
lit_agent = StepConfig(
    name="PubMed-Miner", 
    about="Literature mining", 
    run=x -> println("Executing: PubMed-Miner"),
    maxIter=5, level=2
)

addStep!(bio_plan, struct_agent, afterNodes=[target_analyst])
addStep!(bio_plan, func_agent,   afterNodes=[target_analyst])
addStep!(bio_plan, lit_agent,    afterNodes=[target_analyst])

# --- STAGE 3: COORDINATION ---
design_coord = StepConfig(
    name="Design-Coordinator", 
    about="Consolidating reports", 
    run=x -> println("Executing: Design-Coordinator"),
    maxIter=1, level=3
)
addStep!(bio_plan, design_coord, afterNodes=[struct_agent, func_agent, lit_agent])

# --- STAGE 4: PARALLEL DESIGN ---
mpnn_designer = StepConfig(
    name="ProteinMPNN-Expert", 
    about="Sequence design", 
    run=x -> println("Executing: ProteinMPNN-Expert"),
    maxIter=10, level=4
)
rf_designer = StepConfig(
    name="RFDiffusion-Expert", 
    about="Backbone generation", 
    run=x -> println("Executing: RFDiffusion-Expert"),
    maxIter=10, level=4
)

addStep!(bio_plan, mpnn_designer, afterNodes=[design_coord])
addStep!(bio_plan, rf_designer,   afterNodes=[design_coord])

# --- STAGE 5: PARALLEL VALIDATION ---
stability_agent = StepConfig(
    name="Stability-Oracle", 
    about="DeltaG calculation", 
    run=x -> println("Executing: Stability-Oracle"),
    maxIter=1, level=5
)
docking_agent = StepConfig(
    name="DiffDock-Agent", 
    about="Binding affinity simulation", 
    run=x -> println("Executing: DiffDock-Agent"),
    maxIter=1, level=5
)

addStep!(bio_plan, stability_agent, afterNodes=[mpnn_designer, rf_designer])
addStep!(bio_plan, docking_agent,   afterNodes=[mpnn_designer, rf_designer])

# --- STAGE 6: FINAL SYNTHESIS ---
final_pi = StepConfig(
    name="Principal-Investigator", 
    about="Final report and ranking", 
    run=x -> println("Executing: Principal-Investigator"),
    maxIter=1, level=6
)
addStep!(bio_plan, final_pi, afterNodes=[stability_agent, docking_agent])

printPlanLevels(bio_plan)

bioViz = plotPG(bio_plan)
draw(SVG("./scripts/viz.svg",25cm, 25cm), bioViz)
