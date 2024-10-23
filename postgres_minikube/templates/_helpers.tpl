{{- define "postgresql-helm.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgresql-helm.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgresql-helm.chart" -}}
{{- .Chart.Name }}-{{ .Chart.Version | replace "+" "_" -}}
{{- end -}}
