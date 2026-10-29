export function adminUrl(apiBase: string, path: string): string {
  let url: URL;
  let base: URL;
  try {
    base = new URL(apiBase);
    url = new URL(path, base);
  } catch {
    throw new Error("The staff console calls /admin/v1 only.");
  }
  if (url.origin !== base.origin || !url.pathname.startsWith("/admin/v1/")) {
    throw new Error("The staff console calls /admin/v1 only.");
  }
  return url.toString();
}

export async function adminFetch(
  apiBase: string,
  path: string,
  authorization: string,
  init: {
    method?: string;
    body?: BodyInit;
    contentType?: string;
    assetId?: string;
  } = {},
): Promise<Response> {
  const headers = new Headers();
  headers.set("authorization", authorization);
  if (init.contentType) headers.set("content-type", init.contentType);
  if (init.assetId) headers.set("x-asset-id", init.assetId);
  return fetch(adminUrl(apiBase, path), {
    method: init.method ?? "GET",
    headers,
    body: init.body,
  });
}
