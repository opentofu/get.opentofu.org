# OpenTofu distribution site

This repository contains the source code for the `get.opentofu.org` distribution site. It is deployed on Cloudflare
Pages. The installation script is located in [`src/install.sh`](src/install.sh), which is a combined POSIX/Powershell
script. The Cloudflare function managing the MIME type assignment is located in
[`src/functions/index.ts`](src/functions/index.ts).

## Testing the script (Linux only, WIP)

You can test the [installation script](src/install.sh) manually, or you can use `docker compose` to run the automated
tests:

```
cd tests 
./test.sh
```

## Testing the site

You can test the site locally using wrangler if you have NodeJS/NPM installed:

```
npm i
cd src
npx wrangler pages dev .
```