# OpenTofu distribution site

This repository contains the source code for the `get.opentofu.org` distribution site. It is deployed on Cloudflare
Pages. The installation scripts are located in [`static/install-opentofu.sh`](static/install-opentofu.sh) (POSIX) and [`static/install-opentofu.ps1`](static/install-opentofu.ps1) (Powershell). The Cloudflare function managing the MIME type assignment is located in
[`functions/index.ts`](functions/index.ts).

## Testing the script

### Linux

You can test the installation script manually, or you can use `docker compose` to run the automated

tests:

```bash
cd tests/linux 
./test-all.sh
```

### Windows

```powershell
cd tests\windows
& '.\test-all.ps1'
```

## Testing the site

You can test the site locally using wrangler if you have NodeJS/NPM installed:

```
npm i
cd static
npx wrangler pages dev .
```