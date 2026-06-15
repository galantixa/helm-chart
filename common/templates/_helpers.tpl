{{/*
=============================================================================
common/templates/_helpers.tpl
=============================================================================
IMPORTANT: When included from an application chart's templates/all.yaml via
{{ include "common.xxx" . }}, the context "." is the APPLICATION chart's
root context (.Chart.Name = "pg-fds--be", .Values = pg-fds--be/values.yaml,
NOT common/values.yaml). All helpers below rely on that.
=============================================================================
*/}}

{{/*
Base name of the application chart, trunc'd to the 63-char DNS label limit.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified resource name.
release=pg-fds-be, chart=pg-fds--be → pg-fds-be (no double chart-name suffix)
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
helm.sh/chart label — uses the APPLICATION chart's name+version,
not the common library chart's version.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Recommended Kubernetes labels.
ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — stable across releases, used in matchLabels/selectors.
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name resolution.
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container image reference. Falls back to Chart.AppVersion if image.tag unset
— enforces tag pinning while keeping Chart.yaml as the source of truth.
*/}}
{{- define "common.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
ConfigMap name.
*/}}
{{- define "common.configMapName" -}}
{{- printf "%s-config" (include "common.fullname" .) }}
{{- end }}

{{/*
Secret name — the target Secret that ExternalSecret will materialize,
or a conventional name if externalSecret.target.name is not set.
*/}}
{{- define "common.secretName" -}}
{{- if .Values.externalSecret.target.name }}
{{- .Values.externalSecret.target.name }}
{{- else }}
{{- printf "%s-secret" (include "common.fullname" .) }}
{{- end }}
{{- end }}

{{/*
PVC name.
*/}}
{{- define "common.pvcName" -}}
{{- printf "%s-data" (include "common.fullname" .) }}
{{- end }}
