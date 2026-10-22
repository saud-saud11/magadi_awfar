# Public Amazon price reader

An initial, read-only host compatibility check. There is no schedule, price import,
proxy, credential, or paid API. It logs public product observations only and stops
on access denial or CAPTCHA. A successful workflow does not imply any prices were
found; inspect `observed_products`.

`reader.mjs` is a generated dependency-free bundle of the private core's
`lib/amazon-public.mjs` at source commit
`c9df4b5ecc2cafda0c08d87f9f337484fb15a8c8`. It includes the same identity, Saudi
currency, category, condition, expiry and indicative-price parsing rules used by
the application. Keep the core as the source of truth; do not edit the bundle.
