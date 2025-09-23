# Dev Doc – 18/09/2025

## Obiettivo
Portare in produzione il corso **Igiene Posturale** con:
- `/courses/:slug` → indice lezioni
- `/courses/:course_slug/lessons/:slug` → pagina lezione
- Nessun login oggi, fallback video se copertine vuote, campi vuoti nascosti

## Fatto oggi
- Course loader YAML ricorsivo
- Views brand-agnostiche con fallback video
- Alias `GET /courses/igieneposturale → /courses/igiene_posturale`

## Da fare domani (ordine)
1. **Domains routing**
   - File: `config/domains.yml`
   - Gateway controller: legge `Host`, se `landing_on_academy: true` → redirect a `academy_base + academy_target + ?brand=...`
   - CNAME per `academy.posturacorretta.org` → `academy.flowpulse.net`

2. **Categorie via cartelle**
   - Sposta YAML corso in:
     `config/courses/flowpulse/salute/posturacorretta/postura_e_fisiologia/igieneposturale/01_igieneposturale_2025-09-17.yml`
   - Aggiungi `config/taxonomy.yml` e aggiorna loader (deduzione brand/category dal path)

3. **Modello contenuti**
   - Conferma schema: `course` → `lessons` → `sheets`
   - Aggiungi sezione `programs` (autonomia/pro) e, se serve, `attachments`
   - Mantieni `plans` con `attivo`, opz. `duration_weeks`

4. **Training & Scheduling**
   - Migrazioni `training_courses`, `scheduled_events` (vedi snippet)
   - Pagina `/training_courses/:id` con lista date (MVP)

5. **Tracking esecuzioni**
   - Migrazione `task_dones`
   - Endpoint POST minimo per registrare completamenti (anche anonimi oggi)

## Rotte (oggi)
```rb
get "/courses/igieneposturale", to: redirect("/courses/igiene_posturale")
resources :courses, only: [:show], param: :slug do
  resources :lessons, only: [:show], param: :slug
end

