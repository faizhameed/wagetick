#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>

/**
 * Checks GitHub Releases for a newer WageTick version and exposes
 * the result to QML (banner + "View release" / dismiss / remind later).
 */
class UpdateChecker : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(bool checking READ isChecking NOTIFY checkingChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY updateChanged)
    Q_PROPERTY(QString releaseUrl READ releaseUrl NOTIFY updateChanged)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY updateChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY(bool bannerVisible READ bannerVisible NOTIFY bannerVisibleChanged)

public:
    explicit UpdateChecker(QObject *parent = nullptr);

    QString currentVersion() const { return m_currentVersion; }
    bool isChecking() const { return m_checking; }
    bool updateAvailable() const { return m_updateAvailable; }
    QString latestVersion() const { return m_latestVersion; }
    QString releaseUrl() const { return m_releaseUrl; }
    QString releaseNotes() const { return m_releaseNotes; }
    QString statusMessage() const { return m_statusMessage; }
    bool bannerVisible() const { return m_bannerVisible; }

public slots:
    /** Check GitHub. force=true ignores the 24h cooldown and "remind later". */
    void checkForUpdates(bool force = false);
    void openReleasePage();
    void openUpdateInstructions();
    /** Don't show this version again until a newer one ships. */
    void dismissUpdate();
    /** Hide banner; check again after 24 hours. */
    void remindLater();
    void hideBanner();

signals:
    void checkingChanged();
    void updateChanged();
    void statusChanged();
    void bannerVisibleChanged();

private:
    void setChecking(bool v);
    void setStatus(const QString &msg);
    void setBannerVisible(bool v);
    void applyUpdateResult(bool available,
                           const QString &latest,
                           const QString &url,
                           const QString &notes);
    static QString normalizeVersion(QString version);
    /** -1 if a < b, 0 if equal, 1 if a > b */
    static int compareVersions(const QString &a, const QString &b);

    QNetworkAccessManager m_nam;
    QString m_currentVersion;
    QString m_repo;
    bool m_checking = false;
    bool m_updateAvailable = false;
    bool m_bannerVisible = false;
    QString m_latestVersion;
    QString m_releaseUrl;
    QString m_releaseNotes;
    QString m_statusMessage;
};
