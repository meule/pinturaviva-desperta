---
project: private/pintura
parent: null
family: null
---

# pintura - DESPERTA pre-launch landing page

> **Registry**: see [`ARTIFACTS.md`](./ARTIFACTS.md) — full inventory of texts/images/videos/pdfs/audios produced by this project.

## Goal

Create a premium launch site for Pintura Viva's DESPERTA watercolor palette using the existing film and still imagery as the core product story. The project exists to turn the concept into a deployable bilingual landing page that can collect early buyer interest and support a real product-style release.

## Status

Phase: static launch site delivered, launch operations incomplete.

The repository contains a full bilingual static site, asset pipeline, and deployment scripts for both a generic host and the `pinturaviva.varik.es` preview domain. The remaining gaps are operational: the reserve-sheet flow only shows client-side success feedback in `script.js`, and the deployment notes still require final domain, document-root, and TLS completion for `pinturaviva.es`.

## Key Results

- Shipped a dependency-free EN/ES landing page covering hero, palette, ritual, audience, film, gallery, product details, FAQ, sharing, and reserve flows.
- Integrated the original DESPERTA hero video, full promo film, product crops, and watercolor-process stills into one coherent launch narrative.
- Established the project's art-led positioning in [ADAPTED_CONCEPT.md](./ADAPTED_CONCEPT.md): premium craft and believable brand storytelling instead of a sci-fi gadget aesthetic.
- Added repeatable static deployment tooling via [build-dist.sh](./build-dist.sh), [deploy-rsync.sh](./deploy-rsync.sh), and [deploy-pinturaviva-varik-es.sh](./deploy-pinturaviva-varik-es.sh).

## Architecture

The site is a static HTML/CSS/JavaScript application. `index.html` defines the full landing-page structure and overlays, `styles.css` provides the visual system and responsive behavior, and `script.js` handles EN/ES translation dictionaries, URL/localStorage language state, reveal interactions, share-copy tools, mobile navigation, and the reserve-sheet UI. `build-dist.sh` copies the static site and bundled media into `dist/`, while deployment is handled either by `deploy-rsync.sh` for SSH hosts or `deploy-pinturaviva-varik-es.sh` for an AWS S3 plus CloudFront stack. There is no backend or persistence layer in this repository.

## Tasks & Progress

- [x] Phase 1: Positioning and concept
  - [x] Adapt the concept around the real DESPERTA film and stills instead of a futuristic product-launch aesthetic
  - [x] Define the page story around hero, film, process, gallery, sharing, and first-drop CTA flows
- [x] Phase 2: Static site delivery
  - [x] Build the bilingual EN/ES landing page in plain HTML, CSS, and JavaScript
  - [x] Integrate the DESPERTA hero loop, full film, product pack shots, and process stills
  - [x] Implement sticky mobile buy CTA, mobile navigation drawer, share-copy tools, and reserve-sheet interactions
- [x] Phase 3: Build and deployment tooling
  - [x] Generate a deployable `dist/` output from source files and static assets
  - [x] Support generic SSH/rsync deployment for static hosting
  - [x] Script AWS preview deployment for `pinturaviva.varik.es`
- [ ] Phase 4: Launch operations
  - [ ] Connect reserve-sheet email capture to a real backend or ESP
  - [ ] Finalize production hosting for `pinturaviva.es` and verify valid TLS plus document-root wiring

## Links

| Resource | URL |
|---|---|
| Log | [PROJECT_LOG.md](./PROJECT_LOG.md) |
| State | [STATE.yaml](./STATE.yaml) |
| Readme | [README.md](./README.md) |
| Positioning brief | [ADAPTED_CONCEPT.md](./ADAPTED_CONCEPT.md) |
| Deployment notes | [DEPLOY.md](./DEPLOY.md) |
| Static build script | [build-dist.sh](./build-dist.sh) |
| AWS preview deploy script | [deploy-pinturaviva-varik-es.sh](./deploy-pinturaviva-varik-es.sh) |
| Generic rsync deploy script | [deploy-rsync.sh](./deploy-rsync.sh) |
| Live preview | [pinturaviva.varik.es](https://pinturaviva.varik.es/) |

## Stakeholders

- Pintura Viva as the brand and product owner for DESPERTA.
- Prospective first-drop buyers, especially artists, students, illustrators, and teachers called out in the page copy.
- The operator responsible for DNS, TLS, and static-host deployment on `pinturaviva.es` or `pinturaviva.varik.es`.

## Files & Structure

| Path | Purpose |
|---|---|
| [index.html](./index.html) | Page structure, sections, overlays, and product-story layout |
| [styles.css](./styles.css) | Responsive visual system, typography, layout, and motion styling |
| [script.js](./script.js) | Localization, interaction logic, share tools, menu, and reserve-sheet behavior |
| [assets/images](./assets/images) | Product, process, and social-preview stills |
| [assets/video](./assets/video) | Hero loop and full DESPERTA promo film |
| [build-dist.sh](./build-dist.sh) | Creates the static `dist/` output |
| [deploy-pinturaviva-varik-es.sh](./deploy-pinturaviva-varik-es.sh) | Provisions and deploys the AWS preview-host stack |
| [deploy-rsync.sh](./deploy-rsync.sh) | Publishes the static site to a generic SSH-accessible host |
