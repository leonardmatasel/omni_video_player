# Durante il caricamento un 16:9 si indovina solo quando l'altezza e' libera

Finche' il rapporto del video non si conosce, la vista di caricamento non chiude il loader in un 16:9 indovinato: un
loader custom a tutto campo su un video verticale uscirebbe con le bande (5.1.1). Fa eccezione il genitore con
l'altezza illimitata (una `ListView`): li' la vista tiene un box del rapporto indovinato col loader al centro, se no il
player sarebbe alto quanto il loader e salterebbe all'arrivo del video (`_buildLoadingView` in
`omni_video_player_initializer.dart`). Le due regole sono nate in momenti diversi sullo stesso punto: stanno insieme
perche' una correzione futura non ne annulli una.

## Considered Options

- Sempre 16:9 indovinato: bande su un loader a tutto campo con un video verticale.
- Mai un box indovinato: in una `ListView` il player collassa all'altezza del loader e salta.
