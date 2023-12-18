import type {PagesFunction} from "@cloudflare/workers-types";

interface Env {
    ASSETS: Fetcher;
}

export const onRequest: PagesFunction<Env> = async (context) => {
    const userAgent = context.request.headers.get("user-agent").toLowerCase()
    const url = new URL(context.request.url)
    url.pathname = "/index.sh"
    const asset = await context.env.ASSETS.fetch(url)
    return new Response(asset.body, {
        status: 200,
        headers: {
            'content-type': 'text/x-shellscript',
            'content-disposition': 'attachment; filename=opentofu-install.' + (userAgent.includes("windows")?"ps1":"sh"),
            'vary': 'user-agent'
        },
    });
}
