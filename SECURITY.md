# Security Policy

## Supported versions

Security fixes are applied to the latest commit on `development` and, once a package has a real
tagged release (`<pkg>-vX.Y.Z` — see `docs/releasing.md`), to the most recent release of that
package on `production`. Define your own support window once your release process diverges from this
one; this policy covers `flutter_template`.

## Report a vulnerability privately

Report a suspected vulnerability through GitHub's private vulnerability reporting: open the
repository's **Security** tab and choose **Report a vulnerability**. The report is visible only to
the Maintainer (Cube Algos UG, see `CLA.md`) until a fix is coordinated.

A clone must name its own reporting channel here: either enable private vulnerability reporting
on its own repository (Settings → Security) or give a real, monitored address (see the root
`README.md`'s "After cloning" checklist).

Do not disclose a suspected vulnerability in a public issue, pull request, or comment before
coordinated disclosure.

Include as much of the following as you can:

- the affected file, screen, Appwrite Function, or workflow;
- a description of the impact and who could be affected;
- clear reproduction steps or a minimal proof of concept;
- any conditions required to exploit the issue;
- a suggested mitigation, if you have one.

Avoid including secrets, credentials, or personal data in the report.

## What to expect

Acknowledgment as soon as practical, validation, scoping, and coordinated remediation and
disclosure with the reporter.

## Good-faith research

Avoid accessing, modifying, or deleting data that does not belong to you, disrupting services,
or degrading other users' experience. Test against your own Appwrite Cloud dev project
(see `backend/appwrite/README.md`), never against anyone else's deployed instance. If testing could affect other people or systems, stop and
submit a private report first.
