{{/*
Full image for a service: registry/repository:tag
*/}}
{{- define "hackathon-apps.image" -}}
{{- $reg := .Values.global.imageRegistry -}}
{{- $repo := .repository -}}
{{- $tag := .Values.global.imageTag -}}
{{- if $reg -}}
{{- printf "%s/%s:%s" $reg $repo $tag -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}
