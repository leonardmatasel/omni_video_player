# Lo schermo intero cresce dal posto inline, in un OverlayEntry, senza Hero

Tipo: adr
Da: fullscreen-transizione
Stato: aperta
Cambia: docs/adr/ (via domain-modeling)

## Proposta

La transizione verso lo schermo intero è un'animazione nostra:
- il player condiviso, unico e con la GlobalKey, si sposta nell'OverlayEntry dello schermo intero;
- da lì cresce dal rettangolo del posto inline;
- rotazione e barre di sistema cambiano solo a crescita finita (all'uscita, prima del ritorno).

Non è una `Hero`, per tre motivi:
- una Hero vola solo fra pagine di rotte, e lo schermo intero deve stare in un OverlayEntry per restare sopra quelli
  dell'app (6.0.3);
- una Hero collide con la GlobalKey (flutter#57969);
- le platform view non si fotografano.

Non è nemmeno un secondo widget video, come chewie o media_kit: sul web `video_player_web` ha un solo `<video>`
(flutter#124210).

La scelta è difficile da smontare e sorprende senza contesto: chi legge si aspetta una Hero.
