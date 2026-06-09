---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  /* ===== BASE ===== */
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    background-color: #ffffff;
    color: #1a1a2e;
    padding: 50px 60px 40px 60px;
  }

  /* ===== PAGE NUMBER: X / TOTAL ===== */
  section::after {
    content: attr(data-marpit-pagination) ' / 23';
    font-size: 0.65em;
    color: #999;
  }

  /* ===== HEADER BAR (logo + title) ===== */
  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    top: 12px;
    left: 0;
    right: 0;
    padding: 0 60px;
    font-size: 0.6em;
    color: #0f3460;
    font-weight: 600;
  }
  header img {
    height: 45px;
  }

  /* ===== TITLE SLIDE ===== */
  section.title {
    display: flex;
    flex-direction: column;
    justify-content: center;
    text-align: center;
    background-color: #ffffff;
  }
  section.title h1 {
    color: #0f3460;
    font-size: 1.8em;
    border-bottom: 3px solid #c8a415;
    display: inline-block;
    padding-bottom: 12px;
    margin-bottom: 15px;
  }
  section.title h2 {
    color: #555;
    font-weight: 400;
    font-size: 1em;
  }
  section.title p {
    color: #777;
    font-size: 0.85em;
  }
  section.title::after {
    content: '';
  }

  /* ===== SECTION DIVIDER ===== */
  section.divider {
    display: flex;
    flex-direction: column;
    justify-content: center;
    text-align: left;
    padding-left: 100px;
    background-color: #ffffff;
    border-left: 8px solid #c8a415;
  }
  section.divider h1 {
    color: #0f3460;
    font-size: 2em;
    margin-bottom: 5px;
  }
  section.divider p {
    color: #888;
    font-size: 0.95em;
  }
  section.divider::after {
    content: '';
  }

  /* ===== TYPOGRAPHY ===== */
  h1 {
    color: #0f3460;
    font-size: 1.4em;
    margin-bottom: 18px;
  }
  h2 {
    color: #16213e;
    font-size: 1.1em;
  }
  ul, ol {
    font-size: 0.9em;
    line-height: 1.55;
  }
  li {
    margin-bottom: 4px;
  }
  strong {
    color: #b8860b;
  }

  /* ===== TABLE ===== */
  table {
    font-size: 0.7em;
    margin-top: 10px;
  }
  th {
    background-color: #0f3460;
    color: #ffffff;
    padding: 7px 10px;
  }
  td {
    background-color: #f8f9fa;
    padding: 5px 10px;
  }

  /* ===== BLOCKQUOTE ===== */
  blockquote {
    border-left: 4px solid #c8a415;
    padding: 8px 18px;
    background: #faf8f0;
    font-size: 0.85em;
    color: #333;
    margin: 10px 0;
  }

  /* ===== IMAGES ===== */
  img {
    border-radius: 4px;
  }

  /* ===== CAPTION ===== */
  .caption {
    text-align: center;
    font-size: 0.7em;
    color: #888;
    font-style: italic;
    margin-top: 6px;
  }

  /* ===== TWO COLUMNS ===== */
  .cols {
    display: flex;
    gap: 30px;
    align-items: flex-start;
  }
  .col {
    flex: 1;
  }

  /* ===== SIDE-BY-SIDE IMAGES ===== */
  .side-by-side {
    display: flex;
    gap: 20px;
    justify-content: center;
    align-items: flex-start;
  }
  .side-by-side img {
    max-height: 380px;
  }

  /* ===== FOOTER ===== */
  footer {
    color: #bbb;
    font-size: 0.5em;
  }
---

<!-- _class: title -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

# Système de Gestion des Projets de Fin d'Études (PFE)

## Application web dédiée au contexte universitaire algérien

**HADID Rami**
Encadré par : M. DERBAL | ESST d'Alger | 2025/2026

---

<!-- header: 'Plan de la présentation ![](esst-logo.png)' -->
<!-- footer: 'HADID Rami | Système de Gestion des PFE | ESST 2025/2026' -->

# Plan de la présentation

1. **Introduction et problématique**
2. **État de l'art et étude de l'existant**
3. **Conception du système**
4. **Réalisation et technologies**
5. **Démonstration**
6. **Conclusion et perspectives**

---

<!-- _class: divider -->
<!-- _paginate: false -->
<!-- _header: '' -->

# 1. Introduction et Problématique

Contexte, domaine et motivation du projet

---

<!-- header: 'Introduction et Problématique ![](esst-logo.png)' -->

# Contexte : le PFE en Algérie

- Le PFE est l'aboutissement **obligatoire** de tout cursus universitaire (Licence, Master, Ingénieur)
- L'étudiant mobilise ses compétences pour répondre à une problématique concrète
- Il donne lieu à un **mémoire** écrit et une **soutenance** devant jury
- Trois acteurs collaborent : **étudiant**, **enseignant**, **administration**
- Des **entreprises** partenaires peuvent également proposer des sujets externes

![bg right:30% w:280](../images/trois-acteurs.png)

---

# Problématique

La gestion du PFE reste **manuelle et non structurée** dans les universités algériennes :

- Coordination par emails, tableurs Excel, échanges informels
- **Aucune plateforme unifiée** pour les différents acteurs
- Perte de documents, retards dans les affectations
- Difficulté de suivi pédagogique, absence de traçabilité
- Inégalités d'accès à l'information entre étudiants

> **Objectif** : concevoir et réaliser une application web dédiée couvrant l'intégralité du cycle de vie d'un PFE

---

<!-- _class: divider -->
<!-- _paginate: false -->
<!-- _header: '' -->

# 2. État de l'Art

Solutions existantes et étude de cas à l'ESST

---

<!-- header: 'État de l'Art ![](esst-logo.png)' -->

# Solutions existantes : les LMS

- **Moodle** : LMS open-source (400M+ utilisateurs), modules génériques
- **Canvas** : propriétaire, ~41% du marché nord-américain
- **Blackboard** : outils analytiques avancés, coût élevé

**Constat** : ces outils ne **modélisent pas le processus PFE** (proposition, validation, affectation, jury, notation)

| Critère                       | Moodle | Canvas | Blackboard | **Notre solution** |
| ----------------------------- | :----: | :----: | :--------: | :------------: |
| Proposition de sujets         |   ~    |   X    |     X      |     **V**      |
| Affectation automatisée       |   X    |   X    |     X      |     **V**      |
| Adapté au contexte algérien   |   X    |   X    |     X      |     **V**      |
| Déploiement simple            | Moyen  | Difficile | Difficile | **Simple**  |

---

# Étude de cas : l'ESST d'Alger

- Aucun catalogue centralisé de sujets disponibles
- Recherche de sujet par **bouche-à-oreille** (inégalités d'accès)
- Formalisation par **fiches papier** signées et déposées
- Validation **séquentielle** par 2 enseignants (email + papier)
- Suivi des affectations dans des **tableaux Excel**
- Planification des soutenances par **affichage / email collectif**

> **4 axes de dysfonctionnement** : manque de centralisation, absence d'automatisation, faible traçabilité, inégalités d'accès

---

<!-- _class: divider -->
<!-- _paginate: false -->
<!-- _header: '' -->

# 3. Conception du Système

Besoins fonctionnels et modélisation UML *(cf. Chapitre III du mémoire)*

---

<!-- header: 'Conception du Système ![](esst-logo.png)' -->

# Acteurs et besoins fonctionnels

<div class="cols">
<div class="col">

**Étudiant**
- Consulter le catalogue de sujets
- Exprimer des vœux (classement)
- Suivre son PFE, déposer le mémoire
- Consulter ses résultats

**Enseignant**
- Proposer et valider des sujets
- Encadrer et suivre les étudiants
- Participer aux jurys et noter

</div>
<div class="col">

**Administration**
- Gérer les utilisateurs
- Assigner les validateurs
- Affecter les PFE, constituer les jurys
- Planifier les soutenances
- Consulter les statistiques

**Entreprise**
- Proposer des sujets externes
- Gérer les candidatures
- Participer au suivi

</div>
</div>

---

# Cas d'utilisation de l'administration

![w:550 center](../diagrams/uc-administration.png)

<div class="caption">Diagramme complet disponible à la page 28 du mémoire</div>

---

# Diagramme de classes

![w:570 center](../diagrams/dc-classes-complet.png)

<div class="caption">Disponible en pleine page à la page 31 du mémoire</div>

---

# Diagrammes de séquence

<div class="side-by-side">

![h:370](../diagrams/seq-validation.png)
![h:370](../diagrams/seq-voeux-affectation.png)

</div>

<div class="caption">Validation d'un sujet (gauche) — Vœux et affectation (droite) — Pages 34-35 du mémoire</div>

---

<!-- _class: divider -->
<!-- _paginate: false -->
<!-- _header: '' -->

# 4. Réalisation et Technologies

Choix techniques et architecture

---

<!-- header: 'Réalisation et Technologies ![](esst-logo.png)' -->

# Stack technique

<div class="cols">
<div class="col">

**Frontend**
- **SvelteKit** (Svelte + Node.js)
- TypeScript (typage statique)
- HTML5 / CSS3 / SSR

**Base de données**
- **SQLite** (embarquée, ACID)
- Zéro configuration serveur

</div>
<div class="col">

**Backend**
- **Go (Golang)** + **Fiber**
- API REST sécurisée
- Binaire autonome, zéro dépendances

**Architecture backend**
- Pattern **Repository-Service-Handler**
- Séparation stricte des responsabilités

</div>
</div>

---

# Justification des choix

- **SvelteKit** vs React/Vue : compilation sans runtime virtuel, performance supérieure
- **Go/Fiber** vs Node.js : binaire autonome, empreinte mémoire faible, déploiement simplifié
- **SQLite** vs PostgreSQL : zéro configuration, idéal pour la charge universitaire
- **Application web** : accessible partout, multi-plateforme, déploiement centralisé

---

<!-- _class: divider -->
<!-- _paginate: false -->
<!-- _header: '' -->

# 5. Démonstration

Interfaces principales de l'application

---

<!-- header: 'Démonstration ![](esst-logo.png)' -->

# Tableaux de bord

<div class="side-by-side">

![h:370](../images/screenshots/admin-dashboard.png)
![h:370](../images/screenshots/teacher-dashboard.png)

</div>

<div class="caption">Administration (gauche) — Enseignant (droite)</div>

---

# Tableaux de bord

<div class="side-by-side">

![h:370](../images/screenshots/student-dashboard.png)
![h:370](../images/screenshots/company-dashboard.png)

</div>

<div class="caption">Étudiant (gauche) — Entreprise (droite)</div>

---

<!-- _class: divider -->
<!-- _paginate: false -->
<!-- _header: '' -->

# 6. Conclusion et Perspectives

---

<!-- header: 'Conclusion et Perspectives ![](esst-logo.png)' -->

# Synthèse

- **Problème** : gestion manuelle et non structurée des PFE
- **Solution** : application web dédiée couvrant tout le cycle PFE
- **Technologies** : SvelteKit + Go/Fiber + SQLite
- **Résultat** : plateforme fonctionnelle avec interfaces adaptées aux 4 acteurs

**Fonctionnalités couvertes** : proposition de sujets, validation, expression de vœux, affectation, suivi pédagogique, dépôt du mémoire, constitution des jurys, planification des soutenances, notation et résultats

---

# Perspectives

- **Notifications en temps réel** (WebSockets) pour alerter instantanément
- **Génération automatique de documents** : PV de soutenance, attestations
- **Module d'analyse statistique avancée** pour le pilotage décisionnel
- **Architecture multi-tenant** pour déployer sur plusieurs établissements
- **Application mobile** complémentaire pour le suivi en mobilité
- **Intégration avec les SI universitaires** existants (Progres, etc.)

---

<!-- _class: title -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

# Merci pour votre attention

## Questions ?
