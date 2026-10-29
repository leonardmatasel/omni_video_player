# Durante il caricamento un 16:9 si indovina solo quando l'altezza e' libera

Tipo: adr
Da: gh-55-boxfit
Stato: aperta
Cambia: docs/adr/ (via domain-modeling)

## Proposta

Finche' il rapporto del video non si conosce, la vista di caricamento non chiude il loader in un 16:9 indovinato
(5.1.1: un loader custom a tutto campo su un video verticale avrebbe le bande), **tranne** quando il genitore ha
l'altezza illimitata (`ListView`): li' tiene un box 16:9 col loader al centro, se no il player e' alto quanto il
loader e salta all'arrivo del video. Due decisioni prese in momenti diversi sullo stesso punto: scriverle insieme
evita che una correzione futura ne annulli una.
