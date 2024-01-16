import type {PagesFunction} from "@cloudflare/workers-types";

interface Env {
}

export const onRequest: PagesFunction<Env> = async (context) => {
    try {
        const response = await fetch("https://api.github.com/repos/opentofu/opentofu/releases", {headers: {"User-Agent": "OpenTofu Releases Page"}})
        const data = await response.json()

        const listItems = data.map(entry => `<li><a href="/releases/${entry.name.replace("v", "")}">${entry.name}</a>`)

        return new Response(`<!DOCTYPE html><html><head></head><body><ul>${listItems.join("")}</ul></body></html>`, {
            status: 200,
            headers: {
                'content-type': 'text/html; charset=utf-8',
                'cache-control': 'max-age=3600'
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
