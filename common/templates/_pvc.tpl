{{/*
=============================================================================
common.pvc
Renders a PersistentVolumeClaim when .Values.persistence.enabled is true.
Mounted into the main container by common.deployment at
.Values.persistence.mountPath.

NOTE: A standalone PVC works for ReadWriteOnce volumes with a single
replica, or ReadWriteMany volumes (e.g. NFS, EFS, Filestore) with multiple
replicas. For per-replica volumes with a Deployment + multiple replicas on
ReadWriteOnce storage, use a StatefulSet with volumeClaimTemplates instead
— this library intentionally keeps common.deployment as a Deployment.
=============================================================================
*/}}
{{- define "common.pvc" -}}
{{- if .Values.persistence.enabled }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "common.pvcName" . }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.persistence.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  accessModes:
    {{- toYaml .Values.persistence.accessModes | nindent 4 }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
  {{- if .Values.persistence.storageClassName }}
  storageClassName: {{ .Values.persistence.storageClassName }}
  {{- end }}
{{- end }}
{{- end -}}
