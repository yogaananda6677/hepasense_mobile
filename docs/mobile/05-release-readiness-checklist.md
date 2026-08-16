# HepaSense Mobile — Release Readiness Checklist

## Source gates

- [x] Final application ID and namespace: `com.yogaananda.hepasense`
- [x] Google Services Android package matches
- [x] App label: `HepaSense`
- [x] Frozen API paths and request fields audited
- [x] Legacy push field `token` absent; FID field is `fid`
- [x] Production cleartext disabled; TLS bypass absent
- [x] Android permissions justified
- [x] Secret, logging, and local-persistence audits pass
- [x] Medical and legal-language audits pass
- [x] Dependency and performance audits pass
- [x] Analyzer: 0 errors, warnings, info
- [x] Tests: 197 pass
- [x] Fresh debug APK generated

## External validation

- [ ] Android fresh-install/runtime/visual review
- [ ] Real Android Firebase initialization and FID retrieval
- [ ] Authenticated backend smoke and FID register/revoke verification
- [ ] Backend Firebase Admin project match
- [ ] Genuine foreground/background/open FCM delivery

## Distribution requirements

- [ ] Owner supplies official HTTPS production `API_BASE_URL`
- [ ] Owner configures legitimate Android release signing
- [ ] Owner reviews/replaces default Flutter launcher icon and splash assets
- [ ] Owner decides whether recents-preview protection is required
- [ ] Owner defines symbol/obfuscation strategy if desired

Source freeze criteria are satisfied because no Critical or High source defect
remains. Production release must wait for the unchecked external and deployment
items.
