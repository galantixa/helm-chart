{{/*
=============================================================================
common.configmap
Renders a ConfigMap when .Values.configMap.enabled is true.
The leading "---" makes this safe to concatenate with other common.* includes
inside templates/all.yaml — Helm strips empty/whitespace-only documents.
=============================================================================
*/}}
{{- define "common.configmap" -}}
{{- if .Values.configMap.enabled }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.configMapName" . }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
data:
  {{- toYaml .Values.configMap.data | nindent 2 }}
{{- end }}
{{- end -}}
