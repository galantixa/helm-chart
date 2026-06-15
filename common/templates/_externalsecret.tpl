{{/*
=============================================================================
common.externalsecret
Renders an ExternalSecret (external-secrets.io) when
.Values.externalSecret.enabled is true.

This REPLACES a raw Kubernetes Secret resource: the External Secrets
Operator reads from secretStoreRef (Vault, AWS Secrets Manager, GCP Secret
Manager, etc.) and materializes a regular v1/Secret named
.Values.externalSecret.target.name (defaults to "<fullname>-secret" via
common.secretName). common.deployment references that materialized Secret
in envFrom — no plaintext secret values ever live in values.yaml or in Git.
=============================================================================
*/}}
{{- define "common.externalsecret" -}}
{{- if .Values.externalSecret.enabled }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  refreshInterval: {{ .Values.externalSecret.refreshInterval }}
  secretStoreRef:
    name: {{ .Values.externalSecret.secretStoreRef.name }}
    kind: {{ .Values.externalSecret.secretStoreRef.kind }}
  target:
    name: {{ include "common.secretName" . }}
    creationPolicy: {{ .Values.externalSecret.target.creationPolicy }}
    {{- with .Values.externalSecret.target.template }}
    template:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- with .Values.externalSecret.data }}
  data:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.externalSecret.dataFrom }}
  dataFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}
