#include "UpdateChecker.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QUrl>
#include <QVersionNumber>

#ifndef WAGETICK_VERSION
#define WAGETICK_VERSION "0.0.0"
#endif

#ifndef WAGETICK_GITHUB_REPO
#define WAGETICK_GITHUB_REPO "faizhameed/wagetick"
#endif

namespace {
constexpr auto kSettingsGroup = "updates";
constexpr auto kSkipVersionKey = "skipVersion";
constexpr auto kNextCheckKey = "nextCheckUtc";
constexpr auto kRemindHours = 24;
} // namespace

UpdateChecker::UpdateChecker(QObject *parent)
    : QObject(parent)
    , m_currentVersion(QStringLiteral(WAGETICK_VERSION))
    , m_repo(QStringLiteral(WAGETICK_GITHUB_REPO))
{
    // Prefer QCoreApplication version if set (same string in practice).
    const QString appVer = QCoreApplication::applicationVersion();
    if (!appVer.isEmpty())
        m_currentVersion = appVer;
}

void UpdateChecker::setChecking(bool v)
{
    if (m_checking == v)
        return;
    m_checking = v;
    emit checkingChanged();
}

void UpdateChecker::setStatus(const QString &msg)
{
    if (m_statusMessage == msg)
        return;
    m_statusMessage = msg;
    emit statusChanged();
}

void UpdateChecker::setBannerVisible(bool v)
{
    if (m_bannerVisible == v)
        return;
    m_bannerVisible = v;
    emit bannerVisibleChanged();
}

void UpdateChecker::applyUpdateResult(bool available,
                                      const QString &latest,
                                      const QString &url,
                                      const QString &notes)
{
    const bool changed = (m_updateAvailable != available)
        || (m_latestVersion != latest)
        || (m_releaseUrl != url)
        || (m_releaseNotes != notes);

    m_updateAvailable = available;
    m_latestVersion = latest;
    m_releaseUrl = url;
    m_releaseNotes = notes;

    if (changed)
        emit updateChanged();

    setBannerVisible(available);
}

QString UpdateChecker::normalizeVersion(QString version)
{
    version = version.trimmed();
    if (version.startsWith(QLatin1Char('v'), Qt::CaseInsensitive))
        version = version.mid(1);
    // Strip pre-release / build metadata for ordering: 1.2.0-beta+meta → 1.2.0
    const int dash = version.indexOf(QLatin1Char('-'));
    if (dash >= 0)
        version = version.left(dash);
    const int plus = version.indexOf(QLatin1Char('+'));
    if (plus >= 0)
        version = version.left(plus);
    return version.trimmed();
}

int UpdateChecker::compareVersions(const QString &a, const QString &b)
{
    const QVersionNumber va = QVersionNumber::fromString(normalizeVersion(a));
    const QVersionNumber vb = QVersionNumber::fromString(normalizeVersion(b));
    return QVersionNumber::compare(va, vb);
}

void UpdateChecker::checkForUpdates(bool force)
{
    if (m_checking)
        return;

    QSettings settings;
    settings.beginGroup(QLatin1String(kSettingsGroup));

    if (!force) {
        const QDateTime next = QDateTime::fromString(
            settings.value(QLatin1String(kNextCheckKey)).toString(), Qt::ISODate);
        if (next.isValid() && QDateTime::currentDateTimeUtc() < next) {
            setStatus(QStringLiteral("Next automatic check later"));
            return;
        }
    }

    setChecking(true);
    setStatus(QStringLiteral("Checking for updates…"));

    const QUrl url(QStringLiteral("https://api.github.com/repos/%1/releases/latest")
                       .arg(m_repo));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader,
                  QStringLiteral("WageTick/%1 (macOS; update-check)")
                      .arg(m_currentVersion));
    req.setRawHeader("Accept", "application/vnd.github+json");
    // Avoid long hangs on flaky networks
    req.setTransferTimeout(12000);

    QNetworkReply *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        setChecking(false);

        if (reply->error() != QNetworkReply::NoError) {
            // 404 = no releases published yet — not an error for users
            const int http = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (http == 404) {
                setStatus(QStringLiteral("You're up to date"));
                applyUpdateResult(false, {}, {}, {});
            } else {
                setStatus(QStringLiteral("Could not check for updates"));
            }
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            setStatus(QStringLiteral("Could not parse update info"));
            return;
        }

        const QJsonObject obj = doc.object();
        if (obj.value(QLatin1String("draft")).toBool()
            || obj.value(QLatin1String("prerelease")).toBool()) {
            // Ignore drafts / prereleases for automatic prompts
            setStatus(QStringLiteral("You're up to date"));
            applyUpdateResult(false, {}, {}, {});
            return;
        }

        const QString tag = obj.value(QLatin1String("tag_name")).toString();
        const QString htmlUrl = obj.value(QLatin1String("html_url")).toString();
        QString notes = obj.value(QLatin1String("body")).toString().trimmed();
        // Keep banner compact
        if (notes.size() > 280)
            notes = notes.left(277) + QStringLiteral("…");

        const int cmp = compareVersions(m_currentVersion, tag);
        if (cmp < 0) {
            QSettings s;
            s.beginGroup(QLatin1String(kSettingsGroup));
            const QString skipped = s.value(QLatin1String(kSkipVersionKey)).toString();
            if (!skipped.isEmpty()
                && compareVersions(normalizeVersion(skipped), normalizeVersion(tag)) >= 0) {
                setStatus(QStringLiteral("Update %1 skipped").arg(normalizeVersion(tag)));
                applyUpdateResult(false, normalizeVersion(tag), htmlUrl, notes);
                return;
            }

            applyUpdateResult(true, normalizeVersion(tag), htmlUrl, notes);
            setStatus(QStringLiteral("Update %1 available").arg(normalizeVersion(tag)));
        } else {
            applyUpdateResult(false, normalizeVersion(tag), htmlUrl, notes);
            setStatus(QStringLiteral("You're up to date (v%1)").arg(m_currentVersion));
        }

        // Schedule next automatic check in 24h
        QSettings s;
        s.beginGroup(QLatin1String(kSettingsGroup));
        s.setValue(QLatin1String(kNextCheckKey),
                   QDateTime::currentDateTimeUtc().addSecs(kRemindHours * 3600).toString(Qt::ISODate));
    });

    Q_UNUSED(reply);
}

void UpdateChecker::openReleasePage()
{
    QUrl url(m_releaseUrl);
    if (!url.isValid() || url.isEmpty()) {
        url = QUrl(QStringLiteral("https://github.com/%1/releases/latest").arg(m_repo));
    }
    QDesktopServices::openUrl(url);
}

void UpdateChecker::openUpdateInstructions()
{
    // README section on the default branch — always current install/update steps
    QDesktopServices::openUrl(
        QUrl(QStringLiteral("https://github.com/%1#reinstall--update").arg(m_repo)));
}

void UpdateChecker::dismissUpdate()
{
    if (!m_latestVersion.isEmpty()) {
        QSettings settings;
        settings.beginGroup(QLatin1String(kSettingsGroup));
        settings.setValue(QLatin1String(kSkipVersionKey), m_latestVersion);
    }
    setBannerVisible(false);
    setStatus(QStringLiteral("Update dismissed"));
}

void UpdateChecker::remindLater()
{
    QSettings settings;
    settings.beginGroup(QLatin1String(kSettingsGroup));
    settings.setValue(QLatin1String(kNextCheckKey),
                      QDateTime::currentDateTimeUtc().addSecs(kRemindHours * 3600).toString(Qt::ISODate));
    setBannerVisible(false);
    setStatus(QStringLiteral("Remind again in 24 hours"));
}

void UpdateChecker::hideBanner()
{
    setBannerVisible(false);
}
