# Pintura Viva | DESPERTA

Premium pre-launch landing page for **DESPERTA**, a 12-pan watercolor palette by Pintura Viva.

Live site: `https://pinturaviva.varik.es`

## What This Project Includes

- Mobile-first product landing page
- Bilingual content (English / Spanish)
- Existing DESPERTA film + stills integrated into the story
- Sticky mobile buy CTA + buy bottom sheet with email capture
- Static build/deploy workflow

## Tech Stack

- Plain HTML/CSS/JavaScript (no framework)
- Static assets under `assets/`
- Deployment scripts for static hosting and AWS S3/CloudFront

## Project Structure

- `index.html` - page structure and sections
- `styles.css` - mobile-first visual system and responsive layouts
- `script.js` - EN/ES localization, menu/drawer behavior, buy sheet flow
- `assets/images/` - product and process stills
- `assets/video/` - hero loop and full film
- `build-dist.sh` - builds `dist/` output for deployment
- `deploy-pinturaviva-varik-es.sh` - deploys to `pinturaviva.varik.es` (S3 + CloudFront)
- `deploy-rsync.sh` - generic rsync deployment for SSH hosts

## Local Development

Run a simple local server:

```bash
python3 -m http.server 4173
```

Then open:

`http://127.0.0.1:4173`

## Build

```bash
./build-dist.sh
```

Build output goes to `dist/`.

## Deployment

### Deploy to `pinturaviva.varik.es`

Requires configured AWS CLI credentials with access to the target S3 bucket and CloudFront distribution.

```bash
./deploy-pinturaviva-varik-es.sh
```

### Deploy to another static host via SSH

```bash
DEPLOY_HOST=example.com \
DEPLOY_USER=deploy \
DEPLOY_PATH=/var/www/site \
./deploy-rsync.sh
```

## Notes

- The site is intentionally positioned as a real product pre-launch page (not a concept page).
- EN/ES text is managed in `script.js` translation dictionaries.
