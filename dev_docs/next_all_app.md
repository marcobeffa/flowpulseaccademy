# TODO — Piano di lavoro Education/Academy

## Fase 0 — Decisioni/standard
1. Congelare tassonomia **B (più piatta)** e naming **kebab-case** per cartelle/slug.
2. Uniformare “**academy**” in tutto (URL, namespace `Academy::`).
3. Elenco domini iniziali e loro ruolo (landing vs academy hub).

## Fase 1 — Config & contenuti statici
4. Creare `config/brands.yml` (catalogo card/servizi con slug univoci).
5. Creare `config/domains.yml` (schema: `host`, `root_path`, `landing_path`, `theme`, `features`) + esempi.
6. Preparare albero `config/courses/flowpulse/salute/posturacorretta/igieneposturale/` con:
   - `igieneposturale_online.yml`
   - `igieneposturale_academy.yml`
   - `blog_igieneposturale.yml` *(indice; i post veri anche in DB)*

## Fase 2 — DB/migrazioni minime
7. Migrazione `users.brands_active_slugs:jsonb` (+ GIN index) e helper in `User`.
8. *(Opzionale ora / dopo)* tabelle per blog/lezioni/eventi se parti dal DB.

## Fase 3 — Loader & cache (mtime)
9. Implementare `app/services/course_catalog.rb`:
   - scansione `config/courses/**`, build di **tree**, `packages_by_slug`, **breadcrumb**.
   - API: `find_package(slug)`, `children_for(path)`, `breadcrumb_for(slug)`.
   - cache Rails con chiave **max mtime**.
10. Implementare `app/services/domain_map.rb`:
    - load `config/domains.yml`, `lookup(host)`, cache per **mtime**.
11. Initializer: `CourseCatalog.validate!` in dev (slug duplicati/mancanti).

## Fase 4 — Routing (draw)
12. In `config/routes.rb`: metodo `draw` + `draw :flowpulse`, `draw :academy`, `draw :domains`.
13. `config/routes/flowpulse.rb`:
    ```ruby
    namespace :flowpulse do
      resources :brands, only: [:index]
      post "brands/:slug/toggle", to: "brands#toggle", as: :toggle_brand
    end
    ```
14. `config/routes/academy.rb`:
    ```ruby
    namespace :academy do
      resources :courses, only: [:index, :show] do
        member do
          get :blog
          get :online
          get :academy
        end
      end
    end
    ```
15. `config/routes/domains.rb`: rotte landing host-based (constraint per host che usa `DomainMap.lookup`).

## Fase 5 — Controller & context
16. `Flowpulse::BrandsController#index/toggle` (attivazione per utente).
17. `Academy::CoursesController`:
    - `index`: lista a partire da `root_path` (da DomainMap/host).
    - `show`: landing pacchetto + breadcrumb (da `CourseCatalog`).
18. `Academy::BlogController`, `Academy::OnlineController`, `Academy::TeachingController` (leggono i rispettivi YAML del pacchetto).
19. `Domains::HomeController` (landing per host: usa `domain_map.root_path` + `landing_path`).
20. `ApplicationController` + concern `DomainContext` per esporre `current_domain`, `root_path`, `theme`.

## Fase 6 — Viste/UX (Tailwind)
21. **Flowpulse → Brands#index**: griglia card + Attiva/Disattiva.
22. **Academy → Courses#index**: sezioni = cartelle, cards dei pacchetti figli.
23. **Courses#show**: hero, descrizione, pulsanti “Blog / Online / Academy”, breadcrumb.
24. **Blog/Online/Academy**: pagine base che leggono i rispettivi YAML (lista post/lezioni/eventi).
25. Partials condivisi: `/_breadcrumb`, `/_section_grid`, `/_package_card`.

## Fase 7 — JS & interazioni
26. Toggle attivazione brand (fetch POST, aggiorna badge/UI).
27. Ricerca + filtro “solo attivi” nell’index servizi.
28. (Se serve) client-side cache/fallback locale non bloccante.

## Fase 8 — Visibilità & auth
29. Gestione `visibility` (pubblico/iscritto/privato) in controller/vista.
30. Gate su `academy` e su lezioni se non abilitato nel pacchetto.
31. *(Opzionale)* ruoli/permessi base per area “academy”.

## Fase 9 — Performance & robustezza
32. Config cache store (Memcache/Redis) in prod; chiavi con **mtime**.
33. Helper per 404/410 quando slug/pacchetto non esiste per l’host.
34. Log strumenti: avvisi su YAML invalidi, duplicati, path mancanti.

## Fase 10 — Tooling & seeds
35. Rake task `courses:validate` (lint YAML, stampa sitemap/breadcrumb).
36. Rake task `domains:print` (tabella host → root_path).
37. Seeds minimi per utente demo e attivi predefiniti.

## Fase 11 — Test
38. Unit `CourseCatalog` e `DomainMap` (parsing, cache, breadcrumb).
39. Request test route host-based (domain → landing corretta).
40. System test toggle brand e navigazione pacchetto.

## Fase 12 — Deploy
41. Whitelist host in Rails, carica YAML in repo, imposta cache store, precompila assets.
42. Verifica mappa domini DNS/proxy → app.

---

### Criteri di “Done”
- `academy.flowpulse.net/courses` elenca le categorie da `flowpulse/`.
- `academy.posturacorretta.org` atterra su `flowpulse/salute/posturacorretta`.
- `/courses/igieneposturale` mostra landing con link a Blog/Online/Academy.
- Brands#index attiva/disattiva servizi per utente (jsonb).
- Modifiche YAML si riflettono senza riavvio (cache mtime).

# Dev Doc – 18/09/2025

## Obiettivo

Allineare una mappa chiara per la gestione del servizio education con Pacchetti Corso (atomici) (Blog, Online, Teaching), l’organizzazione per sezioni/cartelle e l’uso di domini/brand via draw e YAML — prima di scrivere codice.

Domini & punti di ingresso (host-based)

Brand con domini dedicati → ciascun dominio ha una landing personalizzata (es. flowpulse.net, posturacorretta.org, igieneposturale.it, generaimpresa.it, 1impegno.it, …).

Le landing reindirizzano/portano verso i contenuti rilevanti (pacchetti, categorie, servizi).

i sottodomini tipo “accademy.*” portano al servizio che è messo in draw (es. accademy.posturacorretta.org, accademy.flowpulse.net) mostrano direttamente il menu della sotto-alberatura corrispondente (vedi Tassonomia).

Tutti i domini sono censiti in config/domains.yml. e i subdomain sono messy sia in subdomains.yml e poi nelle draw tramite routes Se esiste una cartella con nome uguale al dominio (senza TLD o con forma concordata), il dominio si aggancia automaticamente a quel nodo dell’albero (render o redirect).

Tassonomia / Annidamento corsi (cartelle → breadcrumb)

La tassonomia è riflessa dalle cartelle:

config/courses/
  flowpulse/
    salute/
      posturacorretta/
        igieneposturale/              # slug pacchetto
          igieneposturale_online.yml   # corso online (moduli/lezioni)
          igieneposturale_accademy.yml # qui ci saranno i pacchetti le altre cose sono su db
            # la parte blog volevo gestirla tramite tag alla cartella e ai domini  
      postura_e_fisiologia/
        principi_di_fisioterapia_online.yml   # altro pacchetto (solo metadati iniziali se c'è solo la parte online vuol dire che accademy non è attiva)

L’albero cartelle definisce breadcrumb e menu.

I domini accademy.* partono da una cartella specifica:

accademy.flowpulse.net → parte da config/courses/flowpulse/

accademy.posturacorretta.org → parte da config/courses/flowpulse/salute/posturacorretta/

Scelta tassonomia: B (più piatta) consigliata: corsi → salute → posturacorretta.org → igieneposturale (le sottosezioni tipo postura_e_fisiologia diventano tag/categorie, non livello fisso).

Pacchetto Corso (unità atomica)

Un pacchetto ha 3 facce coordinate:

Blog/Contenuti: articoli pubblici/SEO e guide.

Online course: moduli/lezioni, progressi, (in futuro test/valutazioni).

Teaching (Academy): eventi pianificati, corsi in presenza/ibridi, ruoli professionisti.

Schema dati – Blog (contenuti)

Campi minimi per post (DB o YAML iniziale → poi DB):

title, description, tagdomain, tagcategory (lega a sezione/cartella), tagcourses (slugs pacchetto),

body:text, visibility:integer (privato / iscritto / pubblico),

pubblicato:boolean, date_publication:datetime, stato:integer (draft, ecc.).

Schema dati – Online course

lessons:

chapter:boolean (voce di capitolo o lezione?),

position,

content:references (riferimento a contenuto/lezione),

visibility, pubblicato, stato.

Test/valutazioni: rimandati (modulo separato più avanti).

Metadati corso nel file del pacchetto, es: igieneposturale_online.yml.

Schema dati – Teaching (Academy)

File: igieneposturale_accademy.yml (o simile). Esempio campi (riassunto):

users: []                # opzionale, se gestiti altrove anche vuoto
professionals: []        # elenco pro corrente

training_courses:
  - id: tc_2025_09_montichiari_g1
    course_slug: igiene_posturale
    package_slug: pro_presenza_gruppo
    iscrizioni_aprono_il: 2025-09-15
    iscrizioni_chiudono_il: 2025-10-01
    location_name: "Garda Hotel – Sala A"
    location_address: "Montichiari (BS)"
    location_gmaps: "place_id_or_url"
    lat: 45.414
    lng: 10.334
    tel_contatto_location: "+39 030 1234567"
    num_partecipanti: 12
    date_lessons: []     # popolate da scheduled_events

training_course_teachers:
  - id: tct_marta_tc_g1
    course_slug: igiene_posturale
    professional_id: pro_marta
    corso_individuale: true
    corso_in_gruppo_training_course_id: tc_2025_09_montichiari_g1
    tirocinio_online_required_subs: 3
    stato: in_corso  # in_corso | formazione_conclusa | in_attesa_diploma | diplomato
    concluso_la_formazione: null
    admin: false

scheduled_events:
  - id: se_tc_g1_intro
    training_course_id: tc_2025_09_montichiari_g1
    lesson_slug: introduzione
    start_at: 2025-10-05T09:00:00+02:00
    end_at:   2025-10-05T10:00:00+02:00
    note: "Prima disponibilità anche online"
    teacher_id: pro_marta

role_assignments:
  - id: ra1
    role_slug: insegnante
    professional_id: pro_marta
    context: { type: training_course, id: tc_2025_09_montichiari_g1 }
    assigned_by_professional_id: admin_1
    assigned_at: 2025-09-12T10:00:00+02:00
    state: attivo  # attivo | sospeso | revocato
    note: "Responsabile gruppo G1"

UI / Route (draw) — organizzazione

Un solo draw “accademy” (scelta attuale) per tenere insieme Blog, Online, Teaching del pacchetto:

Namespace: Accademy:: (manteniamo la grafia che stai usando)

Controller: Accademy::CoursesController (landing pacchetto), Accademy::BlogController, Accademy::OnlineController, Accademy::TeachingController.

Index hub:

Hub_accademia (multi-host): https://accademy.flowpulse.net/courses → mostra tutte le categorie a partire da config/courses/flowpulse/.

Rotte pacchetto (valide da tutti gli host):

/courses               → lista/filtri pacchetti

/courses/:slug         → landing pacchetto

/courses/:slug/blog    → blog del pacchetto

/courses/:slug/online  → corso online

/courses/:slug/academy → teaching/percorsi/eventi

Host constraints:

igieneposturale.it/ → mostra direttamente /courses/igieneposturale (o home dedicata)

posturacorretta.org/ → elenco pacchetti taggati salute/postura (cartelle relative)

Multi-dominio / Brand awareness

File config/domains.yml con elenco domini/brand, landing, tema, mapping cartella di start.

Regola: se host inizia con accademy. e c’è cartella corrispondente nell’albero, quella diventa radice di navigazione.

flowpulse.net mantiene una landing generale; Flowpulse::Brands#index mostra le card servizi e salva gli attivi per utente (users.brands_active_slugs jsonb).

Index Servizi (flowpulse)

Flowpulse::Brands#index (già definito):

sorgente: config/brands.yml (con slug univoci, niente id),

Attiva/Disattiva → persistenza per utente in brands_active_slugs (jsonb),

ricerca + filtro “solo attivi”,

in futuro: deep link verso pacchetti / domini dedicati.

Dati & Persistenza

YAML: metadati/versionabili (cataloghi, pacchetti, struttura corsi, accademy, domain mapping).

DB: dinamiche runtime (utenti, iscrizioni, progressi, eventi, post del blog se non si adottano file md).

Cache: loader YAML con chiave mtime (invalida alla modifica file).

Draw come servizi

Ogni draw = un servizio. Attuali/priorità:

account (già in corso)

accademy (unisce blog/online/teaching per i pacchetti)

flowpulse/brands (index servizi; già impostato con YAML+jsonb attivi)

domains (nuovo consigliato): legge config/domains.yml e gestisce routing/landing per host (con constraints) + collegamento automatico alla cartella.

In sospeso (da decidere)



Prossimi passi

Congelare tassonomia (cartelle che diventano category  ss) e standard slug.

Definire config/domains.yml (schema + esempi) e creare il draw ********************************************************************************************domains.

Implementare loader YAML per pacchetti e domain mapping (cache mtime).

Generare viste /courses (index, show, blog, online, academy) con host-awareness.

Integrare il primo pacchetto Igiene Posturale end-to-end (landing + blog + online + academy).

Obiettivo

Allineare una mappa chiara per la gestione del servizio education con Pacchetti Corso (atomici) (Blog, Online, Teaching), l’organizzazione per sezioni/cartelle e l’uso di domini/brand via draw e YAML — prima di scrivere codice.

Domini & punti di ingresso (host-based)

Brand con domini dedicati → ciascun dominio ha una landing personalizzata (es. flowpulse.net, posturacorretta.org, igieneposturale.it, generaimpresa.it, 1impegno.it, …).

Le landing reindirizzano/portano verso i contenuti rilevanti (pacchetti, categorie, servizi).

Domini “accademy.*” (es. accademy.posturacorretta.org, accademy.flowpulse.net) mostrano direttamente il menu della sotto-alberatura corrispondente (vedi Tassonomia).

Tutti i domini sono censiti in config/domains.yml. Se esiste una cartella con nome uguale al dominio (senza TLD o con forma concordata), il dominio si aggancia automaticamente a quel nodo dell’albero (render o redirect).

Tassonomia / Annidamento corsi (cartelle → breadcrumb)

La tassonomia è riflessa dalle cartelle:

config/courses/
  flowpulse/
    salute/
      posturacorretta/
        igieneposturale/              # slug pacchetto
          igieneposturale_online.yml   # corso online (moduli/lezioni)
          igieneposturale_accademy.yml # teaching/percorsi/eventi/ruoli
          blog_igieneposturale.yml     # indice blog iniziale (post poi DB o md)
      postura_e_fisiologia/
        principi_di_fisioterapia.yml   # altro pacchetto (solo metadati iniziali)

L’albero cartelle definisce breadcrumb e menu.

I domini accademy.* partono da una cartella specifica:

accademy.flowpulse.net → parte da config/courses/flowpulse/

accademy.posturacorretta.org → parte da config/courses/flowpulse/salute/posturacorretta/

Scelta tassonomia: B (più piatta) consigliata: corsi → salute → posturacorretta.org → igieneposturale (le sottosezioni tipo postura_e_fisiologia diventano tag/categorie, non livello fisso).

Pacchetto Corso (unità atomica)

Un pacchetto ha 3 facce coordinate:

Blog/Contenuti: articoli pubblici/SEO e guide.

Online course: moduli/lezioni, progressi, (in futuro test/valutazioni).

Teaching (Academy): eventi pianificati, corsi in presenza/ibridi, ruoli professionisti.

Schema dati – Blog (contenuti)

Campi minimi per post (DB o YAML iniziale → poi DB):

title, description, tagdomain, tagcategory (lega a sezione/cartella), tagcourses (slugs pacchetto),

body:text, visibility:integer (privato / iscritto / pubblico),

pubblicato:boolean, date_publication:datetime, stato:integer (draft, ecc.).

Schema dati – Online course

lessons:

chapter:boolean (voce di capitolo o lezione?),

position,

content:references (riferimento a contenuto/lezione),

visibility, pubblicato, stato.

Test/valutazioni: rimandati (modulo separato più avanti).

Metadati corso nel file del pacchetto, es: igieneposturale_online.yml.

Schema dati – Teaching (Academy)

File: igieneposturale_accademy.yml (o simile). Esempio campi (riassunto):

users: []                # opzionale, se gestiti altrove anche vuoto
professionals: []        # elenco pro corrente

training_courses:
  - id: tc_2025_09_montichiari_g1
    course_slug: igiene_posturale
    package_slug: pro_presenza_gruppo
    iscrizioni_aprono_il: 2025-09-15
    iscrizioni_chiudono_il: 2025-10-01
    location_name: "Garda Hotel – Sala A"
    location_address: "Montichiari (BS)"
    location_gmaps: "place_id_or_url"
    lat: 45.414
    lng: 10.334
    tel_contatto_location: "+39 030 1234567"
    num_partecipanti: 12
    date_lessons: []     # popolate da scheduled_events

training_course_teachers:
  - id: tct_marta_tc_g1
    course_slug: igiene_posturale
    professional_id: pro_marta
    corso_individuale: true
    corso_in_gruppo_training_course_id: tc_2025_09_montichiari_g1
    tirocinio_online_required_subs: 3
    stato: in_corso  # in_corso | formazione_conclusa | in_attesa_diploma | diplomato
    concluso_la_formazione: null
    admin: false

scheduled_events:
  - id: se_tc_g1_intro
    training_course_id: tc_2025_09_montichiari_g1
    lesson_slug: introduzione
    start_at: 2025-10-05T09:00:00+02:00
    end_at:   2025-10-05T10:00:00+02:00
    note: "Prima disponibilità anche online"
    teacher_id: pro_marta

role_assignments:
  - id: ra1
    role_slug: insegnante
    professional_id: pro_marta
    context: { type: training_course, id: tc_2025_09_montichiari_g1 }
    assigned_by_professional_id: admin_1
    assigned_at: 2025-09-12T10:00:00+02:00
    state: attivo  # attivo | sospeso | revocato
    note: "Responsabile gruppo G1"

UI / Route (draw) — organizzazione

Un solo draw “accademy” (scelta attuale) per tenere insieme Blog, Online, Teaching del pacchetto:

Namespace: Accademy:: (manteniamo la grafia che stai usando)

Controller: Accademy::CoursesController (landing pacchetto), Accademy::BlogController, Accademy::OnlineController, Accademy::TeachingController.

Index hub:

Hub_accademia (multi-host): https://accademy.flowpulse.net/courses → mostra tutte le categorie a partire da config/courses/flowpulse/.

Rotte pacchetto (valide da tutti gli host):

/courses               → lista/filtri pacchetti

/courses/:slug         → landing pacchetto

/courses/:slug/blog    → blog del pacchetto

/courses/:slug/online  → corso online

/courses/:slug/academy → teaching/percorsi/eventi

Host constraints:

igieneposturale.it/ → mostra direttamente /courses/igieneposturale (o home dedicata)

posturacorretta.org/ → elenco pacchetti taggati salute/postura (cartelle relative)

Multi-dominio / Brand awareness

File config/domains.yml con elenco domini/brand, landing, tema, mapping cartella di start.

Regola: se host inizia con accademy. e c’è cartella corrispondente nell’albero, quella diventa radice di navigazione.

flowpulse.net mantiene una landing generale; Flowpulse::Brands#index mostra le card servizi e salva gli attivi per utente (users.brands_active_slugs jsonb).

Index Servizi (flowpulse)

Flowpulse::Brands#index (già definito):

sorgente: config/brands.yml (con slug univoci, niente id),

Attiva/Disattiva → persistenza per utente in brands_active_slugs (jsonb),

ricerca + filtro “solo attivi”,

in futuro: deep link verso pacchetti / domini dedicati.

Dati & Persistenza

YAML: metadati/versionabili (cataloghi, pacchetti, struttura corsi, accademy, domain mapping).

DB: dinamiche runtime (utenti, iscrizioni, progressi, eventi, post del blog se non si adottano file md).

Cache: loader YAML con chiave mtime (invalida alla modifica file).

Draw come servizi

Ogni draw = un servizio. Attuali/priorità:

account (già in corso)

accademy (unisce blog/online/teaching per i pacchetti)

flowpulse/brands (index servizi; già impostato con YAML+jsonb attivi)

domains (nuovo consigliato): legge config/domains.yml e gestisce routing/landing per host (con constraints) + collegamento automatico alla cartella.

In sospeso (da decidere)



Prossimi passi

Congelare tassonomia (cartelle che diventano category ) e tramite i tag si attacca il content a una cartella o a un corso  slug.

Definire config/domains.yml e subdomains.yml con i servizi (schema + esempi) e creare il draw ********************************************************************************************domains.

Implementare loader YAML per pacchetti e domain mapping (cache mtime).

Generare viste /courses (index, show, blog, online, academy) con host-awareness.

Integrare il primo pacchetto Igiene Posturale end-to-end (landing + blog + online + academy).
