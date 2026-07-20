#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QDir>
#include <QFileInfo>
#include <QImage>

#include "UpdateChecker.h"
#include "WageTimer.h"

#ifndef WAGETICK_VERSION
#define WAGETICK_VERSION "0.0.0"
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("WageTick"));
    app.setOrganizationDomain(QStringLiteral("wagetick.app"));
    app.setApplicationName(QStringLiteral("WageTick"));
    app.setApplicationVersion(QStringLiteral(WAGETICK_VERSION));

    // Clean, modern controls; our QML draws the glass look itself
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    WageTimer wageTimer;
    UpdateChecker updateChecker;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("wageTimer"), &wageTimer);
    engine.rootContext()->setContextProperty(QStringLiteral("updateChecker"), &updateChecker);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty())
        return -1;

    // Headless-friendly screenshot capture for docs (no macOS Screen Recording needed):
    //   WAGETICK_SCREENSHOT_ELAPSED_MS=4845000 \
    //   WAGETICK_SAVE_SCREENSHOT=docs/screenshot.png \
    //   ./WageTick
    const QByteArray shotPath = qgetenv("WAGETICK_SAVE_SCREENSHOT");
    if (!shotPath.isEmpty()) {
        QTimer::singleShot(900, &app, [&engine, shotPath]() {
            auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
            if (!window) {
                QCoreApplication::exit(2);
                return;
            }
            // Ensure a full frame has been rendered with seeded elapsed time
            window->requestUpdate();
            QImage img = window->grabWindow();
            if (img.isNull()) {
                QCoreApplication::exit(3);
                return;
            }
            const QString path = QString::fromUtf8(shotPath);
            QDir().mkpath(QFileInfo(path).absolutePath());
            if (!img.save(path, "PNG")) {
                QCoreApplication::exit(4);
                return;
            }
            QCoreApplication::exit(0);
        });
        return app.exec();
    }

    // Automatic check after UI is up (respects 24h cooldown + skipped versions)
    QTimer::singleShot(1500, &updateChecker, [checker = &updateChecker]() {
        checker->checkForUpdates(false);
    });

    return app.exec();
}
