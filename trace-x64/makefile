.PHONY: help
help:
	@echo 'make rel     - release build + test'
	@echo 'make test    - all + run tests'
	@echo 'make testv   - all + run verbose tests'
	@echo 'make all     - trace + print + sym'
	@echo 'make trace   - compile tracer'
	@echo 'make print   - compile printer'
	@echo 'make sym     - compile sym-map.awk'
	@echo 'make clean   - clean up'
	@echo 'make help    - this screen'

CXX := g++
USER_FLAGS := 
FLAGS := -I. -Wall -Wfatal-errors $(USER_FLAGS)

OBJ_DIR := ./obj

.PHONY: rel
rel: FLAGS += -O3
rel: clean all test

TEST_DIR := ./tests
.PHONY: test
test: all
	bash -c "diff <($(TEST_DIR)/run-tests.sh x | grep -Eo '^test_[^ ]+' | sort -u) <(cat $(TEST_DIR)/run-tests-*.sh | grep 'function test_' | cut -d ' ' -f 2 | sort)"

.PHONY: testv
testv: all
	$(TEST_DIR)/run-tests.sh x

.PHONY: all
all: trace print sym

SYM_MAP_BASE := sym-map
SYM_MAP_AWK := $(SYM_MAP_BASE).awk
SYM_MAP_DIR := ./$(SYM_MAP_BASE)
SYM_MAP_DEP := $(SYM_MAP_DIR)/sym_map.awk
SYM_MAP_DEP += $(SYM_MAP_DIR)/awklib_prog.awk
SYM_MAP_DEP += $(SYM_MAP_DIR)/awklib_exec_cmd.awk

.PHONY: sym
sym: $(SYM_MAP_AWK)

$(SYM_MAP_AWK): $(SYM_MAP_DEP)
	cat $^ > $@ && chmod +x $@

PARSE_OPTS_DIR := ./parse-opts
PARSE_OPTS_GEN := $(PARSE_OPTS_DIR)/parse-opts-gen.awk
PARSE_OPTS_SRC := $(PARSE_OPTS_DIR)/parse_opts.c
PARSE_OPTS_O := $(OBJ_DIR)/parse_opts.o

.PHONY: parse-opts
parse-opts: $(PARSE_OPTS_O)
$(PARSE_OPTS_O): $(PARSE_OPTS_SRC)
	$(CXX) -c $^ -o $@ $(FLAGS)

ERR_DIR := ./err
ERR_SRC := $(ERR_DIR)/err.c
ERR_O := $(OBJ_DIR)/err.o

.PHONY: err
err: $(ERR_O)
$(ERR_O): $(ERR_SRC)
	$(CXX) -c $^ -o $@ $(FLAGS)

TRACE_DIR := ./trace
TRACE_BASE := tx64-trace
TRACE_OPTS_DEFN := $(TRACE_DIR)/opts-defn.txt
TRACE_OPTS_INCC := $(TRACE_DIR)/opts_definitions.ic
TRACE_SRC := $(TRACE_DIR)/$(TRACE_BASE).c
TRACE_O := $(OBJ_DIR)/$(TRACE_BASE).o
TRACE_DEP := $(TRACE_O) $(PARSE_OPTS_O) $(ERR_O)

.PHONY: trace
trace: parse-opts err trace-opts $(TRACE_BASE)

$(TRACE_BASE): $(TRACE_OPTS_INCC) $(TRACE_DEP)
	$(CXX) $(TRACE_DEP) -o $@ $(FLAGS)

$(TRACE_O): $(TRACE_SRC) $(TRACE_OPTS_INCC)
	$(CXX) -c $(TRACE_SRC) -o $@ $(FLAGS)

.PHONY: trace-opts
trace-opts: $(TRACE_OPTS_INCC)

$(TRACE_OPTS_INCC): $(TRACE_OPTS_DEFN)
	awk -f $(PARSE_OPTS_GEN) -vOutDir=$(TRACE_DIR) $^

PRINT_DIR := ./print
PRINT_BASE := tx64-print
PRINT_SRC := $(PRINT_DIR)/$(PRINT_BASE).c
PRINT_OPTS_DEFN := $(PRINT_DIR)/opts-defn.txt
PRINT_OPTS_INCC := $(PRINT_DIR)/opts_definitions.ic
PRINT_O := $(OBJ_DIR)/$(PRINT_BASE).o
LIB_CAPSTONE_DIR := $(PRINT_DIR)/capstone
LIB_CAPSTONE_A := $(LIB_CAPSTONE_DIR)/libcapstone-5.0.a
LIB_CAPSTONE_INCL_DIR := $(LIB_CAPSTONE_DIR)/include
PRINT_DEP := $(PRINT_O) $(PARSE_OPTS_O) $(ERR_O) $(LIB_CAPSTONE_A)

.PHONY: print
print: parse-opts err print-opts $(PRINT_BASE)

$(PRINT_BASE): $(PRINT_OPTS_INCC) $(PRINT_DEP)
	$(CXX) $(PRINT_DEP) -o $@ $(FLAGS)

$(PRINT_O): $(PRINT_SRC) $(PRINT_OPTS_INCC)
	$(CXX) -I $(LIB_CAPSTONE_INCL_DIR) -c $(PRINT_SRC) -o $@ $(FLAGS)

.PHONY: print-opts
print-opts: $(PRINT_OPTS_INCC)

$(PRINT_OPTS_INCC): $(PRINT_OPTS_DEFN)
	awk -f $(PARSE_OPTS_GEN) -vOutDir=$(PRINT_DIR) $^

EXAMPLE_TOOLS_DIR := ./example-tools
TO_CLEAN := $(OBJ_DIR)/*.o $(TEST_DIR)/*.bin $(EXAMPLE_TOOLS_DIR)/*.bin
TO_CLEAN += $(TRACE_BASE) $(PRINT_BASE) $(SYM_MAP_AWK)
.PHONY: clean
clean:
	rm -f $(TO_CLEAN)
