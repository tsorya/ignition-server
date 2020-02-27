PWD = $(shell pwd)
UID = $(shell id -u)

all: build

.PHONY: build
build:
	mkdir -p build
	go build -o build/ignition-server cmd/main.go

clean:
	rm -rf build

generate-swagger:
	rm -rf client models restapi
	docker run -u $(UID):$(UID) -v $(PWD):$(PWD) -v /etc/passwd:/etc/passwd -w $(PWD) quay.io/goswagger/swagger generate server	--template=stratoscale -f swagger.yaml --template-dir=/templates/contrib
	docker run -u $(UID):$(UID) -v $(PWD):$(PWD) -v /etc/passwd:/etc/passwd -w $(PWD) quay.io/goswagger/swagger generate client	--template=stratoscale -f swagger.yaml --template-dir=/templates/contrib

########################################################################################################################
# subsystem tolling
########################################################################################################################

# configuration for subsystem
export KUBEVIRT_PROVIDER ?= k8s-1.16.2
#LOCAL_REGISTRY ?= registry:5000
CLUSTER_DIR ?= kubevirtci/cluster-up/
KUBECONFIG ?= $(CURDIR)/kubevirtci/_ci-configs/$(KUBEVIRT_PROVIDER)/.kubeconfig
export KUBECTL ?= $(CLUSTER_DIR)/kubectl.sh
CLUSTER_UP ?= $(CLUSTER_DIR)/up.sh
CLUSTER_DOWN ?= $(CLUSTER_DIR)/down.sh
CLI ?= $(CLUSTER_DIR)/cli.sh
export SSH ?= $(CLUSTER_DIR)/ssh.sh
install_kubevirtci := hack/install-kubevirtci.sh

$(CLUSTER_DIR)/%: $(install_kubevirtci)
	$(install_kubevirtci)

cluster-up: $(CLUSTER_UP)
	$(CLUSTER_UP)

cluster-down: $(CLUSTER_DOWN)
	$(CLUSTER_DOWN)

push-image:
	$(eval IMAGE_REGISTRY := localhost:$(shell KUBEVIRT_PROVIDER=$(KUBEVIRT_PROVIDER) $(CLI) ports registry | tr -d '\r'))
	docker tag $(IMAGE):$(HASH) $(IMAGE_REGISTRY)/$(IMAGE)
	docker push $(IMAGE_REGISTRY)/$(IMAGE)

sub-deploy: $(KUBECTL)
	$(KUBECTL) apply -f ./deploy/deployment.yaml

$(local_handler_manifest): deploy/operator.yaml
	mkdir -p $(dir $@)
	sed "s#REPLACE_IMAGE#$(LOCAL_REGISTRY)/$(HANDLER_IMAGE_FULL_NAME)#" \
		deploy/operator.yaml > $@

cluster-sync: push-image
	local_manifest=./deploy/deployment.yaml ./hack/cluster-sync-handler.sh

test:
	$(SSH)

########################################################################################################################
