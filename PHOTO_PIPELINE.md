# Photo deployment pipeline

This repository uses chunked base64 source files because the GitHub connector is text-first and large binary uploads are unreliable.

## Kaizen workflow

For every new photo:

1. Optimize locally to WebP before GitHub upload.
2. Compute SHA-256 of the exact WebP.
3. Split its base64 into small chunks (target 3-4 KB each).
4. Create the chunk files as Git blobs only — do not commit each chunk.
5. Add one line to `.site-assets/photo-manifest.tsv`.
6. Update the relevant HTML/CSS.
7. Create one Git tree and one commit containing all chunks + page changes.
8. GitHub Actions reconstructs the WebP, checks base64 integrity, verifies SHA-256 and MIME type, then deploys.
9. Verify the single deployment run before declaring the photo live.

This avoids repeated deployments, cache confusion, and silent truncated-image failures.
