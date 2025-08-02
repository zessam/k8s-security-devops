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