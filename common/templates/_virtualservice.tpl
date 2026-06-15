{{/*
=============================================================================
common.virtualservice
Renders an Istio VirtualService (networking.istio.io/v1beta1) when
.Values.virtualService.enabled is true.

Use this INSTEAD OF common.ingress when the cluster routes traffic via
Istio's ingress gateway rather than a Kubernetes Ingress controller.
Both can be enabled simultaneously if you're migrating between the two.
=============================================================================
*/}}
{{- define "common.virtualservice" -}}
{{- if .Values.virtualService.enabled }}
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  hosts:
    {{- toYaml .Values.virtualService.hosts | nindent 4 }}
  {{- with .Values.virtualService.gateways }}
  gateways:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .Values.virtualService.http }}
  http:
    {{- tpl (toYaml .Values.virtualService.http) . | nindent 4 }}
  {{- else }}
  http:
    - route:
        - destination:
            host: {{ include "common.fullname" . }}
            port:
              number: {{ .Values.service.port }}
  {{- end }}
{{- end }}
{{- end -}}
