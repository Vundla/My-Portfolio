{{/*
Expand the name of the chart.
*/}}
{{- define "socialgrants.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "socialgrants.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "socialgrants.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "socialgrants.labels" -}}
helm.sh/chart: {{ include "socialgrants.chart" . }}
{{ include "socialgrants.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: social-grants-system
{{- end }}

{{/*
Selector labels
*/}}
{{- define "socialgrants.selectorLabels" -}}
app.kubernetes.io/name: {{ include "socialgrants.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
API labels
*/}}
{{- define "socialgrants.api.labels" -}}
{{ include "socialgrants.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
API selector labels
*/}}
{{- define "socialgrants.api.selectorLabels" -}}
{{ include "socialgrants.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Web labels
*/}}
{{- define "socialgrants.web.labels" -}}
{{ include "socialgrants.labels" . }}
app.kubernetes.io/component: web
{{- end }}

{{/*
Web selector labels
*/}}
{{- define "socialgrants.web.selectorLabels" -}}
{{ include "socialgrants.selectorLabels" . }}
app.kubernetes.io/component: web
{{- end }}

{{/*
Worker labels
*/}}
{{- define "socialgrants.worker.labels" -}}
{{ include "socialgrants.labels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Worker selector labels
*/}}
{{- define "socialgrants.worker.selectorLabels" -}}
{{ include "socialgrants.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "socialgrants.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "socialgrants.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database connection string
*/}}
{{- define "socialgrants.databaseUrl" -}}
{{- if .Values.database.external.enabled }}
postgresql://{{ .Values.database.username }}:{{ .Values.secrets.database.password }}@{{ .Values.database.external.host }}:{{ .Values.database.external.port }}/{{ .Values.database.external.name }}
{{- else }}
postgresql://{{ .Values.database.username }}:{{ .Values.secrets.database.password }}@{{ .Values.database.host }}:{{ .Values.database.port }}/{{ .Values.database.name }}
{{- end }}
{{- end }}

{{/*
Redis connection string
*/}}
{{- define "socialgrants.redisUrl" -}}
{{- if .Values.redis.external.enabled }}
{{- if .Values.secrets.redis.password }}
redis://:{{ .Values.secrets.redis.password }}@{{ .Values.redis.external.host }}:{{ .Values.redis.external.port }}
{{- else }}
redis://{{ .Values.redis.external.host }}:{{ .Values.redis.external.port }}
{{- end }}
{{- else }}
{{- if .Values.secrets.redis.password }}
redis://:{{ .Values.secrets.redis.password }}@{{ .Values.redis.host }}:{{ .Values.redis.port }}
{{- else }}
redis://{{ .Values.redis.host }}:{{ .Values.redis.port }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Keycloak URL
*/}}
{{- define "socialgrants.keycloakUrl" -}}
{{- if .Values.keycloak.external.enabled }}
https://{{ .Values.keycloak.external.host }}:{{ .Values.keycloak.external.port }}
{{- else }}
http://{{ .Values.keycloak.host }}:{{ .Values.keycloak.port }}
{{- end }}
{{- end }}

{{/*
Common environment variables
*/}}
{{- define "socialgrants.commonEnv" -}}
- name: NODE_ENV
  value: {{ .Values.environment | quote }}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "socialgrants.fullname" . }}-secrets
      key: database-url
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "socialgrants.fullname" . }}-secrets
      key: redis-url
- name: KEYCLOAK_URL
  value: {{ include "socialgrants.keycloakUrl" . | quote }}
- name: KEYCLOAK_REALM
  value: {{ .Values.keycloak.realm | quote }}
- name: KEYCLOAK_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "socialgrants.fullname" . }}-secrets
      key: keycloak-client-secret
- name: JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "socialgrants.fullname" . }}-secrets
      key: jwt-secret
- name: ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "socialgrants.fullname" . }}-secrets
      key: encryption-key
- name: SESSION_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "socialgrants.fullname" . }}-secrets
      key: session-secret
{{- end }}

{{/*
Common volume mounts
*/}}
{{- define "socialgrants.commonVolumeMounts" -}}
{{- if .Values.persistence.enabled }}
- name: uploads
  mountPath: {{ .Values.persistence.uploads.mountPath }}
- name: logs
  mountPath: {{ .Values.persistence.logs.mountPath }}
{{- end }}
- name: tmp
  mountPath: /tmp
{{- end }}

{{/*
Common volumes
*/}}
{{- define "socialgrants.commonVolumes" -}}
{{- if .Values.persistence.enabled }}
- name: uploads
  persistentVolumeClaim:
    claimName: {{ include "socialgrants.fullname" . }}-uploads
- name: logs
  persistentVolumeClaim:
    claimName: {{ include "socialgrants.fullname" . }}-logs
{{- end }}
- name: tmp
  emptyDir: {}
{{- end }}

{{/*
Security context
*/}}
{{- define "socialgrants.securityContext" -}}
{{- toYaml .Values.securityContext }}
{{- end }}

{{/*
Pod security context
*/}}
{{- define "socialgrants.podSecurityContext" -}}
{{- toYaml .Values.podSecurityContext }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "socialgrants.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Compliance annotations
*/}}
{{- define "socialgrants.complianceAnnotations" -}}
compliance.gov.za/popia: "required"
compliance.gov.za/gdpr: "required"
security.gov.za/classification: "sensitive"
backup.gov.za/required: "true"
audit.gov.za/required: "true"
{{- end }}

{{/*
Resource limits
*/}}
{{- define "socialgrants.resources" -}}
{{- if .resources }}
resources:
{{- toYaml .resources | nindent 2 }}
{{- end }}
{{- end }}