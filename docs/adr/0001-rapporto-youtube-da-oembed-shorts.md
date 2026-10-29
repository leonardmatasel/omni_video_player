# Il rapporto vero di un video YouTube senza estrazione viene dall'oEmbed nella forma `/shorts/`

Quando lo stream non si estrae (WebView di YouTube, YouTube su web) il player parte da 16:9, o da 9:16 se l'URL ha
`/shorts/`, e intanto chiede `https://www.youtube.com/oembed?url=https://www.youtube.com/shorts/<id>&format=json`
con un timeout, senza mai bloccare il caricamento (`YoutubeVideoApi.fetchVideoSize`). La forma `/shorts/` e' l'unica
che dia il rapporto vero anche degli Short: con `watch?v=` la risposta e' sempre 16:9, e IFrame API, miniature e
youtube_explode non lo danno. L'endpoint non e' documentato, quindi e' best-effort: qualunque errore lascia la
misura di partenza.

## Considered Options

- `watch?v=` nell'oEmbed: sempre 16:9, sbaglia gli Short.
- Un servizio terzo (`noembed.com`): tolto con la #74, perche' una chiamata lenta bloccava il caricamento.
