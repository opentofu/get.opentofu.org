import type {PagesFunction} from "@cloudflare/workers-types";

interface Env {
}

export const onRequest: PagesFunction<Env> = async (context) => {
    try {
        const response = await fetch(
            "https://api.github.com/repos/opentofu/opentofu/releases/tags/v" + encodeURIComponent(context.params.release),
            {headers: {"User-Agent": "OpenTofu Releases Page"}}
        )
        const data = await response.json()

        const listItems = data.assets.map(asset => `<li><a href="${asset.browser_download_url}">${asset.name}</a></li>`)

        return new Response(`<!DOCTYPE html><html><head><title>OpenTofu releases</title></head><body><ul><li><a href="/releases/">../</a></li>${listItems.join("")}</ul></body></html>`, {
            status: 200,
            headers: {
                'content-type': 'text/html; charset=utf-8',
                'cache-control': 'max-age=31556926'
            },
        });
    } catch (e) {
        return new Response(e, {
            status: 500,
            headers: {
                'content-type': 'text/html; charset=utf-8',
            },
        });
    }
}
