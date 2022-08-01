{{/*
By default it takes the chart from the global app directory.
If you want to override it you need to put the charts folder into your specific stage

example override: Put your chart under stages/dev/apps
*/}}
{{- define "appPath"  -}}
    {{- $localChartPath := print (.values.global.source.appsBasePath | replace "$STAGE" .values.global.stage) "/" .chartName -}}
    {{- $relativeLocalChartPath := (print (base .values.global.source.appsBasePath) "/" .chartName "/*") -}}
    {{ if .files.Glob  $relativeLocalChartPath -}}
      {{- $localChartPath -}}
    {{- else -}}
      {{- print .values.global.chartPath "/" .chartName -}}
    {{- end -}}
{{- end -}}

{{/*This variable creates the list of helm parametes for the helm chart.
The parametes are ordered by priority that means global helm values are overriden by app helm values.

The following parametes are taken:
1. Helm Values specific for this app charts (takes highest precedence)
2. Terraform Helm Values which are injected over Terraform
3. Global Helm Values which counts for every App Chart
*/}}
{{- define "helmParameters" -}}
  {{- if .values.global.helmValues -}}
    {{- toYaml  .values.global.helmValues | nindent 10 | replace "$STAGE" .values.global.stage -}}
  {{- end -}}
  {{- if (index .values .chartName).terraformValues }}
    {{- toYaml  (index .values .chartName).terraformValues | nindent 10 | replace "$STAGE" .values.global.stage -}}
  {{- end -}}
  {{- if (index .values .chartName).helmValues }}
    {{- toYaml  (index .values .chartName).helmValues | nindent 10 | replace "$STAGE" .values.global.stage -}}
  {{- end -}}
{{- end -}}