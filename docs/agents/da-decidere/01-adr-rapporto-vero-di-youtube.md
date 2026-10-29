# Il rapporto vero di un video YouTube senza estrazione viene dall'oEmbed nella forma `/shorts/`

Tipo: adr
Da: gh-55-boxfit
Stato: accettata
Cambia: docs/adr/ (primo ADR del repo, via domain-modeling)

## Proposta

Quando lo stream non si estrae (WebView di YouTube, YouTube su web) il player parte da 16:9 (9:16 se l'URL ha
`/shorts/`) e chiede in parallelo `https://www.youtube.com/oembed?url=https://www.youtube.com/shorts/<id>&format=json`,
con timeout, senza mai bloccare il caricamento. La forma `/shorts/` e' l'unica che da' il rapporto vero anche degli
Short (con `watch?v=` torna 16:9); IFrame API, miniature e youtube_explode non lo danno. L'endpoint non e'
documentato: e' best-effort. Vale oltre la #55 perche' chi tocchera' la WebView o i ripieghi di YouTube rischia di
tornare a `watch?v=` o a una chiamata che blocca (la #74 aveva tolto `noembed.com` per questo).
