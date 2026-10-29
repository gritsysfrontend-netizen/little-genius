export function renderStaffConsole(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Little Genius staff console</title>
</head>
<body>
  <h1>Staff console</h1>
  <p>This page is for staff. It is not the child app. The API checks the staff token, MFA, and role. A hidden button is not authorization.</p>
  <label>API <input id="api-base" value="http://127.0.0.1:3000"></label>
  <label>Staff token <input id="token" type="password" autocomplete="off"></label>
  <h2>Draft</h2>
  <label>Content id <input id="content-id" value="count.stars.001"></label>
  <label>English title <input id="title-en"></label>
  <label>Hindi title <input id="title-hi"></label>
  <label>Tamil title <input id="title-ta"></label>
  <button id="save-draft" type="button">Save draft</button>
  <h2>Asset</h2>
  <label>Asset file <input id="asset-file" type="file"></label>
  <button id="upload-asset" type="button">Upload asset</button>
  <h2>Review</h2>
  <p id="review-status">Education, language, and rights reviews are pending until a reviewer records them.</p>
  <button id="review-education" type="button">Record education review</button>
  <button id="review-language" type="button">Record language review</button>
  <button id="review-rights" type="button">Record rights review</button>
  <button id="publish" type="button">Publish</button>
  <button id="unpublish" type="button">Unpublish</button>
  <h2>Audit</h2>
  <button id="load-audit" type="button">Load audit</button>
  <pre id="audit"></pre>
  <script>
    const base = () => document.querySelector('#api-base').value.replace(/\\/$/, '');
    const headers = (extra) => ({ authorization: document.querySelector('#token').value, ...extra });
    let draftId = '';
    const copy = (text) => ({ title: text, instruction: text, feedbackCorrect: text, feedbackRetry: text });
    document.querySelector('#save-draft').addEventListener('click', () => {
      const title = (id) => document.querySelector(id).value;
      const lesson = {
        schemaVersion: '1.0',
        contentId: document.querySelector('#content-id').value,
        categoryId: 'numbers',
        ageRange: { minMonths: 49, maxMonths: 60 },
        learningObjectives: ['count'],
        difficulty: 1,
        estimatedDurationSeconds: 30,
        localizations: { en: copy(title('#title-en')), hi: copy(title('#title-hi')), ta: copy(title('#title-ta')) },
        assets: [],
        interaction: { type: 'counting', completionRule: 'count_matches', retryPolicy: 'unlimited', targetCount: 2, maxCount: 5 },
        accessibility: { imageLabel: {}, requiresAudio: false }
      };
      fetch(base() + '/admin/v1/drafts', {
        method: 'POST',
        headers: headers({ 'content-type': 'application/json' }),
        body: JSON.stringify(lesson)
      }).then((response) => response.json()).then((body) => {
        draftId = body.draftId || '';
        document.querySelector('#review-status').textContent = JSON.stringify({
          education: body.educationStatus, rights: body.rightsStatus, locales: body.locales
        });
      });
    });
    document.querySelector('#upload-asset').addEventListener('click', () => {
      const file = document.querySelector('#asset-file').files[0];
      if (!file) return;
      fetch(base() + '/admin/v1/assets', {
        method: 'POST',
        headers: headers({ 'content-type': file.type, 'x-asset-id': 'img.staff.upload' }),
        body: file
      });
    });
    const review = (path, body) => fetch(base() + '/admin/v1/drafts/' + draftId + path, {
      method: 'POST',
      headers: headers({ 'content-type': 'application/json' }),
      body: JSON.stringify(body)
    });
    document.querySelector('#review-education').addEventListener('click', () => {
      review('/reviews/education', { decision: 'approved' });
    });
    document.querySelector('#review-language').addEventListener('click', () => {
      review('/reviews/language', { locale: 'en', decision: 'approved' });
      review('/reviews/language', { locale: 'hi', decision: 'approved' });
      review('/reviews/language', { locale: 'ta', decision: 'approved' });
    });
    document.querySelector('#review-rights').addEventListener('click', () => {
      review('/reviews/rights', { decision: 'approved' });
    });
    document.querySelector('#publish').addEventListener('click', () => {
      fetch(base() + '/admin/v1/drafts/' + draftId + '/publish', { method: 'POST', headers: headers({}) });
    });
    document.querySelector('#unpublish').addEventListener('click', () => {
      const id = document.querySelector('#content-id').value;
      fetch(base() + '/admin/v1/content/' + encodeURIComponent(id) + '/unpublish', { method: 'POST', headers: headers({}) });
    });
    document.querySelector('#load-audit').addEventListener('click', () => {
      fetch(base() + '/admin/v1/audit', { headers: headers({}) });
    });
  </script>
</body>
</html>`;
}
