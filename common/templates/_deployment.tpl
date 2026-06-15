{{/*
=============================================================================
common.deployment
Renders the main Deployment. Hardened by default:
  - Dual securityContext (pod + container)
  - resources always set
  - liveness/readiness/startup probes
  - RollingUpdate with maxUnavailable: 0
  - checksum annotations trigger rollout on config/secret-mapping changes
  - full pass-through for initContainers, sidecars, extraEnv*, extraVolume*
=============================================================================
*/}}
{{- define "common.deployment" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  strategy:
    type: {{ .Values.strategy.type }}
    {{- if eq .Values.strategy.type "RollingUpdate" }}
    rollingUpdate:
      maxSurge: {{ .Values.strategy.rollingUpdate.maxSurge }}
      maxUnavailable: {{ .Values.strategy.rollingUpdate.maxUnavailable }}
    {{- end }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      annotations:
        # Force pod rollout when ConfigMap data or ExternalSecret mapping
        # changes. Note: this hashes the *mapping*, not the secret VALUE
        # (which lives outside Helm in Vault/AWS SM/etc). If your secret
        # backend rotates values without changing the mapping, pair this
        # with stakater/reloader or ESO's own controller-side restart.
        {{- if .Values.configMap.enabled }}
        checksum/config: {{ .Values.configMap.data | toYaml | sha256sum }}
        {{- end }}
        {{- if .Values.externalSecret.enabled }}
        checksum/external-secret: {{ .Values.externalSecret | toYaml | sha256sum }}
        {{- end }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
      terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
      {{- with .Values.priorityClassName }}
      priorityClassName: {{ . }}
      {{- end }}

      # -----------------------------------------------------------------
      # POD SECURITY CONTEXT
      # -----------------------------------------------------------------
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}

      # -----------------------------------------------------------------
      # INIT CONTAINERS — full spec from values, no template edits needed
      # -----------------------------------------------------------------
      {{- with .Values.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      containers:
        - name: {{ .Chart.Name }}
          image: {{ include "common.image" . }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}

          # -------------------------------------------------------------
          # CONTAINER SECURITY CONTEXT
          # -------------------------------------------------------------
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}

          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
            {{- with .Values.extraContainerPorts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}

          # -------------------------------------------------------------
          # ENV: ConfigMap -> ExternalSecret-managed Secret -> extraEnvFrom -> extraEnv
          # -------------------------------------------------------------
          {{- if or .Values.configMap.enabled .Values.externalSecret.enabled .Values.extraEnvFrom }}
          envFrom:
            {{- if .Values.configMap.enabled }}
            - configMapRef:
                name: {{ include "common.configMapName" . }}
            {{- end }}
            {{- if .Values.externalSecret.enabled }}
            - secretRef:
                name: {{ include "common.secretName" . }}
            {{- end }}
            {{- with .Values.extraEnvFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}

          {{- with .Values.extraEnv }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          # -------------------------------------------------------------
          # RESOURCES — always set, prevents noisy-neighbor contention
          # -------------------------------------------------------------
          resources:
            {{- toYaml .Values.resources | nindent 12 }}

          # -------------------------------------------------------------
          # VOLUME MOUNTS: persistence (if enabled) + extraVolumeMounts
          # -------------------------------------------------------------
          {{- if or .Values.persistence.enabled .Values.extraVolumeMounts }}
          volumeMounts:
            {{- if .Values.persistence.enabled }}
            - name: data
              mountPath: {{ .Values.persistence.mountPath }}
            {{- end }}
            {{- with .Values.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}

          # -------------------------------------------------------------
          # PROBES
          # -------------------------------------------------------------
          {{- if .Values.livenessProbe.enabled }}
          livenessProbe:
            {{- with .Values.livenessProbe.httpGet }}
            httpGet:
              path: {{ .path }}
              port: {{ .port }}
            {{- end }}
            {{- with .Values.livenessProbe.tcpSocket }}
            tcpSocket:
              port: {{ .port }}
            {{- end }}
            initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
            successThreshold: {{ .Values.livenessProbe.successThreshold }}
          {{- end }}

          {{- if .Values.readinessProbe.enabled }}
          readinessProbe:
            {{- with .Values.readinessProbe.httpGet }}
            httpGet:
              path: {{ .path }}
              port: {{ .port }}
            {{- end }}
            {{- with .Values.readinessProbe.tcpSocket }}
            tcpSocket:
              port: {{ .port }}
            {{- end }}
            initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
            successThreshold: {{ .Values.readinessProbe.successThreshold }}
          {{- end }}

          {{- if .Values.startupProbe.enabled }}
          startupProbe:
            {{- with .Values.startupProbe.httpGet }}
            httpGet:
              path: {{ .path }}
              port: {{ .port }}
            {{- end }}
            initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.startupProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.startupProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.startupProbe.failureThreshold }}
          {{- end }}

        # -----------------------------------------------------------------
        # SIDECAR CONTAINERS — full spec from values
        # -----------------------------------------------------------------
        {{- with .Values.sidecars }}
        {{- toYaml . | nindent 8 }}
        {{- end }}

      # ---------------------------------------------------------------------
      # VOLUMES: persistence PVC (if enabled) + extraVolumes
      # ---------------------------------------------------------------------
      {{- if or .Values.persistence.enabled .Values.extraVolumes }}
      volumes:
        {{- if .Values.persistence.enabled }}
        - name: data
          persistentVolumeClaim:
            claimName: {{ include "common.pvcName" . }}
        {{- end }}
        {{- with .Values.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- end }}

      # ---------------------------------------------------------------------
      # SCHEDULING
      # ---------------------------------------------------------------------
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.affinity }}
      affinity:
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}

      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
