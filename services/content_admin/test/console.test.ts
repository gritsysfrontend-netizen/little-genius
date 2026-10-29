import assert from "node:assert/strict";
import test from "node:test";
import { adminUrl } from "../src/client.ts";
import { renderStaffConsole } from "../src/render.ts";

test("the staff client calls /admin/v1 only", () => {
  assert.equal(
    adminUrl("http://127.0.0.1:3000", "/admin/v1/drafts"),
    "http://127.0.0.1:3000/admin/v1/drafts",
  );
  assert.throws(() =>
    adminUrl("http://127.0.0.1:3000", "/api/v1/content/manifest"),
  );
  assert.throws(() =>
    adminUrl("http://127.0.0.1:3000", "/admin/v1/../api/v1/profiles"),
  );
  assert.throws(() =>
    adminUrl("http://127.0.0.1:3000", "https://example.test/admin/v1/drafts"),
  );
});

test("the staff page keeps publish visible and does not call the child API", () => {
  const html = renderStaffConsole();
  assert.match(html, /id="title-en"/);
  assert.match(html, /id="title-hi"/);
  assert.match(html, /id="title-ta"/);
  assert.match(html, /id="review-education"/);
  assert.match(html, /id="review-language"/);
  assert.match(html, /id="review-rights"/);
  assert.match(html, /id="publish"/);
  assert.match(html, /id="unpublish"/);
  assert.match(html, /\/admin\/v1\/drafts/);
  assert.match(html, /\/admin\/v1\/assets/);
  assert.match(html, /\/admin\/v1\/audit/);
  assert.match(html, /\/unpublish/);
  assert.equal(html.includes("/api/v1"), false);
  assert.equal(html.includes("if (role"), false);
});
