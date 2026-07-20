#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTimer>

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

    // Automatic check after UI is up (respects 24h cooldown + skipped versions)
    QTimer::singleShot(1500, &updateChecker, [checker = &updateChecker]() {
        checker->checkForUpdates(false);
    });

    return app.exec();
}
