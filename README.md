# Olympic Participation Tracker

## Context

The **Olympic Participation Tracker** is an application designed to record and analyze countries' participation in the Olympic Games. It provides statistics on medals obtained by each country, helping users gain insights into historical performance. Although the application is currently in its early development stages, we aim to create a robust and user-friendly tool for Olympic enthusiasts.

## Technical Context

The application is built using **Angular 14.1** and relies on **npm** for package management. Angular offers a powerful framework for creating dynamic web applications, and npm simplifies the process of managing dependencies and scripts.

Summary:

- **NodeJS**: Tested with version 20.11.0
- **NPM**: Tested with version 10.2.4
- **NGINX**: Tested with version 1.27

## Getting Started

### Install dependencies

Run `npm i` in local development to install NodeJS dependencies. If you are installing the app on a CI environment prefer to use `npm ci`. you can also change npm cache directory to your working directory as following

```bash
npm ci --cache .npm --prefer-offline
```

## Development server

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The application will automatically reload if you change any of the source files.

### Build

Run `npm run build` to build the project. The build artifacts will be stored in the `dist/` directory.

### Test

To run tests and ensure the application's functionality, use the following command:

```bash
npm test
```

Our test suite covers critical components, ensuring stability and reliability.

### Packaging

To package the application for distribution, run:

```bash
npm pack
```

This will create a distributable package containing the compiled code and necessary assets.

### Deploy on nginx

To deploy application on nginx web server with docker you can use nginx config located in the `nginx` folder. This one configure the root application folder in the `/app` folder.

After building the app copy the `dist/olympic-games-starter` folder to the root application folder in the docker image.

### Publishing to GitLab Registry

To publish the application to a GitLab registry, follow these steps:

1. **Change Application Scope**:
   - Change the application scope for your new gitlab group. For example, if your repository url is `https://gitlab.com/your-gitlab-group-slug/olympic-games-starter` change the application name to `@your-gitlab-group-slug/olympic-games-starter`
   ```json
   {
      "name": "@your-gitlab-group-slug/olympic-games-starter",
      ...
   }
   ```
2. To publish, you need to create a file named `.npmrc` with the following content :

   ```ini
   @your-gitlab-group-slug:registry=https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/packages/npm/
   //gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}/packages/npm/:_authToken="${GITLAB_TOKEN}"
   ```

3. **Set Environment Variables**:
   - Ensure that the following environment variables are specified:
     - `GITLAB_PROJECT_ID`: The ID of your GitLab project.
     - `GITLAB_TOKEN`: Your GitLab deploy token.
4. **Execute the Publish Command**:
   ```bash
   npm publish
   ```
   This will publish the package to your GitLab registry.

---

## Industrialisation : Docker & CI/CD

### Lancer l'application avec Docker

Prérequis : Docker 24+ et Docker Compose v2.

```bash
docker compose up -d --build
```

L'application est servie par Nginx sur http://localhost (endpoint de santé : http://localhost/health).
Le port peut être changé avec la variable `APP_PORT` (ex. `APP_PORT=8081 docker compose up -d`).

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Build multi-stage : `node:22-alpine` compile l'application, `nginx-unprivileged:1.27-alpine` (non-root, port 8080) sert uniquement `dist/…/browser` |
| `.dockerignore` | Exclut `node_modules`, `dist`, rapports, fichiers Git/IDE du contexte de build |
| `docker-compose.yml` | Service `front` (port 80 → 8080), healthcheck et rotation des logs |
| `nginx/nginx.conf` | Configuration Nginx (SPA fallback, cache des assets, `/health`) |

### Exécuter les tests

```bash
./run-tests.sh
```

Le script détecte le type de projet, vérifie les prérequis (Node 20+, Chrome/Chromium), exécute les tests Karma
en headless avec couverture et place les rapports dans `test-results/` (`junit-report.xml` + `coverage/`).
Codes de sortie : `0` succès, `1` tests en échec, `2` environnement invalide, `3` aucun rapport produit.

### Pipeline CI/CD (GitHub Actions)

Le workflow `.github/workflows/ci.yml` est générique (même fichier pour le back-end Spring Boot) :

1. **detect** : type de projet via `./run-tests.sh --detect`
2. **test** : `./run-tests.sh`, rapport JUnit publié dans l'onglet *Checks*, résultats archivés en artefact
3. **build** : image Docker construite, validée par un smoke test `docker compose up --wait`, puis poussée sur
   `ghcr.io/<owner>/<repo>` avec les tags `<branche>`, `<branche>-<sha>`, `sha-<sha>` (+ `latest` sur `main`)
4. **release** (branche `main`) : [semantic-release](https://semantic-release.gitbook.io/) calcule la version à partir
   des commits conventionnels (`feat:`, `fix:`…), crée le tag Git et la GitHub Release, puis ajoute les tags `X.Y.Z`
   et `X.Y` à l'image déjà publiée.
