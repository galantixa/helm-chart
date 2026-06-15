{{/*
=============================================================================
common.serviceaccount
Renders a ServiceAccount when .Values.serviceAccount.create is true.
=============================================================================
*/}}
{{- define "common.serviceaccount" -}}
{{- if .Values.serviceAccount.create }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.serviceAccountName" . }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
{{- end }}
{{- end -}}
