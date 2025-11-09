SHELL := bash
GOOS ?= linux
GOARCH ?= amd64
BINARY := bootstrap
PKG := gringotts-bank-backend
DIST := dist

.PHONY: build
build:
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=0 go build -tags lambda.norpc -ldflags "-s -w" -o $(BINARY) ./lambda/GetHealthcheckAPI/cmd

.PHONY: package
package: build
	mkdir -p $(DIST)
	zip -j $(DIST)/health.zip $(BINARY)

.PHONY: clean
clean:
	rm -f $(BINARY)
	rm -rf $(DIST)
