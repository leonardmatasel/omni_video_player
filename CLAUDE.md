# CLAUDE.md — omni_video_player

Pacchetto Flutter **singolo** (non monorepo) pubblicato su pub.dev.
Niente codegen, niente l10n, niente script di workspace: `flutter analyze` +
`flutter test` sono l'unico gate.

## Comandi

```bash
flutter pub get
flutter analyze
flutter test
cd example && flutter run   # verifica a mano su device/emulatore
```

Flutter **non** è pinnato nel repo (nessun `.fvmrc`): si usa `flutter` nudo, che
qui risolve alla default di FVM. Non usare `fvm flutter`.
Vincoli del `pubspec.yaml`: Dart `>=3.10.0`, Flutter `>=3.38.0`.
Platform supportate: android, ios, web — il playback ha rami per-piattaforma
(WebView vs `video_player`), quindi ogni decisione va qualificata per piattaforma.

## Agent skills

### Issue tracker

Markdown locale in `.scratch/`. Vedi `docs/agents/issue-tracker.md`.
Le **GitHub issues** del repo sono il canale dei bug degli utenti del pacchetto:
i ticket wayfinder non ci vanno mai (il tracker pubblico non è una lavagna di
lavoro interno).

### Domain docs

Single-context: `CONTEXT.md` a root + ADR in `docs/adr/`. Nessuno dei due esiste
ancora: li crea `domain-modeling` quando una decisione lo merita, non in anticipo.
Se mancano, si procede in silenzio.

## wayfinder chain

Quando scrivo `/wayfinder`, la sessione entra in questa catena e prosegue da sola:
passa allo stadio seguente e lo esegue senza chiedermi conferma. Ti fermi a
chiedere **solo** in questi casi, che sono tutti quelli previsti:

- la pausa per il `/clear` fra lo stadio 4 e il 5, che devo fare io;
- una skill gated (`disable-model-invocation`, es. `/to-spec`): dimmi di lanciarla io;
- una decisione che spetta a me: grilling, scelte di prodotto, un ticket `prototype`,
  due decisioni già prese che si contraddicono;
- un'azione distruttiva, o che esce dal repo e dalla mia macchina (release inclusa).

Tutto il resto parte in automatico: verifiche (`flutter analyze`, `flutter test`),
scrittura di file in `.scratch/` e `docs/superpowers/`, letture del codice e delle
dipendenze.

1. `/wayfinder` — chart della mappa, poi un ticket per sessione. Gli stadi seguenti
   partono solo quando la mappa è pulita (nessun ticket aperto).
   **Il tipo `prototype` passa da me.** Chiedimi prima di crearne uno in fase di
   charting, e di nuovo prima di scrivere la prima riga per risolverlo: spesso la
   risposta ce l'ho già io, e il prototipo diventa lavoro buttato. Se ti confermo il
   comportamento a voce, scrivilo nel ticket come **confermato dal dev, non misurato**.
   Vale doppio qui: un bug di playback si conferma su device reale, e quello lo faccio io.
2. `/to-spec` — collassa le decisioni della mappa in una spec (in `.scratch/<effort>/spec.md`).
3. `superpowers:writing-plans` — piano in `docs/superpowers/plans/`.
4. `superpowers:subagent-driven-development` — esecuzione del piano.
   Include già la review per-task (spec + qualità) su subagent isolati: non
   aggiungere `superpowers:requesting-code-review` come stadio a sé, sarebbe la
   stessa review su un contesto più sporco.
   **Finito lo stadio 4, fermati e dimmi di fare `/clear`**: gli stadi 5-7 leggono
   da file (spec in `.scratch/`, piano in `docs/superpowers/plans/`, diff da git),
   non dalla conversazione, e a contesto pulito rendono di più.
5. `simplify` — riuso, semplificazione, efficienza: applica le fix da sola.
6. `ponytail:ponytail-review` — gate sull'over-engineering rimasto. La skill solo
   elenca: applico io le voci che approvi, poi si prosegue.
7. `/code-review` — gate finale a due assi (Standards + Spec) sul diff, usando come
   spec quella prodotta allo stadio 2. Nota: il suo asse Standards porta lo smell
   "Duplicated Code" di Fowler, che può contraddire lo `yagni:` dello stadio 6.
   Segnala il conflitto invece di risolverlo da solo.

Regole valide per tutta la catena, non negoziabili:

- **Mai** `superpowers:finishing-a-development-branch`. Niente merge, niente PR.
- **Mai** creare branch o worktree, **mai** `superpowers:using-git-worktrees`:
  si lavora nel branch e nella working directory correnti.
- Niente `git commit` salvo richiesta esplicita, subagent implementatori inclusi:
  le modifiche restano nel working tree. Dove il piano prevede uno step "Commit",
  saltalo.
- **Mai pubblicare**: niente `flutter pub publish` / `dart pub publish`, e nessun bump
  di `version:` nel `pubspec.yaml` o voce nel `CHANGELOG.md` se non te lo chiedo.
  La release è una mia decisione, non l'ultimo stadio della catena.
- Di conseguenza il diff per le review è il **working tree**: `git diff` quando sono
  su `main`, `git diff main` quando sto su un branch. **Non** `main...HEAD`, non la
  coppia BASE_SHA/HEAD_SHA.
- Chiusura della catena: `flutter analyze` + `flutter test` verdi, poi stop e riepilogo.
  Quello che il test non copre (playback reale, fullscreen, web) lo verifico io sul
  device o su `example/`: dimmi cosa guardare, non dare per verde ciò che non è girato.
- Sempre alla chiusura, prima del riepilogo: rileggi le Decisions-so-far della mappa
  e proponimi la promozione ad ADR (`docs/adr/` via `domain-modeling`) delle decisioni
  **durevoli**, quelle che valgono oltre questo effort. Proponi, non scrivere: scelgo io
  quali. Il resto resta in `.scratch/`, che non va cancellato né pulito.
- Prerequisito degli stadi 1-2: `docs/agents/issue-tracker.md` (già presente).

Questo file e `docs/agents/` sono **versionati** nel repo: niente `.git/info/exclude`.
Lo stesso vale per quello che la catena produce — `.scratch/`, `docs/superpowers/`,
`docs/adr/` — che va committato come il resto (il commit lo faccio io, vedi la regola
sopra). Fuori dal pacchetto pubblicato ci resta comunque: `docs/` e `CLAUDE.md` sono
in `.pubignore`.
