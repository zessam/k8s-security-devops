{{/*
Returns the full name of the app, respecting fullnameOverride if provided.
*/}}
{{- define "java-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{ .Values.fullnameOverride }}
{{- else -}}
{{ printf "%s-%s" .Release.Name .Chart.Name }}
{{- end -}}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "java-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "java-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "java-app.labels" -}}
helm.sh/chart: {{ include "java-app.chart" . }}
{{ include "java-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "java-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "java-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "java-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "java-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}