# Deploy Notes

## Current domain state

- `pinturaviva.es` resolves to `213.165.70.121`
- the server responds with LiteSpeed / RunCloud
- the current page is a `Website Unavailable` placeholder
- HTTPS answers, but the certificate chain is not valid yet

## What to upload

Upload the contents of `dist/` into the document root for `pinturaviva.es`.

Files required at the web root:

- `index.html`
- `styles.css`
- `script.js`
- `robots.txt`
- `sitemap.xml`
- `.htaccess`
- `assets/`

## Build the deploy folder

```bash
./build-dist.sh
```

## Deploy over SSH/rsync

If you have SSH credentials and the remote path:

```bash
DEPLOY_HOST=example.com \
DEPLOY_USER=deploy \
DEPLOY_PATH=/home/example/webapps/pinturaviva/public \
./deploy-rsync.sh
```

Optional:

```bash
DEPLOY_PORT=2222
```

## Hosting checklist

1. Point the domain document root to the uploaded `dist/` contents.
2. Remove the RunCloud `Website Unavailable` placeholder.
3. Install or reissue a valid TLS certificate for `pinturaviva.es` and `www.pinturaviva.es`.
4. Confirm `https://pinturaviva.es/` serves the new `index.html`.
5. If `www.pinturaviva.es` should work, set a redirect to the apex or mirror the same site.

## Asset notes

- hero loop: `assets/video/pinturaviva-desperta-hero.mp4`
- full film: `assets/video/pinturaviva-desperta-full.mp4`
- social preview image: `assets/images/og-desperta.jpg`
