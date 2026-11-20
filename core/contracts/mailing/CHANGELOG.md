# Changelog

All notable changes to `mailing` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `mailing-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Added

- Backend-agnostic mailer contract: `Mailer` (send, status, record a bounce, unsubscribe), `MailMessage`
  (template id, `MailLocale`, data, idempotency key, extra headers), `MailDeliveryResult` with a
  `MailDeliveryStatus` (accepted, delivered, rejected, failed, bounced, suppressed) and a `replayed` flag.
- `MailerEngine`: the one implementation of the rules over a `MailStore` (delivery record unique on the
  idempotency key, suppression list) and a `MailTransport`. A retried send never mails twice; non-transactional
  mail gets an unsubscribe footer plus `List-Unsubscribe` and `List-Unsubscribe-Post` headers and is skipped for
  an unsubscribed user.
- `MailCatalog`/`MailTemplate`: de/en templates as pure Dart (no Flutter, no slang), `{name}` placeholders like
  slang's, construction fails when a locale is missing or its placeholders differ; `exampleDigestTemplate`.
- `UnsubscribeLinks`: signed (HMAC-SHA-256), expiring one-click links scoped to one person and one subscription.
- `FakeMailer`, `InMemoryMailStore` and `RecordingMailTransport` for tests.
