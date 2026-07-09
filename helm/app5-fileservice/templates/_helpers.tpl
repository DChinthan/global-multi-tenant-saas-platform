{{- define "app5-fileservice.fullname" -}}
{{ .Release.Name }}-app5-fileservice
{{- end -}}

{{- define "app5-fileservice.labels" -}}
app.kubernetes.io/name: app5-fileservice
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
