locals {
  domain      = format("ray.%s", trimprefix("${var.subdomain}.${var.base_domain}", "."))
  domain_full = format("ray.%s.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)

  helm_values = [{
    raycluster = {
      image = {
        repository = "gersonrs/ray-ml"
        tag        = "v1"
      }

      head = {
        # containerEnv = []
        # - name: EXAMPLE_ENV
        #   value: "1"
        # envFrom = []
        # - secretRef:
        #     name: my-env-secret
        resources = {
          requests = { for k, v in var.resources.head.requests : k => v if v != null }
          limits   = { for k, v in var.resources.head.limits : k => v if v != null }
        }
      }
      worker = {
        replicas = var.replicas
        resources = {
          requests = { for k, v in var.resources.worker.requests : k => v if v != null }
          limits   = { for k, v in var.resources.worker.limits : k => v if v != null }
        }
      }
      ingress = {
        # -- Specifies if you want to create an ingress access
        enabled : true
        # -- New style ingress class name. Only possible if you use K8s 1.18.0 or later version
        className : "traefik"
        # -- Additional ingress annotations
        annotations = {
          "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
          "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
          "traefik.ingress.kubernetes.io/router.tls"         = "true"
        }
        hosts = [
          {
            host = local.domain
            paths = [{
              path     = "/"
              pathType = "ImplementationSpecific"
            }]
          },
          {
            host = local.domain_full
            paths = [{
              path     = "/"
              pathType = "ImplementationSpecific"
            }]
          }
        ]
        # -- Ingress tls configuration for https access
        tls : [{
          secretName = "ray-ingres-tls"
          hosts = [
            local.domain,
            local.domain_full
          ]
        }]
      }
    }

  }]
}
