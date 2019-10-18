{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cje.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "oc.protocol" -}}
{{- if .Values.OperationsCenter.Ingress.tls.Enable -}}https{{- else -}}{{ .Values.OperationsCenter.Protocol }}{{- end -}}
{{- end -}}

{{- define "oc.url" -}}
{{- template "oc.protocol" . -}}://{{ .Values.OperationsCenter.HostName }}{{ .Values.OperationsCenter.ContextPath }}
{{- end -}}

{{- define "ingress.ssl_redirect" -}}
{{- .Values.OperationsCenter.Ingress.tls.Enable }}
{{- end -}}

{{- define "rbac.apiVersion" -}}
{{ if not (eq .Values.OperationsCenter.Platform "openshift") -}}rbac.authorization.k8s.io/{{- end -}}v1
{{- end -}}

{{- define "rbac.apiGroup" -}}
{{ if not (eq .Values.OperationsCenter.Platform "openshift") -}}rbac.authorization.k8s.io{{- end -}}
{{- end -}}