.SUFFIXES: .bin
.PRECIOUS:	%.ngd %.ncd %.twx vivado/%.xpr bin/%.bit bin/%.mcs bin/%.M65 bin/%.BIN

COPT=	-Wall -g -std=gnu99
CC=	gcc

VIVADO=	./vivado_wrapper

GHDL=  ghdl/build/bin/ghdl

ASSETS=		assets
SRCDIR=		src
BINDIR=		bin
UTILDIR=	$(SRCDIR)/utilities
TESTDIR=	$(SRCDIR)/tests
VHDLSRCDIR=	$(SRCDIR)/vhdl
VERILOGSRCDIR=	$(SRCDIR)/verilog

SDCARD_DIR=	sdcard-files

all:	$(BINDIR)/mega65r2.mcs 

$(GHDL):
	git submodule init
	git submodule update
	( cd ghdl && ./configure --prefix=./build && make && make install )

#-----------------------------------------------------------------------------

# Generate Vivado .xpr from .tcl
vivado/%.xpr: 	vivado/%_gen.tcl | $(VHDLSRCDIR)/*.vhdl $(VHDLSRCDIR)/*.xdc 
	echo MOOSE $@ from $<
	$(VIVADO) -mode batch -source $<

$(BINDIR)/%.bit: 	vivado/%.xpr $(VHDLSRCDIR)/*.vhdl $(VHDLSRCDIR)/*.xdc $(VERILOGSRCDIR)/*.v 
	echo MOOSE $@ from $<
#	@rm -f $@
#	@echo "---------------------------------------------------------"
#	@echo "Checking design for timing errors and unroutes..."
#	@grep -i "all signals are completely routed" $(filter %.unroutes,$^)
#	@grep -iq "timing errors:" $(filter %.twr,$^); \
#	if [ $$? -eq 0 ]; then \
#		grep -i "timing errors: 0" $(filter %.twr,$^); \
#		exit $$?; \
#	fi
#	@echo "Design looks good. Generating bitfile."
#	@echo "---------------------------------------------------------"

	mkdir -p $(SDCARD_DIR)
	$(VIVADO) -mode batch -source vivado/$(subst bin/,,$*)_impl.tcl vivado/$(subst bin/,,$*).xpr
	cp vivado/$(subst bin/,,$*).runs/impl_1/container.bit $@
	# Make a copy named after the commit and datestamp, for easy going back to previous versions
	cp $@ $(BINDIR)/$*-`$(TOOLDIR)/gitversion.sh`.bit

$(BINDIR)/%.mcs:	$(BINDIR)/%.bit
	mkdir -p $(SDCARD_DIR)
	$(VIVADO) -mode batch -source vivado/run_mcs.tcl -tclargs $< $@

clean:
	rm -rf vivado/{mega65r2,megaphoner1}.{cache,runs,hw,ip_user_files,srcs,xpr}
