PWD := $(shell pwd)
GD_TRIALS := 2500000
LD_TRIALS := 1000000

gd1:
	@echo "Generating $@ from gd_template"
	@cp -r gd_template $@
	@# Configure the docking parameters
	@sed -i "s|DockingInitialPerturbation|DockingInitialPerturbation name=\"init_pert\" randomize1=\"true\" randomize2=\"true\"|" $@/dock.xml
	@sed -i "s|TRIALS|$(GD_TRIALS)|" $@/dock.xml
	@# Configure the replica docking parameters
	@sed -i "s|IN_PDB|$(PWD)/protein_complex/I13R2-scFv47_Hs.pdb|" $@/flags_replica_dock
	@sed -i "s|NATIVE_PDB|$(PWD)/protein_complex/I13R2-IL13_AFm.pdb|" $@/flags_replica_dock
	@sed -i "s|OUT_PATH_ALL|$(PWD)/$@/output|" $@/flags_replica_dock
	@sed -i "s|OUT_MPI_TRACER|$(PWD)/$@/logs/log|" $@/flags_replica_dock

gd2:
	@echo "Generating $@ from gd_template"
	@cp -r gd_template $@
	@# Configure the docking parameters
	@sed -i "s|DockingInitialPerturbation|DockingInitialPerturbation name=\"init_pert\" randomize1=\"true\" randomize2=\"false\"|" $@/dock.xml
	@sed -i "s|TRIALS|$(GD_TRIALS)|" $@/dock.xml
	@# Configure the replica docking parameters
	@sed -i "s|IN_PDB|$(PWD)/gd1/output/I13R2-scFv47_Hs.pdb|" $@/flags_replica_dock
	@sed -i "s|NATIVE_PDB|$(PWD)/protein_complex/I13R2-IL13_AFm.pdb|" $@/flags_replica_dock
	@sed -i "s|OUT_PATH_ALL|$(PWD)/$@/output|" $@/flags_replica_dock
	@sed -i "s|OUT_MPI_TRACER|$(PWD)/$@/logs/log|" $@/flags_replica_dock

gd3:
	@echo "Generating $@ from gd_template"
	@cp -r gd_template $@
	@# Configure the docking parameters
	@sed -i "s|DockingInitialPerturbation|DockingInitialPerturbation name=\"init_pert\" randomize1=\"false\" randomize2=\"false\" spin=\"true\"|" $@/dock.xml
	@sed -i "s|TRIALS|$(GD_TRIALS)|" $@/dock.xml
	@# Configure the replica docking parameters
	@sed -i "s|IN_PDB|$(PWD)/gd2/output/I13R2-scFv47_Hs.pdb|" $@/flags_replica_dock
	@sed -i "s|NATIVE_PDB|$(PWD)/protein_complex/I13R2-IL13_AFm.pdb|" $@/flags_replica_dock
	@sed -i "s|OUT_PATH_ALL|$(PWD)/$@/output|" $@/flags_replica_dock
	@sed -i "s|OUT_MPI_TRACER|$(PWD)/$@/logs/log|" $@/flags_replica_dock

ld:
	@echo "Generating $@ from ld_template"
	@cp -r ld_template $@
	@# Configure the docking parameters
	@sed -i "s|TRIALS|$(LD_TRIALS)|" $@/dock.xml
	@# Configure the replica docking parameters
	@sed -i "s|IN_PDB|$(PWD)/gd3/output/I13R2-scFv47_Hs.pdb|" $@/flags_replica_dock
	@sed -i "s|NATIVE_PDB|$(PWD)/protein_complex/I13R2-IL13_AFm.pdb|" $@/flags_replica_dock
	@sed -i "s|OUT_PATH_ALL|$(PWD)/$@/output|" $@/flags_replica_dock
	@sed -i "s|OUT_MPI_TRACER|$(PWD)/$@/logs/log|" $@/flags_replica_dock