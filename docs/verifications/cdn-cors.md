# CDN CORS Verification

> **Verified:** 2026-04-17 · **By:** pizmam · **Task:** Task A (#60) prereq per ADR-022 §4.A.0

## Cloudinary

```
curl -sI -H "Origin: https://deelmarkt.com" \
  "https://res.cloudinary.com/dkdkohmmx/image/upload/sample.jpg" \
  | grep -i "access-control"
```

**Result:** `Access-Control-Allow-Origin: *` ✅

## Supabase Storage

```
curl -sI -H "Origin: https://deelmarkt.com" \
  "https://ehxrhyqhtngwqkguwdiv.supabase.co/storage/v1/object/public/listings-images/sample.jpg" \
  | grep -i "access-control"
```

**Result:** `Access-Control-Allow-Origin: *` ✅ (400 on sample path is expected — bucket exists, key does not)

## Conclusion

Both CDN origins allow CORS from `https://deelmarkt.com`. Flutter Web builds using `CachedNetworkImage` from `deelmarkt.com` will not be blocked by CORS policy. Task A may proceed.

## Re-verification schedule

CI job `ci.yml` runs weekly `curl` headers assertion (to be added in Task A PR). Manual re-verify after any Cloudinary or Supabase Storage CORS policy change.
