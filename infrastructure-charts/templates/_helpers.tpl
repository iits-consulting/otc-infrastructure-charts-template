{{/* Expects a dictionary as input
key is the value (or Values) to be subsituted. Referenced by .value
value is the context which is used to find the substitution. Referenced by .context

Usage: {{ include "tpl-values" (dict "values" <value(s)> "context" $ ) }}
*/}}
{{ define "tpl-values" }}
    {{- if kindIs "string" .values }}
        {{- tpl .values .context  }}
    {{- else }}
        {{- tpl ( toYaml .values ) .context }}
    {{- end }}
{{- end }}