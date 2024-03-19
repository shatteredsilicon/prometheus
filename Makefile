BUILDDIR	?= /tmp/ssmbuild

ARCH	:= $(shell rpm --eval "%{_arch}")
VERSION	?= $(shell rpmspec -q --queryformat="%{version}" prometheus.spec)
RELEASE	:= $(shell rpmspec -q --queryformat="%{release}" prometheus.spec)

SRPM_FILE		:= $(BUILDDIR)/results/SRPMS/prometheus-$(VERSION)-$(RELEASE).src.rpm
RPM_FILE		:= $(BUILDDIR)/results/RPMS/prometheus-$(VERSION)-$(RELEASE).$(ARCH).rpm

.PHONY: all
all: srpm rpm

.PHONY: srpm
srpm: $(SRPM_FILE)

$(SRPM_FILE):
	mkdir -vp $(BUILDDIR)/rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
	mkdir -vp $(shell dirname $(SRPM_FILE))

	cp prometheus.spec $(BUILDDIR)/rpmbuild/SPECS/prometheus.spec
	cp prometheus.service $(BUILDDIR)/rpmbuild/SOURCES/prometheus.service
	sed -i -E 's/%\{\??_version\}/$(VERSION)/g' $(BUILDDIR)/rpmbuild/SPECS/prometheus.spec
	spectool -C $(BUILDDIR)/rpmbuild/SOURCES -g $(BUILDDIR)/rpmbuild/SPECS/prometheus.spec

	tar -C $(BUILDDIR)/rpmbuild/SOURCES/ -zxf $(BUILDDIR)/rpmbuild/SOURCES/prometheus-v$(VERSION).tar.gz
	cd $(BUILDDIR)/rpmbuild/SOURCES/prometheus-$(VERSION) && go mod vendor && tar -czf $(BUILDDIR)/rpmbuild/SOURCES/prometheus-v$(VERSION).tar.gz -C $(BUILDDIR)/rpmbuild/SOURCES prometheus-$(VERSION)

	rpmbuild -bs --define "debug_package %{nil}" --define "_topdir $(BUILDDIR)/rpmbuild" $(BUILDDIR)/rpmbuild/SPECS/prometheus.spec
	mv $(BUILDDIR)/rpmbuild/SRPMS/$(shell basename $(SRPM_FILE)) $(SRPM_FILE)

.PHONY: rpm
rpm: $(RPM_FILE)

$(RPM_FILE): $(SRPM_FILE)
	mkdir -vp $(BUILDDIR)/mock $(shell dirname $(RPM_FILE))
	mock -r ssm-9-$(ARCH) --resultdir $(BUILDDIR)/mock --rebuild $(SRPM_FILE)
	mv $(BUILDDIR)/mock/$(shell basename $(RPM_FILE)) $(RPM_FILE)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/{rpmbuild,mock,results}
