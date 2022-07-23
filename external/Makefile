
.PHONY: repos

repos:
	helm repo add jetstack \
		https://charts.jetstack.io
	helm repo add metallb \
		https://metallb.github.io/metallb
	helm repo add ingress-nginx \
		https://kubernetes.github.io/ingress-nginx
	helm repo add coredns \
		https://coredns.github.io/helm
	helm repo add nvidia \
		https://helm.ngc.nvidia.com/nvidia

metallb:
	helm upgrade \
		--install \
		--create-namespace \
		metallb \
		-n metallb-system \
		metallb/metallb \
		-f metallb-values.yaml


nginx-cloud:
	helm upgrade \
		--install \
		--create-namespace \
		ingress-nginx-cloud \
		-n ingress-nginx-cloud \
		ingress-nginx/ingress-nginx \
		-f nginx-cloud-ingress-values.yaml

external-dns:
	helm upgrade \
		--install \
		--create-namespace \
		external-dns \
		-n external-dns \
		external-dns/external-dns \
		-f external-dns-values.yaml

nginx-lan:
	helm upgrade \
		--install \
		--create-namespace \
		ingress-nginx-lan \
		-n ingress-nginx-lan \
		ingress-nginx/ingress-nginx \
		-f nginx-lan-ingress-values.yaml

nginx-wg:
	helm upgrade \
		--install \
		--create-namespace \
		ingress-nginx-wg \
		-n ingress-nginx-wg \
		ingress-nginx/ingress-nginx \
		-f nginx-wg-ingress-values.yaml

coredns:
	helm upgrade \
		--install \
		--create-namespace \
		coredns \
		-n kube-system \
		coredns/coredns \
		-f coredns-values.yaml

librespeed:
	helm upgrade \
		--install \
		--create-namespace \
		librespeed \
		-n home \
		k8s-at-home/librespeed \
		-f librespeed-values.yaml

nvidia:
	helm upgrade \
		--install \
		--wait \
		--create-namespace \
		gpu-operator \
     		-n gpu-operator \
      		nvidia/gpu-operator \
      		--set driver.enabled=false \
      		--set toolkit.enabled=false
